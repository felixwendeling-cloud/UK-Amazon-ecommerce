-- Views (run after schema.sql). They hold derived data, so nothing is stored twice.

-- Total value and number of lines per order. The order total is not stored in ORDERS.
CREATE VIEW ORDER_TOTAL AS
SELECT Order_Id, COUNT(*) AS Number_Of_Lines, SUM(Amount) AS Order_Total
FROM ORDER_ITEM
GROUP BY Order_Id;

-- One row per customer order with its total, for customer-level reporting.
-- Depends on ORDER_TOTAL, so it must be created after it.
CREATE VIEW CUSTOMER_ORDER_HISTORY AS
SELECT CUSTOMER.ID, CUSTOMER.FName, CUSTOMER.LName,
       ORDERS.Order_Id, ORDERS.Order_Date, ORDERS.Status,
       ORDER_TOTAL.Order_Total
FROM CUSTOMER
JOIN ORDERS ON ORDERS.ID = CUSTOMER.ID
LEFT JOIN ORDER_TOTAL ON ORDER_TOTAL.Order_Id = ORDERS.Order_Id;

-- Units sold and remaining stock per product; products never ordered show 0.
CREATE VIEW PRODUCT_SALES AS
SELECT PRODUCT.Product_Id, PRODUCT.Product_Name, CATEGORY.Category_Name,
       PRODUCT.Stock_Quantity,
       COALESCE(SUM(ORDER_ITEM.Quantity), 0) AS Units_Sold
FROM PRODUCT
JOIN CATEGORY ON CATEGORY.Category_Id = PRODUCT.Category_Id
LEFT JOIN ORDER_ITEM ON ORDER_ITEM.Product_Id = PRODUCT.Product_Id
GROUP BY PRODUCT.Product_Id;