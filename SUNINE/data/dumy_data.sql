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
-- (AUTO_INCREMENT values for farmId will typically start from 1)
INSERT INTO Item (itemName, itemRank, price, cultivationDate, farmId, averageRating) VALUES
('프리미엄 샤인머스캣 2kg', '특', 35000, '2023-09-01', 1, 4.5),
('가정용 샤인머스캣 4kg', '상', 55000, '2023-09-15', 1, 4.2),
('유기농 샤인머스캣 1kg', '특', 25000, '2023-08-25', 2, 4.8),
('GAP 인증 샤인머스캣 3kg', '중', 40000, '2023-09-10', 2, DEFAULT),
('일반 샤인머스캣 5kg', '하', 60000, '2023-09-20', 1, 3.9);

-- Order table
-- Assuming customerId 1-5 and itemId 1-5 exist
INSERT INTO `Order` (customerId, itemId, quantity, orderDate, deliveryAddress, orderStatus) VALUES
(1, 1, 1, '2023-10-01 10:00:00', '서울시 강남구 테헤란로 123', 'DELIVERED'),
(2, 3, 2, '2023-10-05 14:30:00', '부산시 해운대구 마린시티로 456', 'SHIPPED'),
(3, 2, 1, '2023-10-10 09:15:00', '인천시 연수구 송도국제대로 789', 'ORDERED'),
(1, 4, 3, '2023-10-12 11:00:00', '서울시 강남구 봉은사로 524', 'REFUND_REQUESTED'),
(4, 5, 1, '2023-10-15 16:45:00', '대전시 유성구 대학로 101', 'DELIVERED'),
(5, 1, 2, '2023-10-18 10:20:00', '광주시 서구 상무중앙로 202', 'ORDERED'),
(2, 5, 1, '2023-10-20 12:00:00', '부산시 수영구 광안해변로 219', 'SHIPPED');

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
