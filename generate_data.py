"""
Generates the synthetic e-commerce data and loads it into SQLite.

Run: python generate_data.py
Needs: E_Commerce_empty.db (schema.sql already executed, no rows).
Output: E_Commerce.db (populated copy). Fixed seeds make every run identical.
Tables are filled in foreign-key order:
CATEGORY, PRODUCT, CUSTOMER, ADDRESS, ORDERS, ORDER_ITEM, SHIPMENT, PAYMENT.
"""
import random
import shutil
import sqlite3 as sq3
from datetime import date, timedelta
import pandas as pd
from faker import Faker

random.seed(42)
Faker.seed(42)
fake = Faker("en_GB")

EMPTY_DB = "E_Commerce_empty.db"
DB = "E_Commerce.db"

N_CUSTOMERS = 500
N_ORDERS = 3000
PRODUCTS_PER_CATEGORY = 30


# STEP 1: CATEGORY
# category -> (product types, min price, max price)
catalogue = {
    "Electronics": (["Headphones", "Speaker", "Charger", "Keyboard", "Mouse",
                     "Webcam", "Power Bank", "Smartwatch"], 10, 250),
    "Clothing": (["T-Shirt", "Jeans", "Jacket", "Dress", "Hoodie",
                  "Skirt", "Jumper", "Shorts"], 8, 90),
    "Home and Kitchen": (["Blender", "Kettle", "Toaster", "Lamp", "Cushion",
                          "Saucepan", "Mug Set", "Vase"], 5, 120),
    "Books": (["Novel", "Cookbook", "Biography", "Atlas", "Notebook",
               "Workbook", "Journal", "Guidebook"], 4, 30),
    "Toys": (["Puzzle", "Board Game", "Building Set", "Teddy Bear", "Doll",
              "Toy Car", "Kite", "Drum"], 5, 60),
    "Beauty": (["Shampoo", "Moisturiser", "Perfume", "Lipstick", "Face Mask",
                "Hand Cream", "Sunscreen", "Soap"], 3, 80),
}
category_rows = []
category_id = {}
for name in catalogue:
    new_id = len(category_rows) + 1
    category_id[name] = new_id
    category_rows.append((new_id, name))


# STEP 2: PRODUCT
adjectives = ["Classic", "Premium", "Compact", "Deluxe", "Eco", "Essential", "Smart"]
colours = ["Black", "White", "Blue", "Red", "Green", "Grey"]
sizes = ["XS", "S", "M", "L", "XL"]
product_rows = []
product_price = {}      # price fixed once per product, reused for every order line
product_weights = []    # popularity: 10% best sellers (10), 30% medium (3), 60% rare (1)

for category, (types, low, high) in catalogue.items():
    for i in range(PRODUCTS_PER_CATEGORY):
        new_id = len(product_rows) + 1
        sku = category[:3].upper() + "-" + str(new_id).zfill(4)
        asin = "B0" + str(random.randint(10000000, 99999999))
        name = random.choice(adjectives) + " " + random.choice(types)
        style = random.choice(colours)

        # only clothing has a size, other categories keep NULL
        if category == "Clothing":
            size = random.choice(sizes)
        else:
            size = None

        price = round(random.uniform(low, high), 2)

        # 5% of products are almost out of stock (edge case for the restock query)
        if random.random() < 0.05:
            stock = random.randint(0, 5)
        else:
            stock = random.randint(20, 500)

        product_price[new_id] = price

        roll = random.random()
        if roll < 0.10:
            product_weights.append(10)
        elif roll < 0.40:
            product_weights.append(3)
        else:
            product_weights.append(1)
        product_rows.append((new_id, sku, asin, style, size, price, stock,
                             name, category_id[category]))


# STEP 3: CUSTOMER
customer_rows = []
customer_weights = []   # how likely a customer is to be picked for an order (same 10/3/1 scheme)
quiet_customers = []    # ~15% of customers only order in the first half of 2025
n_business = random.randint(6, 12) * N_CUSTOMERS // 100   # 6-12% business customers
business_ids = set(random.sample(range(1, N_CUSTOMERS + 1), k=n_business))
for cid in range(1, N_CUSTOMERS + 1):
    fname = fake.first_name()
    lname = fake.last_name()
    email = fake.unique.email()     # Email is UNIQUE
    phone = fake.phone_number()
    is_business = 1 if cid in business_ids else 0
    # 60% of customers have no middle initial (NULL)
    if random.random() < 0.6:
        initial = None
    else:
        initial = random.choice("ABCDEFGHIJKLMNOPQRSTUVWXYZ")
    roll = random.random()
    if roll < 0.10:
        customer_weights.append(10)
    elif roll < 0.40:
        customer_weights.append(3)
    else:
        customer_weights.append(1)

    if random.random() < 0.15:
        quiet_customers.append(cid)

    # registered before 2025, so every order date is after registration
    registered = date(2023, 1, 1) + timedelta(days=random.randint(0, 729))

    customer_rows.append((initial, lname, fname, cid, email, phone,
                          registered.isoformat(), is_business))


# STEP 4: ADDRESS (1 to 3 addresses per customer)
address_rows = []
addresses_of = {}       # customer id -> their address ids, used to keep orders consistent
for cid in range(1, N_CUSTOMERS + 1):
    addresses_of[cid] = []
    for i in range(random.randint(1, 3)):
        new_id = len(address_rows) + 1
        address_rows.append((new_id, fake.postcode(), fake.city(),
                             "United Kingdom", fake.county(), cid))
        addresses_of[cid].append(new_id)


# STEP 5: ORDERS, ORDER_ITEM and SHIPMENT
statuses = ["Delivered", "Shipped", "Pending", "Cancelled", "Returned"]
status_weights = [60, 15, 10, 10, 5]
# Pending and Cancelled orders have no shipment
courier_status = {"Shipped": "In Transit", "Delivered": "Delivered",
                  "Returned": "Returned"}
order_rows = []
item_rows = []
shipment_rows = []
order_info = []         # (order id, status, total, date), reused to build PAYMENT
customer_ids = list(range(1, N_CUSTOMERS + 1))
product_ids = list(range(1, len(product_rows) + 1))

for number in range(1, N_ORDERS + 1):
    order_id = "ORD-" + str(number).zfill(6)
    status = random.choices(statuses, status_weights)[0]
    customer = random.choices(customer_ids, customer_weights)[0]
    address = random.choice(addresses_of[customer])     # always the customer's own address

    if customer in quiet_customers:
        last_day = 180
    else:
        last_day = 364
    order_date = (date(2025, 1, 1) + timedelta(days=random.randint(0, last_day))).isoformat()
    order_rows.append((order_id, order_date, status, customer, address))

    # one line per order; Amount = quantity x the product's fixed price
    product = random.choices(product_ids, product_weights)[0]
    quantity = random.choice([1, 1, 1, 2, 2, 3])
    amount = round(product_price[product] * quantity, 2)
    item_rows.append((quantity, amount, 1, "GBP", order_id, product))

    if status in courier_status:
        shipment_rows.append((len(shipment_rows) + 1, courier_status[status],
                              random.choice(["Warehouse", "Seller"]), order_id))

    order_info.append((order_id, status, amount, order_date))


# STEP 6: PAYMENT (derived from order status so the two always agree)
methods = ["Credit Card", "Debit Card", "PayPal", "Apple Pay"]
payment_rows = []

for order_id, status, amount, order_date in order_info:
    method = random.choice(methods)
    if status == "Cancelled":
        # cancelled orders only have a declined payment
        payment_rows.append((len(payment_rows) + 1, method, amount,
                             "Declined", None, order_id))
    else:
        # 5% of other orders have a declined attempt before the accepted payment
        if random.random() < 0.05:
            payment_rows.append((len(payment_rows) + 1, method, amount,
                                 "Declined", None, order_id))
        payment_rows.append((len(payment_rows) + 1, method, amount,
                             "Accepted", order_date, order_id))


# STEP 7: write everything into the database
shutil.copyfile(EMPTY_DB, DB)
connection = sq3.connect(DB)
connection.execute("PRAGMA foreign_keys = ON")

customers = pd.DataFrame(customer_rows, columns=[
    "MInitial", "LName", "FName", "ID", "Email", "Phone", "Registered_Date", "Is_Business"])
customers.to_sql("CUSTOMER", connection, if_exists="append", index=False)

categories = pd.DataFrame(category_rows, columns=["Category_Id", "Category_Name"])
categories.to_sql("CATEGORY", connection, if_exists="append", index=False)

products = pd.DataFrame(product_rows, columns=[
    "Product_Id", "SKU", "ASIN", "Style", "Size", "Unit_Price", "Stock_Quantity",
    "Product_Name", "Category_Id"])
products.to_sql("PRODUCT", connection, if_exists="append", index=False)

addresses = pd.DataFrame(address_rows, columns=[
    "AddressID", "Postcode", "City", "Country", "State", "ID"])
addresses.to_sql("ADDRESS", connection, if_exists="append", index=False)

orders = pd.DataFrame(order_rows, columns=[
    "Order_Id", "Order_Date", "Status", "ID", "AddressID"])
orders.to_sql("ORDERS", connection, if_exists="append", index=False)

shipments = pd.DataFrame(shipment_rows, columns=[
    "Shipment_Id", "Courier_Status", "Fulfilment", "Order_Id"])
shipments.to_sql("SHIPMENT", connection, if_exists="append", index=False)

items = pd.DataFrame(item_rows, columns=[
    "Quantity", "Amount", "Line_Number", "Currency", "Order_Id", "Product_Id"])
items.to_sql("ORDER_ITEM", connection, if_exists="append", index=False)

payments = pd.DataFrame(payment_rows, columns=[
    "Payment_Id", "Method", "Amount", "Payment_Status", "Paid_At", "Order_Id"])
payments.to_sql("PAYMENT", connection, if_exists="append", index=False)

connection.commit()
connection.close()