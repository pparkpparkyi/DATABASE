-- =============================================================================
-- Master Setup Script for SUNINE Database
-- =============================================================================
--
-- This script creates the database schema, sets up triggers,
-- procedures, functions, and populates the tables with dummy data.
--
-- How to Execute:
-- 1. Ensure you have MySQL server running.
-- 2. Create the database if it doesn't exist (e.g., CREATE DATABASE your_database_name;)
-- 3. Use the MySQL client to run this script:
--    mysql -u your_user -p your_database_name < SUNINE/master_setup.sql
--    (Replace your_user and your_database_name with your actual credentials/database)
--
-- Order of execution:
-- 1. Create Tables
-- 2. Create Triggers
-- 3. Create Procedures
-- 4. Create Functions
-- 5. Insert Dummy Data
--
-- =============================================================================

-- -----------------------------------------------------------------------------
-- 1. Create Tables
-- Source: SUNINE/schema/create_tables.sql
-- -----------------------------------------------------------------------------
-- 테이블 생성 ------------------------------------------------

CREATE TABLE Owner (
    ownerSsn VARCHAR(20) PRIMARY KEY,
    name VARCHAR(50),
    phone VARCHAR(20)
);

CREATE TABLE Farm (
    farmId INT AUTO_INCREMENT PRIMARY KEY,
    farmName VARCHAR(100),
    location VARCHAR(100),
    phone VARCHAR(20),
    ownerSsn VARCHAR(13),
    FOREIGN KEY (ownerSsn) REFERENCES Owner(ownerSsn)
);

CREATE TABLE Customer (
    customerId INT AUTO_INCREMENT PRIMARY KEY,
    password VARCHAR(100),
    address VARCHAR(200)
);

CREATE TABLE Item (
    itemId INT AUTO_INCREMENT PRIMARY KEY,
    itemName VARCHAR(100),
    itemRank VARCHAR(10),
    price INT,
    cultivationDate DATE,
    farmId INT,
    averageRating FLOAT DEFAULT 0,
    itemStock INT DEFAULT 0, -- New column
    FOREIGN KEY (farmId) REFERENCES Farm(farmId)
);

CREATE TABLE PreferRank (
    customerId INT,
    itemRank VARCHAR(10),
    PRIMARY KEY (customerId, itemRank),
    FOREIGN KEY (customerId) REFERENCES Customer(customerId)
);

CREATE TABLE `Order` (
    orderId INT AUTO_INCREMENT PRIMARY KEY,
    customerId INT,
    itemId INT,
    quantity INT,
    orderDate DATETIME DEFAULT CURRENT_TIMESTAMP,
    deliveryAddress VARCHAR(200),
    orderStatus VARCHAR(30) DEFAULT 'ORDERED',
    FOREIGN KEY (customerId) REFERENCES Customer(customerId),
    FOREIGN KEY (itemId) REFERENCES Item(itemId)
);

CREATE TABLE Review (
    reviewId INT AUTO_INCREMENT PRIMARY KEY,
    customerId INT,
    itemId INT,
    rating INT CHECK (rating BETWEEN 1 AND 5),
    comment TEXT,
    createdAt DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (customerId) REFERENCES Customer(customerId),
    FOREIGN KEY (itemId) REFERENCES Item(itemId)
);

CREATE TABLE DefectReport (
    reportId INT AUTO_INCREMENT PRIMARY KEY,
    orderId INT,
    itemId INT,
    customerId INT,
    reason TEXT,
    imageUrl TEXT,
    reportedAt DATETIME DEFAULT CURRENT_TIMESTAMP,
    processed BOOLEAN DEFAULT FALSE,
    refundAmount INT,
    FOREIGN KEY (orderId) REFERENCES `Order`(orderId),
    FOREIGN KEY (itemId) REFERENCES Item(itemId),
    FOREIGN KEY (customerId) REFERENCES Customer(customerId)
);

CREATE TABLE QualityInspection (
    inspectionId INT AUTO_INCREMENT PRIMARY KEY,
    itemId INT,
    farmId INT,
    inspectorName VARCHAR(100),
    inspectionDate DATE,
    inspectionResult VARCHAR(10),
    notes TEXT,
    FOREIGN KEY (itemId) REFERENCES Item(itemId),
    FOREIGN KEY (farmId) REFERENCES Farm(farmId)
);

CREATE TABLE HarvestLog (
    harvestId INT AUTO_INCREMENT PRIMARY KEY,
    itemId INT,
    farmId INT,
    quantityHarvested INT,
    harvestDate DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (itemId) REFERENCES Item(itemId),
    FOREIGN KEY (farmId) REFERENCES Farm(farmId)
);

-- -----------------------------------------------------------------------------
-- 2. Create Triggers
-- Source: SUNINE/triggers_procs/triggers.sql
-- -----------------------------------------------------------------------------
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

-- -----------------------------------------------------------------------------
-- 3. Create Procedures
-- Source: SUNINE/triggers_procs/procedures.sql
-- -----------------------------------------------------------------------------
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

-- -----------------------------------------------------------------------------
-- 4. Create Functions
-- Source: SUNINE/triggers_procs/functions.sql
-- -----------------------------------------------------------------------------
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

-- -----------------------------------------------------------------------------
-- 5. Insert Dummy Data
-- Source: SUNINE/data/dummy_data.sql
-- -----------------------------------------------------------------------------
-- Dummy data for SUNINE database

-- Owner table
INSERT INTO Owner (ownerSsn, name, phone) VALUES
('123456-1234567', '김철수', '010-1111-1111'),
('654321-7654321', '박영희', '010-2222-2222');

-- Farm table
INSERT INTO Farm (farmName, location, phone, ownerSsn) VALUES
('햇살농장', '경상북도 상주시', '054-111-1111', '123456-1234567'),
('푸른언덕농원', '전라남도 나주시', '061-222-2222', '654321-7654321');

-- Customer table
INSERT INTO Customer (password, address) VALUES
('pass123', '서울시 강남구 테헤란로 123'),
('securePwd', '부산시 해운대구 마린시티로 456'),
('myPassword!', '인천시 연수구 송도국제대로 789'),
('customerX', '대전시 유성구 대학로 101'),
('userABC', '광주시 서구 상무중앙로 202');

-- Item table
-- Assuming farmId 1 corresponds to '햇살농장' and farmId 2 to '푸른언덕농원'
-- itemStock is initial stock BEFORE HarvestLog entries are processed by trigger.
INSERT INTO Item (itemName, itemRank, price, cultivationDate, farmId, averageRating, itemStock) VALUES
('프리미엄 샤인머스캣 2kg', '특', 35000, '2023-09-01', 1, 4.5, 100),
('가정용 샤인머스캣 4kg', '상', 55000, '2023-09-15', 1, 4.2, 150),
('유기농 샤인머스캣 1kg', '특', 25000, '2023-08-25', 2, 4.8, 80),
('GAP 인증 샤인머스캣 3kg', '중', 40000, '2023-09-10', 2, DEFAULT, 120),
('일반 샤인머스캣 5kg', '하', 60000, '2023-09-20', 1, 3.9, 200);

-- Order table
-- Assuming customerId 1-5 and itemId 1-5 exist
-- These orders will DECREASE itemStock via trg_decrease_stock_on_order
INSERT INTO `Order` (customerId, itemId, quantity, orderDate, deliveryAddress, orderStatus) VALUES
(1, 1, 1, '2023-10-01 10:00:00', '서울시 강남구 테헤란로 123', 'DELIVERED'),       -- Item 1 stock: 100 - 1 = 99
(2, 3, 2, '2023-10-05 14:30:00', '부산시 해운대구 마린시티로 456', 'SHIPPED'),       -- Item 3 stock: 80 - 2 = 78
(3, 2, 1, '2023-10-10 09:15:00', '인천시 연수구 송도국제대로 789', 'ORDERED'),       -- Item 2 stock: 150 - 1 = 149
(1, 4, 3, '2023-10-12 11:00:00', '서울시 강남구 봉은사로 524', 'REFUND_REQUESTED'), -- Item 4 stock: 120 - 3 = 117
(4, 5, 1, '2023-10-15 16:45:00', '대전시 유성구 대학로 101', 'DELIVERED'),       -- Item 5 stock: 200 - 1 = 199
(5, 1, 2, '2023-10-18 10:20:00', '광주시 서구 상무중앙로 202', 'ORDERED'),       -- Item 1 stock: 99 - 2 = 97
(2, 5, 1, '2023-10-20 12:00:00', '부산시 수영구 광안해변로 219', 'SHIPPED');       -- Item 5 stock: 199 - 1 = 198

-- Review table
-- Assuming customerId 1-5 and itemId 1-5 exist
INSERT INTO Review (customerId, itemId, rating, comment, createdAt) VALUES
(1, 1, 5, '정말 맛있어요! 알도 크고 달콤합니다.', '2023-10-05 10:00:00'),
(2, 3, 4, '품질이 좋네요. 배송도 빨랐어요.', '2023-10-08 11:30:00'),
(4, 5, 5, '최고의 샤인머스캣입니다. 재구매 의사 있습니다!', '2023-10-18 09:00:00'),
(1, 4, 2, '기대했던 것보다는 별로네요. 일부 포도알이 물렀어요.', '2023-10-15 10:00:00');

-- DefectReport table
-- Assuming orderId, itemId, customerId correspond to existing records
-- orderId will typically be 1, 2, 3, 4, 5, 6, 7 based on the Order inserts above
INSERT INTO DefectReport (orderId, itemId, customerId, reason, imageUrl, reportedAt, processed, refundAmount) VALUES
(4, 4, 1, '포도알 일부가 물러져 있고, 맛이 시큼합니다. 환불 요청합니다.', 'http://example.com/defect1.jpg', '2023-10-15 09:50:00', FALSE, NULL),
(2, 3, 2, '배송 중 박스가 파손되어 포장이 훼손되었습니다.', 'http://example.com/defect2.jpg', '2023-10-07 18:00:00', FALSE, NULL),
(1, 1, 1, '단순 변심으로 인한 환불 요청 (처리 완료 건)', 'http://example.com/completed_refund.jpg', '2023-10-03 10:00:00', TRUE, 35000);

-- PreferRank table
-- Assuming customerId 1-5 exist and itemRank values are from '특', '상', '중', '하'
INSERT INTO PreferRank (customerId, itemRank) VALUES
(1, '특'),
(1, '상'),
(2, '특'),
(3, '중'),
(5, '상');

-- QualityInspection table
-- Assuming itemId 1-5 and farmId 1-2 exist
INSERT INTO QualityInspection (itemId, farmId, inspectorName, inspectionDate, inspectionResult, notes) VALUES
(1, 1, '김인수 검사관', '2023-08-28', 'PASS', '당도 및 크기 기준치 통과'),
(3, 2, '박현지 검사관', '2023-08-20', 'PASS', '친환경 인증 기준 적합, 일부 샘플 당도 미달'),
(5, 1, '김인수 검사관', '2023-09-18', 'FAIL', '전반적인 상품성 부족, 폐기 대상');

-- HarvestLog Sample Data
-- These inserts will INCREASE itemStock via trg_update_stock_on_harvest
-- Item stocks after these and orders:
-- Item 1: 100 (initial) - 1 (order1) - 2 (order6) + 50 (harvest1) = 147
-- Item 2: 150 (initial) - 1 (order3) + 75 (harvest2) = 224
-- Item 3: 80  (initial) - 2 (order2) + 60 (harvest3) = 138
-- Item 4: 120 (initial) - 3 (order4) = 117
-- Item 5: 200 (initial) - 1 (order5) - 1 (order7) = 198
INSERT INTO HarvestLog (itemId, farmId, quantityHarvested, harvestDate) VALUES
(1, 1, 50, NOW() - INTERVAL 7 DAY),
(2, 1, 75, NOW() - INTERVAL 5 DAY),
(3, 2, 60, NOW() - INTERVAL 3 DAY);

-- =============================================================================
-- End of Master Setup Script
-- =============================================================================
