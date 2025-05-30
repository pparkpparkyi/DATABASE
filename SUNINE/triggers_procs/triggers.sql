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
DELIMITER ;
