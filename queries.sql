-- Q5: use case queries (SQLite). Run on the populated database.

-- USE CASE 1: CUSTOMER SPENDING PROFILE (example customer ID 206)
-- Cancelled and returned orders are excluded because the money was not kept.

-- 1.1 Running total of what the customer has spent, order by order
SELECT ROW_NUMBER() OVER (ORDER BY ORDERS.Order_Date, ORDERS.Order_Id) AS Order_Number,
       ORDERS.Order_Id, ORDERS.Order_Date, ORDER_ITEM.Amount,
       ROUND(SUM(ORDER_ITEM.Amount) OVER (ORDER BY ORDERS.Order_Date, ORDERS.Order_Id), 2) AS Running_Total
FROM ORDERS
JOIN ORDER_ITEM ON ORDER_ITEM.Order_Id = ORDERS.Order_Id
WHERE ORDERS.ID = 206
  AND ORDERS.Status NOT IN ('Cancelled', 'Returned')
ORDER BY ORDERS.Order_Date, ORDERS.Order_Id;

-- 1.2 Categories the customer buys from most
SELECT CATEGORY.Category_Name,
       COUNT(*) AS Number_Of_Orders,
       SUM(ORDER_ITEM.Quantity) AS Items_Bought,
       ROUND(SUM(ORDER_ITEM.Amount), 2) AS Total_Spent
FROM ORDERS
JOIN ORDER_ITEM ON ORDER_ITEM.Order_Id = ORDERS.Order_Id
JOIN PRODUCT ON PRODUCT.Product_Id = ORDER_ITEM.Product_Id
JOIN CATEGORY ON CATEGORY.Category_Id = PRODUCT.Category_Id
WHERE ORDERS.ID = 206
  AND ORDERS.Status NOT IN ('Cancelled', 'Returned')
GROUP BY CATEGORY.Category_Name
ORDER BY Total_Spent DESC;


-- USE CASE 2: ORDER AND STOCK MANAGEMENT

-- 2.2 Share of orders in each status
SELECT Status,
       COUNT(*) AS Number_Of_Orders,
       ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 1) AS Percentage_Of_Orders
FROM ORDERS
GROUP BY Status
ORDER BY Number_Of_Orders DESC;

-- 2.3 Restock list: products with 5 or fewer units left, best sellers first
SELECT PRODUCT.Product_Id, PRODUCT.Product_Name, CATEGORY.Category_Name,
       PRODUCT.Stock_Quantity,
       COALESCE(SUM(ORDER_ITEM.Quantity), 0) AS Units_Sold
FROM PRODUCT
JOIN CATEGORY ON CATEGORY.Category_Id = PRODUCT.Category_Id
LEFT JOIN ORDER_ITEM ON ORDER_ITEM.Product_Id = PRODUCT.Product_Id
WHERE PRODUCT.Stock_Quantity <= 5
GROUP BY PRODUCT.Product_Id, PRODUCT.Product_Name, CATEGORY.Category_Name, PRODUCT.Stock_Quantity
ORDER BY Units_Sold DESC;


-- USE CASE 3: SALES AND CUSTOMER ACTIVITY

-- 3.1 Revenue by category (cancelled and returned orders excluded)
SELECT CATEGORY.Category_Name,
       COUNT(*) AS Number_Of_Orders,
       ROUND(SUM(ORDER_ITEM.Amount), 2) AS Revenue,
       ROUND(AVG(ORDER_ITEM.Amount), 2) AS Average_Order_Value
FROM ORDERS
JOIN ORDER_ITEM ON ORDER_ITEM.Order_Id = ORDERS.Order_Id
JOIN PRODUCT ON PRODUCT.Product_Id = ORDER_ITEM.Product_Id
JOIN CATEGORY ON CATEGORY.Category_Id = PRODUCT.Category_Id
WHERE ORDERS.Status NOT IN ('Cancelled', 'Returned')
GROUP BY CATEGORY.Category_Name
ORDER BY Revenue DESC;

-- 3.2 Registered customers who never placed an order (oldest registrations first)
SELECT CUSTOMER.ID, CUSTOMER.FName, CUSTOMER.LName, CUSTOMER.Email,
       CUSTOMER.Registered_Date
FROM CUSTOMER
WHERE CUSTOMER.ID NOT IN (SELECT ORDERS.ID FROM ORDERS)
ORDER BY CUSTOMER.Registered_Date, CUSTOMER.ID
LIMIT 10;