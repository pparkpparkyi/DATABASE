DELIMITER $$
CREATE FUNCTION fn_get_defectRate(p_itemId INT)
RETURNS FLOAT
DETERMINISTIC
BEGIN
    DECLARE totalOrders INT DEFAULT 0;
    DECLARE defectCount INT DEFAULT 0;

    SELECT COUNT(*) INTO totalOrders FROM `Order` WHERE itemId = p_itemId;
    SELECT COUNT(*) INTO defectCount FROM DefectReport WHERE itemId = p_itemId;

    IF totalOrders = 0 THEN
        RETURN 0;
    ELSE
        RETURN defectCount / totalOrders;
    END IF;
END$$
DELIMITER ;
