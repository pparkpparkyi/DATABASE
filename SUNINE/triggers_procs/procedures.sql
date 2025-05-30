DELIMITER $$
-- Stored procedure to process a refund for an order and update the defect report.
--
-- Parameters:
--   p_orderId: The ID of the order to be refunded.
--   p_reportId: The ID of the defect report related to the order.
CREATE PROCEDURE proc_process_refund(IN p_orderId INT, IN p_reportId INT)
BEGIN
    DECLARE v_amount INT;

    -- Calculate the refund amount based on the item price and order quantity.
    SELECT price * quantity INTO v_amount
    FROM `Order` O
    JOIN Item I ON O.itemId = I.itemId
    WHERE O.orderId = p_orderId;

    -- Update the order status to 'REFUNDED'.
    UPDATE `Order`
    SET orderStatus = 'REFUNDED'
    WHERE orderId = p_orderId;

    -- Update the defect report to mark it as processed and record the refund amount.
    UPDATE DefectReport
    SET processed = TRUE, refundAmount = v_amount
    WHERE reportId = p_reportId;
END$$

CREATE PROCEDURE proc_register_inspection(
    IN p_itemId INT,
    IN p_farmId INT,
    IN p_result VARCHAR(10),
    IN p_inspector VARCHAR(100)
)
BEGIN
    INSERT INTO QualityInspection(itemId, farmId, inspectorName, inspectionDate, inspectionResult)
    VALUES (p_itemId, p_farmId, p_inspector, CURDATE(), p_result);
END$$

CREATE PROCEDURE proc_update_preferrank_from_orders(IN p_customerId INT)
BEGIN
    DECLARE done INT DEFAULT FALSE;
    DECLARE v_itemRank VARCHAR(10);
    DECLARE v_orderCount INT; -- Though v_orderCount is fetched, it's not directly used after HAVING.
                            -- It's implicitly used by the HAVING COUNT(*) > 2 filter.
    DECLARE cur_ranks CURSOR FOR
        SELECT I.itemRank, COUNT(*) AS orderCount
        FROM `Order` O
        JOIN Item I ON O.itemId = I.itemId
        WHERE O.customerId = p_customerId
        GROUP BY I.itemRank
        HAVING COUNT(*) > 2; -- Threshold: ordered more than 2 times
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = TRUE;

    OPEN cur_ranks;
    read_loop: LOOP
        FETCH cur_ranks INTO v_itemRank, v_orderCount;
        IF done THEN
            LEAVE read_loop;
        END IF;
        INSERT IGNORE INTO PreferRank (customerId, itemRank) VALUES (p_customerId, v_itemRank);
    END LOOP;
    CLOSE cur_ranks;
END$$
DELIMITER ;
