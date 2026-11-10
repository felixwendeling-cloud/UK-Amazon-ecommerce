-- Q6: triggers (SQLite). Run after schema.sql.
-- They enforce rules that PRIMARY/FOREIGN KEY and CHECK constraints cannot express.

-- SITUATION 1: STOCK AVAILABILITY
-- Risk: an order line could ask for more units than the warehouse holds.

-- 1a: reject an order line if the quantity is bigger than the stock.
CREATE TRIGGER check_stock_before_order_item
BEFORE INSERT ON ORDER_ITEM
WHEN NEW.Quantity > (SELECT Stock_Quantity FROM PRODUCT WHERE Product_Id = NEW.Product_Id)
BEGIN
    SELECT RAISE(ABORT, 'Not enough stock for this product');
END;

-- 1b: after a valid order line is added, take its quantity out of the stock.
CREATE TRIGGER reduce_stock_after_order_item
AFTER INSERT ON ORDER_ITEM
BEGIN
    UPDATE PRODUCT
    SET Stock_Quantity = Stock_Quantity - NEW.Quantity
    WHERE Product_Id = NEW.Product_Id;
END;


-- SITUATION 2: DELIVERY ADDRESS MUST BELONG TO THE CUSTOMER
-- Risk: the foreign key only checks that the address exists, not whose it is.

-- 2a: reject a new order whose address belongs to another customer.
CREATE TRIGGER check_order_address_insert
BEFORE INSERT ON ORDERS
WHEN (SELECT ID FROM ADDRESS WHERE AddressID = NEW.AddressID) <> NEW.ID
BEGIN
    SELECT RAISE(ABORT, 'The delivery address does not belong to this customer');
END;

-- 2b: the same check when the customer or the address of an order is changed.
CREATE TRIGGER check_order_address_update
BEFORE UPDATE OF ID, AddressID ON ORDERS
WHEN (SELECT ID FROM ADDRESS WHERE AddressID = NEW.AddressID) <> NEW.ID
BEGIN
    SELECT RAISE(ABORT, 'The delivery address does not belong to this customer');
END;