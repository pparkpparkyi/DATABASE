-- =============================================================================
-- SUNINE (순이네 샤인머스캣 농장) 데이터베이스 테스트 시나리오 SQL 스크립트
-- =============================================================================
-- 이 스크립트는 SUNINE/test_scenarios.md 파일의 내용을 기반으로 생성되었습니다.
--
-- 참고:
-- 1. 이 스크립트에 사용된 ID 값(예: customerId = 1, itemId = 1 등)은
--    플레이스홀더입니다. `master_setup.sql`을 통해 데이터를 먼저 삽입한 경우,
--    해당 스크립트에 의해 생성된 실제 ID를 참조하여 이 스크립트의 ID 값을
--    적절히 수정해야 할 수 있습니다.
-- 2. 각 시나리오는 독립적으로 실행 가능하도록 작성되었으나, 일부 시나리오는
--    특정 상태(예: 'REFUND_REQUESTED' 상태의 주문)를 전제로 할 수 있습니다.
--    필요에 따라 `master_setup.sql`을 먼저 실행하여 초기 데이터를 구성하십시오.
-- 3. 확인(Verification) 쿼리는 기본적으로 주석 처리되어 있습니다.
--    각 실행 단계 후 주석을 해제하여 결과를 확인할 수 있습니다.
-- =============================================================================

-- 데이터베이스 선택 (필요한 경우 주석 해제)
-- USE sunine_db;

-- -----------------------------------------------------------------------------
-- 시나리오 1: 신규 고객 등록 및 선호 등급 설정
-- 설명: 신규 고객이 시스템에 가입하고, 선호하는 샤인머스캣 등급을 설정합니다.
-- -----------------------------------------------------------------------------

-- 1. 신규 고객 등록
INSERT INTO Customer (password, address) VALUES ('new_password123', '서울시 마포구 월드컵북로 400');
-- (생성된 customerId 확인, 예: 6 가정. MySQL에서는 SELECT LAST_INSERT_ID(); 로 확인 가능)
-- SELECT LAST_INSERT_ID() AS new_customerId;

-- 2. 선호 등급 설정 (방금 가입한 고객 ID 사용, 아래는 예시로 customerId = 6 사용)
-- 실제 사용 시에는 위 INSERT 후 반환된 customerId를 사용해야 합니다.
INSERT INTO PreferRank (customerId, itemRank) VALUES (6, '특');
INSERT INTO PreferRank (customerId, itemRank) VALUES (6, '상');

-- 확인:
-- SELECT * FROM Customer WHERE customerId = 6;
-- SELECT * FROM PreferRank WHERE customerId = 6;

-- -----------------------------------------------------------------------------
-- 시나리오 2: 고객 상품 주문
-- 설명: 기존 고객이 특정 샤인머스캣 상품을 주문합니다.
-- -----------------------------------------------------------------------------

-- (customerId = 1, itemId = 2, 수량 = 1 가정)
INSERT INTO `Order` (customerId, itemId, quantity, deliveryAddress)
VALUES (1, 2, 1, '서울시 강남구 테헤란로 123 (기존 주소와 동일)');
-- (생성된 orderId 확인, 예: 8 가정. MySQL에서는 SELECT LAST_INSERT_ID(); 로 확인 가능)
-- SELECT LAST_INSERT_ID() AS new_orderId;

-- 확인:
-- SELECT * FROM `Order` WHERE orderId = 8; -- 실제 생성된 orderId 값으로 변경

-- -----------------------------------------------------------------------------
-- 시나리오 3: 고객 리뷰 작성 (트리거 `trg_update_avg_rating` 테스트)
-- 설명: 고객이 주문했던 상품에 대해 리뷰를 작성합니다. 이 때, `Item` 테이블의 `averageRating`이 올바르게 업데이트되는지 확인합니다.
-- -----------------------------------------------------------------------------

-- (customerId = 1, itemId = 1 (주문 1번 상품) 가정, 평점 = 5)
-- 먼저 Item ID 1의 현재 평균 평점 확인 (선택적)
-- SELECT itemId, itemName, averageRating FROM Item WHERE itemId = 1;

INSERT INTO Review (customerId, itemId, rating, comment)
VALUES (1, 1, 5, '역시 믿고 먹는 햇살농장 샤인머스캣! 최고예요.');
-- (생성된 reviewId 확인. MySQL에서는 SELECT LAST_INSERT_ID(); 로 확인 가능)
-- SELECT LAST_INSERT_ID() AS new_reviewId;

-- 확인:
-- -- Review 테이블 확인
-- SELECT * FROM Review WHERE customerId = 1 AND itemId = 1 ORDER BY createdAt DESC LIMIT 1;
-- -- Item 테이블의 averageRating 확인
-- SELECT itemId, itemName, averageRating FROM Item WHERE itemId = 1;

-- -----------------------------------------------------------------------------
-- 시나리오 4: 고객 불량/결함 보고 (트리거 `trg_update_order_status_on_defect` 테스트)
-- 설명: 고객이 주문한 상품에 대해 불량/결함을 보고합니다. 이 때, 해당 주문의 상태가 'REFUND_REQUESTED'로 변경되는지 확인합니다.
-- -----------------------------------------------------------------------------

-- (orderId = 3 (고객 3, 아이템 2), itemId = 2, customerId = 3 가정)
-- 먼저 Order ID 3의 현재 상태 확인 (선택적)
-- SELECT orderId, orderStatus FROM `Order` WHERE orderId = 3;

INSERT INTO DefectReport (orderId, itemId, customerId, reason, imageUrl)
VALUES (3, 2, 3, '포장 상태 불량 및 일부 포도알 터짐.', 'http://example.com/defect_image.jpg');
-- (생성된 reportId 확인, 예: 4 가정. MySQL에서는 SELECT LAST_INSERT_ID(); 로 확인 가능)
-- SELECT LAST_INSERT_ID() AS new_reportId;

-- 확인:
-- -- DefectReport 테이블 확인
-- SELECT * FROM DefectReport WHERE reportId = 4; -- 실제 생성된 reportId 값으로 변경
-- -- Order 테이블의 orderStatus 확인
-- SELECT orderId, orderStatus FROM `Order` WHERE orderId = 3;

-- -----------------------------------------------------------------------------
-- 시나리오 5: 환불 처리 (프로시저 `proc_process_refund` 테스트)
-- 설명: 관리자가 접수된 불량 보고에 대해 환불을 처리합니다.
-- 선행 조건:
--   - `Order` 테이블에 `orderStatus = 'REFUND_REQUESTED'`인 주문이 존재해야 합니다 (예: `orderId = 4`).
--   - `DefectReport` 테이블에 해당 `orderId`와 연결된 보고가 존재해야 합니다 (예: `reportId = 1`).
--   (master_setup.sql 실행 시 orderId=4, reportId=1 이 이 조건에 해당될 수 있음)
-- -----------------------------------------------------------------------------

-- (orderId = 4, reportId = 1 가정)
-- 처리 전 상태 확인 (선택적)
-- SELECT orderId, orderStatus FROM `Order` WHERE orderId = 4;
-- SELECT reportId, processed, refundAmount FROM DefectReport WHERE reportId = 1;

CALL proc_process_refund(4, 1);

-- 확인:
-- -- DefectReport 테이블 확인
-- SELECT reportId, processed, refundAmount FROM DefectReport WHERE reportId = 1;
-- -- Order 테이블의 orderStatus 확인
-- SELECT orderId, orderStatus FROM `Order` WHERE orderId = 4;
-- -- Item 테이블에서 해당 상품의 가격과 주문 수량 확인 (v_amount 계산 검증용)
-- SELECT I.price, O.quantity, (I.price * O.quantity) AS expectedRefundAmount
-- FROM `Order` O JOIN Item I ON O.itemId = I.itemId
-- WHERE O.orderId = 4;

-- -----------------------------------------------------------------------------
-- 시나리오 6: 상품별 불량률 계산 (함수 `fn_get_defectRate` 테스트)
-- 설명: 특정 상품의 전체 주문 대비 불량 보고 비율을 계산합니다.
-- -----------------------------------------------------------------------------

-- (itemId = 4 가정)
-- master_setup.sql 실행 시 itemId=4는 Order 1건(orderId=4), DefectReport 1건(reportId=1) 존재. 예상 불량률 1.0
SELECT fn_get_defectRate(4) AS defectRate_Item4;

-- (선택적) 수동 계산 (itemId = 4):
-- SELECT
--     (SELECT COUNT(*) FROM DefectReport WHERE itemId = 4) AS defect_reports,
--     (SELECT COUNT(*) FROM `Order` WHERE itemId = 4) AS total_orders,
--     (SELECT COUNT(*) FROM DefectReport WHERE itemId = 4) /
--     (SELECT COUNT(*) FROM `Order` WHERE itemId = 4)
-- AS manual_defect_rate;

-- (itemId = 1 가정)
-- master_setup.sql 실행 시 itemId=1은 Order 2건(orderId=1, 6), DefectReport 1건(reportId=3, orderId=1) 존재. 예상 불량률 0.5
SELECT fn_get_defectRate(1) AS defectRate_Item1;

-- -----------------------------------------------------------------------------
-- 시나리오 7: 품질 검사 등록 (프로시저 `proc_register_inspection` 테스트)
-- 설명: 농장 작업자가 특정 상품 및 농장에 대한 품질 검사 결과를 시스템에 등록합니다.
-- -----------------------------------------------------------------------------

-- (itemId = 1, farmId = 1, 검사 결과 = 'PASS', 검사자 = '홍길동' 가정)
CALL proc_register_inspection(1, 1, 'PASS', '홍길동');
-- (QualityInspection 테이블의 auto_increment로 생성된 inspectionId 확인)
-- SELECT LAST_INSERT_ID() AS new_inspectionId;

-- 확인:
-- SELECT * FROM QualityInspection
-- WHERE itemId = 1 AND farmId = 1 AND inspectorName = '홍길동'
-- ORDER BY inspectionDate DESC LIMIT 1;

-- =============================================================================
-- 테스트 시나리오 SQL 스크립트 종료
-- =============================================================================
