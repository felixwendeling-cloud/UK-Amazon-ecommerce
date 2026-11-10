-- E-commerce database schema (SQLite).
-- Run first. Tables are created parents before children so foreign keys resolve.
-- Order: CUSTOMER, ADDRESS, CATEGORY, PRODUCT, ORDERS, ORDER_ITEM, SHIPMENT, PAYMENT.
-- Enable foreign keys on every connection: PRAGMA foreign_keys = ON;

-- A person or business that buys. Email is optional but unique when present.
CREATE TABLE CUSTOMER
(
  MInitial VARCHAR(1),
  LName VARCHAR(40) NOT NULL,
  FName VARCHAR(40) NOT NULL,
  ID INT NOT NULL,
  Email VARCHAR(80),
  Phone VARCHAR(20),
  Registered_Date DATE NOT NULL,
  Is_Business INT NOT NULL CHECK (Is_Business IN (0, 1)),
  PRIMARY KEY (ID),
  UNIQUE (Email)
);

-- Delivery addresses; a customer can have several.
CREATE TABLE ADDRESS
(
  AddressID INT NOT NULL,
  Postcode VARCHAR(10),
  City VARCHAR(40) NOT NULL,
  Country VARCHAR(40) NOT NULL,
  State VARCHAR(40),
  ID INT NOT NULL,
  PRIMARY KEY (AddressID),
  FOREIGN KEY (ID) REFERENCES CUSTOMER(ID)
);

CREATE TABLE CATEGORY
(
  Category_Id INT NOT NULL,
  Category_Name VARCHAR(40) NOT NULL,
  PRIMARY KEY (Category_Id)
);

CREATE TABLE PRODUCT
(
  Product_Id INT NOT NULL,
  SKU VARCHAR(40) NOT NULL,
  ASIN VARCHAR(20) NOT NULL,
  Style VARCHAR(30),
  Size VARCHAR(20),
  Unit_Price NUMERIC(10,2) NOT NULL CHECK (Unit_Price >= 0),
  Stock_Quantity INT NOT NULL,
  Product_Name VARCHAR(80) NOT NULL,
  Category_Id INT NOT NULL,
  PRIMARY KEY (Product_Id),
  FOREIGN KEY (Category_Id) REFERENCES CATEGORY(Category_Id),
  UNIQUE (SKU)
);

-- One customer and one delivery address per order.
CREATE TABLE ORDERS
(
  Order_Id VARCHAR(30) NOT NULL,
  Order_Date DATE NOT NULL,
  Status VARCHAR(40) NOT NULL,
  ID INT NOT NULL,
  AddressID INT NOT NULL,
  PRIMARY KEY (Order_Id),
  FOREIGN KEY (ID) REFERENCES CUSTOMER(ID),
  FOREIGN KEY (AddressID) REFERENCES ADDRESS(AddressID)
);

-- Resolves the many-to-many link between ORDERS and PRODUCT.
-- Amount is the line total, so past orders keep their price if Unit_Price changes.
CREATE TABLE ORDER_ITEM
(
  Quantity INT NOT NULL CHECK (Quantity > 0),
  Amount NUMERIC(10,2) NOT NULL CHECK (Amount >= 0),
  Line_Number INT NOT NULL,
  Currency VARCHAR(10) NOT NULL,
  Order_Id VARCHAR(30) NOT NULL,
  Product_Id INT NOT NULL,
  PRIMARY KEY (Line_Number, Order_Id),
  FOREIGN KEY (Order_Id) REFERENCES ORDERS(Order_Id),
  FOREIGN KEY (Product_Id) REFERENCES PRODUCT(Product_Id)
);

-- At most one shipment per order (UNIQUE); orders not yet shipped have none.
CREATE TABLE SHIPMENT
(
  Shipment_Id INT NOT NULL,
  Courier_Status VARCHAR(40),
  Fulfilment VARCHAR(20) NOT NULL,
  Order_Id VARCHAR(30) NOT NULL,
  PRIMARY KEY (Shipment_Id),
  FOREIGN KEY (Order_Id) REFERENCES ORDERS(Order_Id),
  UNIQUE (Order_Id)
);

-- An order can have several payment attempts (e.g. declined, then accepted).
CREATE TABLE PAYMENT
(
  Payment_Id INT NOT NULL,
  Method VARCHAR(40) NOT NULL,
  Amount NUMERIC(10,2) NOT NULL CHECK (Amount >= 0),
  Payment_Status VARCHAR(20) NOT NULL CHECK (Payment_Status IN ('Accepted', 'Declined')),
  Paid_At DATE,
  Order_Id VARCHAR(30) NOT NULL,
  PRIMARY KEY (Payment_Id),
  FOREIGN KEY (Order_Id) REFERENCES ORDERS(Order_Id)
);