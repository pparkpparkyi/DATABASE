DELIMITER $$
CREATE PROCEDURE proc_process_refund(IN p_orderId INT)
BEGIN
    DECLARE v_amount INT;

    SELECT price * quantity INTO v_amount
    FROM `Order` O
    JOIN Item I ON O.itemId = I.itemId
    WHERE O.orderId = p_orderId;

    UPDATE `Order`
    SET orderStatus = 'REFUNDED'
    WHERE orderId = p_orderId;

    INSERT INTO DefectReport (orderId, itemId, customerId, reason, reportedAt, processed, refundAmount)
    SELECT orderId, itemId, customerId, '자동 환불 처리', NOW(), TRUE, v_amount
    FROM `Order`
    WHERE orderId = p_orderId;
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
DELIMITER ;
