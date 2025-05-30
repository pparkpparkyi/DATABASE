DELIMITER $$
CREATE TRIGGER trg_update_order_status_on_defect
AFTER INSERT ON DefectReport
FOR EACH ROW
BEGIN
    UPDATE `Order`
    SET orderStatus = 'REFUND_REQUESTED'
    WHERE orderId = NEW.orderId;
END$$

CREATE TRIGGER trg_update_avg_rating
AFTER INSERT ON Review
FOR EACH ROW
BEGIN
    UPDATE Item
    SET averageRating = (
        SELECT AVG(rating)
        FROM Review
        WHERE itemId = NEW.itemId
    )
    WHERE itemId = NEW.itemId;
END$$

CREATE TRIGGER trg_update_stock_on_harvest
AFTER INSERT ON HarvestLog
FOR EACH ROW
BEGIN
    UPDATE Item
    SET itemStock = itemStock + NEW.quantityHarvested
    WHERE itemId = NEW.itemId;
END$$

CREATE TRIGGER trg_decrease_stock_on_order
AFTER INSERT ON `Order`
FOR EACH ROW
BEGIN
    UPDATE Item
    SET itemStock = itemStock - NEW.quantity
    WHERE itemId = NEW.itemId;
END$$

CREATE TRIGGER trg_update_preferrank_on_review
AFTER INSERT ON Review
FOR EACH ROW
BEGIN
    DECLARE v_itemRank VARCHAR(10);
    IF NEW.rating >= 4 THEN
        SELECT itemRank INTO v_itemRank FROM Item WHERE itemId = NEW.itemId;
        IF v_itemRank IS NOT NULL THEN
            INSERT IGNORE INTO PreferRank (customerId, itemRank) VALUES (NEW.customerId, v_itemRank);
        END IF;
    END IF;
END$$
DELIMITER ;
