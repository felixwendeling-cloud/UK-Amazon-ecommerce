-- Q6: trigger tests. Run after schema.sql and triggers.sql on the populated database.
-- Each test is followed by a SELECT showing the database state afterwards.

-- SETUP: test product (stock 10) and test order, not part of the generated data
INSERT INTO PRODUCT (Product_Id, SKU, ASIN, Style, Size, Unit_Price, Stock_Quantity, Product_Name, Category_Id)
VALUES (9001, 'TEST-9001', 'B0TEST9001', 'Black', NULL, 10.00, 10, 'Test Product', 1);

INSERT INTO ORDERS (Order_Id, Order_Date, Status, ID, AddressID)
VALUES ('ORD-TEST1', '2025-12-31', 'Pending', 1,
        (SELECT MIN(AddressID) FROM ADDRESS WHERE ID = 1));


-- SITUATION 1: STOCK AVAILABILITY

-- TEST 1.1  success expected: 3 <= 10, so the line is added and stock falls to 7
INSERT INTO ORDER_ITEM (Quantity, Amount, Line_Number, Currency, Order_Id, Product_Id)
VALUES (3, 30.00, 1, 'GBP', 'ORD-TEST1', 9001);

SELECT Product_Id, Stock_Quantity FROM PRODUCT WHERE Product_Id = 9001;


-- TEST 1.2  error expected: 8 > 7, so the line is rejected and stock stays at 7
INSERT INTO ORDER_ITEM (Quantity, Amount, Line_Number, Currency, Order_Id, Product_Id)
VALUES (8, 80.00, 2, 'GBP', 'ORD-TEST1', 9001);

SELECT Product_Id, Stock_Quantity FROM PRODUCT WHERE Product_Id = 9001;


-- SITUATION 2: DELIVERY ADDRESS MUST BELONG TO THE CUSTOMER

-- TEST 2.1  success expected: customer 1 uses one of their own addresses
INSERT INTO ORDERS (Order_Id, Order_Date, Status, ID, AddressID)
VALUES ('ORD-TEST2', '2025-12-31', 'Pending', 1,
        (SELECT MIN(AddressID) FROM ADDRESS WHERE ID = 1));

SELECT Order_Id, ID AS Customer_Id, AddressID FROM ORDERS WHERE Order_Id LIKE 'ORD-TEST%';


-- TEST 2.2  error expected: customer 1 uses an address of customer 2, so no ORD-TEST3 row appears
INSERT INTO ORDERS (Order_Id, Order_Date, Status, ID, AddressID)
VALUES ('ORD-TEST3', '2025-12-31', 'Pending', 1,
        (SELECT MIN(AddressID) FROM ADDRESS WHERE ID = 2));

SELECT Order_Id, ID AS Customer_Id, AddressID FROM ORDERS WHERE Order_Id LIKE 'ORD-TEST%';