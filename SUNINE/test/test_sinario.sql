-- =============================================================================
-- SUNINE (순이네 샤인머스캣 농장) 데이터베이스 테스트 시나리오 SQL 스크립트
-- =============================================================================
-- 이 스크립트는 SUNINE/test_scenarios.md 파일의 내용을 기반으로 생성되었습니다.
--
-- 참고:
-- 1. 이 스크립트에 사용된 ID 값(예: customerId = 1, itemId = 1 등)은
--    플레이스홀더입니다. `master_setup.sql`을 통해 데이터를 먼저 삽입한 경우,
--    해당 스크립트에 의해 생성된 실제 ID를 참조하여 이 스크립트의 ID 값을
--    적절히 수정해야 할 수 있습니다. `dummy_data.sql`의 초기 `itemStock` 값과
--    `HarvestLog` 및 `Order` 삽입으로 인한 재고 변경을 고려하여 ID를 선택하십시오.
-- 2. 각 시나리오는 독립적으로 실행 가능하도록 작성되었으나, 일부 시나리오는
--    특정 상태(예: 'REFUND_REQUESTED' 상태의 주문)를 전제로 할 수 있습니다.
--    필요에 따라 `master_setup.sql`을 먼저 실행하여 초기 데이터를 구성하십시오.
-- 3. 확인(Verification) 쿼리는 기본적으로 주석 처리되어 있습니다.
--    각 실행 단계 후 주석을 해제하여 결과를 확인할 수 있습니다.
-- =============================================================================

-- 데이터베이스 선택 (필요한 경우 주석 해제)
DROP DATABASE IF EXIST sunine_db;
CREATE DATABASE IF NOT EXIST sunine_db;
USE sunine_db;

-- -----------------------------------------------------------------------------
-- 시나리오 1: 신규 고객 등록 및 선호 등급 설정
-- 설명: 신규 고객이 시스템에 가입하고, 선호하는 샤인머스캣 등급을 설정합니다.
-- -----------------------------------------------------------------------------
-- 1. 신규 고객 등록
INSERT INTO Customer (password, address) VALUES ('new_customer_pref_test', '서울시 용산구 한강대로 300');
-- (생성된 customerId 확인, 예: 다음 사용 가능한 ID 가정, 예: 6)
-- SELECT LAST_INSERT_ID() AS new_customerId;

-- 2. 선호 등급 설정 (방금 가입한 고객 ID 사용, LAST_INSERT_ID() 사용 권장)
INSERT INTO PreferRank (customerId, itemRank) VALUES (LAST_INSERT_ID(), '특');
-- INSERT INTO PreferRank (customerId, itemRank) VALUES (LAST_INSERT_ID(), '상'); -- 필요시 추가

-- 확인:
-- -- Customer 테이블 확인 (ID는 위 INSERT 결과에 따라 변경)
-- SELECT * FROM Customer WHERE customerId = (SELECT MAX(customerId) FROM Customer); -- 예시: 가장 최근 고객
-- -- PreferRank 테이블 확인 (ID는 위 INSERT 결과에 따라 변경)
-- SELECT * FROM PreferRank WHERE customerId = (SELECT MAX(customerId) FROM Customer); -- 예시: 가장 최근 고객

-- -----------------------------------------------------------------------------
-- 시나리오 2: 상품 수확 및 재고 업데이트 (트리거 `trg_update_stock_on_harvest` 테스트)
-- 설명: 농장에서 새로운 수확을 기록하면, `trg_update_stock_on_harvest` 트리거에 의해 해당 상품의 `Item.itemStock`이 자동으로 업데이트됩니다.
-- -----------------------------------------------------------------------------
-- (itemId = 1 가정, farmId = 1 가정)
-- 초기 재고 확인
SELECT itemId, itemName, itemStock FROM Item WHERE itemId = 1;

-- 상품 ID 1에 대한 새로운 수확 기록 (수량: 30)
INSERT INTO HarvestLog (itemId, farmId, quantityHarvested, harvestDate) VALUES (1, 1, 30, NOW());

-- 확인:
-- -- 업데이트된 재고 확인
-- SELECT itemId, itemName, itemStock FROM Item WHERE itemId = 1;
-- -- HarvestLog 확인
-- SELECT * FROM HarvestLog WHERE itemId = 1 ORDER BY harvestDate DESC LIMIT 1;

-- -----------------------------------------------------------------------------
-- 시나리오 3: 고객 상품 주문 및 재고 차감 (트리거 `trg_decrease_stock_on_order` 테스트)
-- 설명: 기존 고객이 특정 샤인머스캣 상품을 주문하면, `trg_decrease_stock_on_order` 트리거에 의해 해당 상품의 `Item.itemStock`이 자동으로 차감됩니다.
-- -----------------------------------------------------------------------------
-- (customerId = 1, itemId = 2 가정, 주문 수량 = 5)
-- 초기 재고 확인
SELECT itemId, itemName, itemStock FROM Item WHERE itemId = 2;

-- 고객 ID 1이 상품 ID 2를 5개 주문
INSERT INTO `Order` (customerId, itemId, quantity, deliveryAddress)
VALUES (1, 2, 5, '서울시 강남구 테헤란로 123 (테스트 주소)');
-- (생성된 orderId 확인)
-- SELECT LAST_INSERT_ID() AS new_orderId;

-- 확인:
-- -- 업데이트된 재고 확인
-- SELECT itemId, itemName, itemStock FROM Item WHERE itemId = 2;
-- -- 주문 내역 확인
-- SELECT * FROM `Order` WHERE orderId = LAST_INSERT_ID();

-- -----------------------------------------------------------------------------
-- 시나리오 4: 고객 리뷰 작성 (트리거 `trg_update_avg_rating` 테스트)
-- 설명: 고객이 주문했던 상품에 대해 리뷰를 작성합니다. 이 때, `Item` 테이블의 `averageRating`이 올바르게 업데이트되는지 확인합니다.
-- -----------------------------------------------------------------------------
-- (customerId = 1, itemId = 1 가정, 평점 = 4)
-- 초기 평균 평점 확인 (선택적)
-- SELECT itemId, itemName, averageRating FROM Item WHERE itemId = 1;

INSERT INTO Review (customerId, itemId, rating, comment)
VALUES (1, 1, 4, '만족합니다. 품질이 괜찮네요.');
-- (생성된 reviewId 확인)
-- SELECT LAST_INSERT_ID() AS new_reviewId;

-- 확인:
-- -- Review 테이블 확인
-- SELECT * FROM Review WHERE customerId = 1 AND itemId = 1 ORDER BY createdAt DESC LIMIT 1;
-- -- Item 테이블의 averageRating 확인
-- SELECT itemId, itemName, averageRating FROM Item WHERE itemId = 1;

-- -----------------------------------------------------------------------------
-- 시나리오 5: 높은 평점 리뷰로 인한 선호 등급 자동 업데이트 (트리거 `trg_update_preferrank_on_review` 테스트)
-- 설명: 고객이 상품에 대해 높은 평점(4점 이상)을 부여하면, `trg_update_preferrank_on_review` 트리거에 의해 해당 상품의 등급이 고객의 선호 등급(`PreferRank`)에 자동으로 (중복 방지하며) 추가됩니다.
-- -----------------------------------------------------------------------------
-- (customerId = 2, itemId = 3 (dummy_data.sql에서 rank '특') 가정, rating = 5)
-- Item ID 3의 등급 확인 (선택적)
-- SELECT itemId, itemRank FROM Item WHERE itemId = 3; -- '특' 등급이어야 함

-- 해당 고객의 해당 등급 선호도 초기 상태 확인 (선택적, 테스트 전 삭제하여 명확히 확인 가능)
-- DELETE FROM PreferRank WHERE customerId = 2 AND itemRank = '특';

INSERT INTO Review (customerId, itemId, rating, comment)
VALUES (2, 3, 5, '정말 최고의 샤인머스캣! 이 등급 팬이 되었어요.');

-- 확인:
-- SELECT * FROM PreferRank WHERE customerId = 2 AND itemRank = '특';

-- -----------------------------------------------------------------------------
-- 시나리오 6: 고객 불량/결함 보고 (트리거 `trg_update_order_status_on_defect` 테스트)
-- 설명: 고객이 주문한 상품에 대해 불량/결함을 보고합니다. 이 때, 해당 주문의 상태가 'REFUND_REQUESTED'로 변경되는지 확인합니다.
-- -----------------------------------------------------------------------------
-- (orderId = 3 (dummy_data.sql: 고객 3, 아이템 2), itemId = 2, customerId = 3 가정)
-- 초기 주문 상태 확인 (선택적)
-- SELECT orderId, orderStatus FROM `Order` WHERE orderId = 3;

INSERT INTO DefectReport (orderId, itemId, customerId, reason, imageUrl)
VALUES (3, 2, 3, '테스트용 불량 보고: 상품 일부 손상.', 'http://example.com/defect_test.jpg');
-- (생성된 reportId 확인)
-- SELECT LAST_INSERT_ID() AS new_reportId;

-- 확인:
-- -- DefectReport 테이블 확인 (가장 최근 reportId 또는 특정 reportId로 조회)
-- SELECT * FROM DefectReport ORDER BY reportId DESC LIMIT 1;
-- -- Order 테이블의 orderStatus 확인
-- SELECT orderId, orderStatus FROM `Order` WHERE orderId = 3;

-- -----------------------------------------------------------------------------
-- 시나리오 7: 환불 처리 (프로시저 `proc_process_refund` 테스트)
-- 설명: 관리자가 접수된 불량 보고에 대해 환불을 처리합니다.
-- 선행 조건:
--   - `Order` 테이블에 `orderStatus = 'REFUND_REQUESTED'`인 주문이 존재해야 합니다 (예: 시나리오 6의 `orderId = 3` 또는 `dummy_data.sql`의 `orderId = 4`).
--   - `DefectReport` 테이블에 해당 `orderId`와 연결된 보고가 존재해야 합니다.
-- -----------------------------------------------------------------------------
-- (dummy_data.sql의 orderId = 4, reportId = 1 가정)
-- 초기 상태 확인 (선택적)
-- SELECT orderStatus FROM `Order` WHERE orderId = 4;
-- SELECT processed, refundAmount FROM DefectReport WHERE reportId = 1;

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
-- 시나리오 8: 주문 빈도에 따른 선호 등급 자동 업데이트 (프로시저 `proc_update_preferrank_from_orders` 테스트)
-- 설명: 특정 고객이 특정 등급의 상품을 여러 번 주문한 경우, `proc_update_preferrank_from_orders` 프로시저를 실행하여 해당 등급을 고객의 선호 등급(`PreferRank`)에 자동으로 추가합니다. (임계값: 2회 초과 주문)
-- -----------------------------------------------------------------------------
-- 선행 조건 (예시 `customerId = 1`, `itemRank = '특'`):
-- `dummy_data.sql`에서 `customerId = 1`은 `itemId = 1`('특' 등급)을 2번 주문했습니다 (orderId 1, 6).
-- 프로시저의 기준이 `>2`이므로, 테스트를 위해 추가 주문이 필요합니다.
INSERT INTO `Order` (customerId, itemId, quantity, deliveryAddress) VALUES (1, 1, 1, '추가 주문 테스트 주소');
-- SELECT LAST_INSERT_ID() AS extra_orderId_for_customer1_item1;

-- 해당 고객의 해당 등급 선호도 초기 상태 확인 (선택적, 테스트 전 삭제하여 명확히 확인 가능)
-- DELETE FROM PreferRank WHERE customerId = 1 AND itemRank = '특';

-- 실행:
CALL proc_update_preferrank_from_orders(1); -- customerId = 1 대상

-- 확인:
-- SELECT * FROM PreferRank WHERE customerId = 1 AND itemRank = '특';

-- -----------------------------------------------------------------------------
-- 시나리오 9: 상품별 불량률 계산 (함수 `fn_get_defectRate` 테스트)
-- 설명: 특정 상품의 전체 주문 대비 불량 보고 비율을 계산합니다.
-- -----------------------------------------------------------------------------
-- (itemId = 4 가정, dummy_data.sql에 의해 주문 1건, 불량보고 1건 존재)
SELECT fn_get_defectRate(4) AS defectRate_Item4;

-- 확인:
-- -- 반환된 `defectRate_Item4` 값을 확인합니다. (예상: 1.0)
-- -- (선택적) 수동 계산:
-- SELECT
--     (SELECT COUNT(*) FROM DefectReport WHERE itemId = 4) AS num_defect_reports,
--     (SELECT COUNT(*) FROM `Order` WHERE itemId = 4) AS num_orders,
--     (SELECT COUNT(*) FROM DefectReport WHERE itemId = 4) /
--     (SELECT COUNT(*) FROM `Order` WHERE itemId = 4)
-- AS manual_defect_rate_Item4;

-- -----------------------------------------------------------------------------
-- 시나리오 10: 품질 검사 등록 (프로시저 `proc_register_inspection` 테스트)
-- 설명: 농장 작업자가 특정 상품 및 농장에 대한 품질 검사 결과를 시스템에 등록합니다.
-- -----------------------------------------------------------------------------
-- (itemId = 1, farmId = 1, 검사 결과 = 'PASS', 검사자 = '박철수' 가정)
CALL proc_register_inspection(1, 1, 'PASS', '박철수');
-- (QualityInspection 테이블의 auto_increment로 생성된 inspectionId 확인)
-- SELECT LAST_INSERT_ID() AS new_inspectionId;

-- 확인:
-- SELECT * FROM QualityInspection
-- WHERE itemId = 1 AND farmId = 1 AND inspectorName = '박철수'
-- ORDER BY inspectionDate DESC LIMIT 1;

-- =============================================================================
-- 테스트 시나리오 SQL 스크립트 종료
-- =============================================================================
