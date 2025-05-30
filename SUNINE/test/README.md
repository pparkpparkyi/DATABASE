# 순이네 샤인머스캣 농장: 데이터베이스 테스트 시나리오

이 문서는 "순이네 샤인머스캣 농장" 데이터베이스의 주요 기능에 대한 테스트 시나리오를 정의합니다.
각 시나리오는 설명, 실행을 위한 예제 SQL 쿼리 또는 프로시저 호출, 그리고 예상되는 결과를 포함합니다.

**참고:** 아래 예제 쿼리에 사용된 ID (예: `customerId = 1`, `itemId = 1`)는 플레이스홀더입니다. `master_setup.sql` 스크립트에 의해 실제로 삽입된 데이터에 따라 적절한 ID로 조정해야 합니다. `dummy_data.sql`의 초기 `itemStock` 값과 `HarvestLog` 및 `Order` 삽입으로 인한 재고 변경을 고려하여 ID를 선택하십시오.

---

## 시나리오 1: 신규 고객 등록 및 선호 등급 설정

-   **설명:** 신규 고객이 시스템에 가입하고, 선호하는 샤인머스캣 등급을 설정합니다.
-   **실행:**
    ```sql
    -- 1. 신규 고객 등록
    INSERT INTO Customer (password, address) VALUES ('new_customer_pref_test', '서울시 용산구 한강대로 300');
    -- (생성된 customerId 확인, 예: 다음 사용 가능한 ID 가정, 예: 6)
    -- SELECT LAST_INSERT_ID(); -- new_customerId 확인

    -- 2. 선호 등급 설정 (방금 가입한 고객 ID 사용)
    INSERT INTO PreferRank (customerId, itemRank) VALUES (LAST_INSERT_ID(), '특');
    -- INSERT INTO PreferRank (customerId, itemRank) VALUES (6, '상'); -- 필요시 추가
    ```
-   **확인:**
    ```sql
    -- Customer 테이블 확인 (ID는 위 INSERT 결과에 따라 변경)
    -- SELECT * FROM Customer WHERE customerId = 6;
    -- PreferRank 테이블 확인 (ID는 위 INSERT 결과에 따라 변경)
    -- SELECT * FROM PreferRank WHERE customerId = 6;
    ```
-   **예상 결과:**
    -   `Customer` 테이블에 새로운 고객 레코드가 생성됩니다.
    -   `PreferRank` 테이블에 해당 고객의 선호 등급 정보가 저장됩니다.

---

## 시나리오 2: 상품 수확 및 재고 업데이트 (트리거 `trg_update_stock_on_harvest` 테스트)

-   **설명:** 농장에서 새로운 수확을 기록하면, `trg_update_stock_on_harvest` 트리거에 의해 해당 상품의 `Item.itemStock`이 자동으로 업데이트됩니다.
-   **실행:**
    ```sql
    -- (itemId = 1 가정, farmId = 1 가정)
    -- 초기 재고 확인
    SELECT itemId, itemName, itemStock FROM Item WHERE itemId = 1;

    -- 상품 ID 1에 대한 새로운 수확 기록 (수량: 30)
    INSERT INTO HarvestLog (itemId, farmId, quantityHarvested, harvestDate) VALUES (1, 1, 30, NOW());
    ```
-   **확인:**
    ```sql
    -- 업데이트된 재고 확인
    SELECT itemId, itemName, itemStock FROM Item WHERE itemId = 1;
    ```
-   **예상 결과:**
    -   `HarvestLog`에 새로운 수확 기록이 추가됩니다.
    -   `Item` 테이블에서 `itemId = 1`인 상품의 `itemStock`이 이전 값에서 30만큼 증가합니다. (예: 초기 100 -> `dummy_data.sql` 주문으로 97 -> `dummy_data.sql` 수확으로 147 -> 이 테스트 수확으로 177)

---

## 시나리오 3: 고객 상품 주문 및 재고 차감 (트리거 `trg_decrease_stock_on_order` 테스트)

-   **설명:** 기존 고객이 특정 샤인머스캣 상품을 주문하면, `trg_decrease_stock_on_order` 트리거에 의해 해당 상품의 `Item.itemStock`이 자동으로 차감됩니다.
-   **실행:**
    ```sql
    -- (customerId = 1, itemId = 2 가정, 주문 수량 = 5)
    -- 초기 재고 확인
    SELECT itemId, itemName, itemStock FROM Item WHERE itemId = 2;

    -- 고객 ID 1이 상품 ID 2를 5개 주문
    INSERT INTO `Order` (customerId, itemId, quantity, deliveryAddress)
    VALUES (1, 2, 5, '서울시 강남구 테헤란로 123 (테스트 주소)');
    -- (생성된 orderId 확인)
    -- SELECT LAST_INSERT_ID();
    ```
-   **확인:**
    ```sql
    -- 업데이트된 재고 확인
    SELECT itemId, itemName, itemStock FROM Item WHERE itemId = 2;
    -- 주문 내역 확인
    -- SELECT * FROM `Order` WHERE orderId = LAST_INSERT_ID();
    ```
-   **예상 결과:**
    -   `Order` 테이블에 새로운 주문 레코드가 생성됩니다.
    -   `Item` 테이블에서 `itemId = 2`인 상품의 `itemStock`이 이전 값에서 5만큼 감소합니다. (예: 초기 150 -> `dummy_data.sql` 주문으로 149 -> `dummy_data.sql` 수확으로 224 -> 이 테스트 주문으로 219)
    -   `orderStatus`는 'ORDERED'로 설정됩니다.

---

## 시나리오 4: 고객 리뷰 작성 (트리거 `trg_update_avg_rating` 테스트)

-   **설명:** 고객이 주문했던 상품에 대해 리뷰를 작성합니다. 이 때, `Item` 테이블의 `averageRating`이 올바르게 업데이트되는지 확인합니다.
-   **실행:**
    ```sql
    -- (customerId = 1, itemId = 1 가정, 평점 = 4)
    -- 초기 평균 평점 확인 (선택적)
    -- SELECT itemId, itemName, averageRating FROM Item WHERE itemId = 1;

    INSERT INTO Review (customerId, itemId, rating, comment)
    VALUES (1, 1, 4, '만족합니다. 품질이 괜찮네요.');
    -- (생성된 reviewId 확인)
    ```
-   **확인:**
    ```sql
    -- Review 테이블 확인
    -- SELECT * FROM Review WHERE customerId = 1 AND itemId = 1 ORDER BY createdAt DESC LIMIT 1;
    -- Item 테이블의 averageRating 확인
    SELECT itemId, itemName, averageRating FROM Item WHERE itemId = 1;
    ```
-   **예상 결과:**
    -   `Review` 테이블에 새로운 리뷰 레코드가 생성됩니다.
    -   `trg_update_avg_rating` 트리거가 실행되어 `Item` 테이블에서 `itemId = 1`인 상품의 `averageRating`이 새 리뷰를 포함하여 다시 계산됩니다.

---

## 시나리오 5: 높은 평점 리뷰로 인한 선호 등급 자동 업데이트 (트리거 `trg_update_preferrank_on_review` 테스트)

-   **설명:** 고객이 상품에 대해 높은 평점(4점 이상)을 부여하면, `trg_update_preferrank_on_review` 트리거에 의해 해당 상품의 등급이 고객의 선호 등급(`PreferRank`)에 자동으로 (중복 방지하며) 추가됩니다.
-   **실행:**
    ```sql
    -- (customerId = 2, itemId = 3 (rank '특') 가정, rating = 5)
    -- Item ID 3의 등급 확인
    -- SELECT itemId, itemRank FROM Item WHERE itemId = 3; -- '특' 등급이어야 함

    -- 해당 고객의 해당 등급 선호도 초기 상태 확인 (선택적, 테스트 전 삭제하여 명확히 확인 가능)
    -- DELETE FROM PreferRank WHERE customerId = 2 AND itemRank = '특';

    INSERT INTO Review (customerId, itemId, rating, comment)
    VALUES (2, 3, 5, '정말 최고의 샤인머스캣! 이 등급 팬이 되었어요.');
    ```
-   **확인:**
    ```sql
    SELECT * FROM PreferRank WHERE customerId = 2 AND itemRank = '특';
    ```
-   **예상 결과:**
    -   `Review` 테이블에 새로운 리뷰가 추가됩니다.
    -   `PreferRank` 테이블에 `(customerId = 2, itemRank = '특')` 레코드가 존재하거나, 이미 존재했다면 오류 없이 넘어갑니다 (INSERT IGNORE).

---

## 시나리오 6: 고객 불량/결함 보고 (트리거 `trg_update_order_status_on_defect` 테스트)

-   **설명:** 고객이 주문한 상품에 대해 불량/결함을 보고합니다. 이 때, 해당 주문의 상태가 'REFUND_REQUESTED'로 변경되는지 확인합니다.
-   **실행:**
    ```sql
    -- (orderId = 3 (고객 3, 아이템 2), itemId = 2, customerId = 3 가정)
    -- 초기 주문 상태 확인 (선택적)
    -- SELECT orderId, orderStatus FROM `Order` WHERE orderId = 3;

    INSERT INTO DefectReport (orderId, itemId, customerId, reason, imageUrl)
    VALUES (3, 2, 3, '테스트용 불량 보고: 상품 일부 손상.', 'http://example.com/defect_test.jpg');
    -- (생성된 reportId 확인)
    ```
-   **확인:**
    ```sql
    -- DefectReport 테이블 확인 (가장 최근 reportId 또는 특정 reportId로 조회)
    -- SELECT * FROM DefectReport ORDER BY reportId DESC LIMIT 1;
    -- Order 테이블의 orderStatus 확인
    SELECT orderId, orderStatus FROM `Order` WHERE orderId = 3;
    ```
-   **예상 결과:**
    -   `DefectReport` 테이블에 새로운 불량 보고 레코드가 생성됩니다.
    -   `trg_update_order_status_on_defect` 트리거가 실행되어 `Order` 테이블에서 `orderId = 3`인 주문의 `orderStatus`가 'REFUND_REQUESTED'로 업데이트됩니다.

---

## 시나리오 7: 환불 처리 (프로시저 `proc_process_refund` 테스트)

-   **설명:** 관리자가 접수된 불량 보고에 대해 환불을 처리합니다.
-   **선행 조건:**
    -   `Order` 테이블에 `orderStatus = 'REFUND_REQUESTED'`인 주문이 존재해야 합니다 (예: 시나리오 6의 `orderId = 3` 또는 `dummy_data.sql`의 `orderId = 4`).
    -   `DefectReport` 테이블에 해당 `orderId`와 연결된 보고가 존재해야 합니다.
-   **실행:**
    ```sql
    -- (dummy_data.sql의 orderId = 4, reportId = 1 가정)
    -- 초기 상태 확인 (선택적)
    -- SELECT orderStatus FROM `Order` WHERE orderId = 4;
    -- SELECT processed, refundAmount FROM DefectReport WHERE reportId = 1;

    CALL proc_process_refund(4, 1);
    ```
-   **확인:**
    ```sql
    -- DefectReport 테이블 확인
    SELECT reportId, processed, refundAmount FROM DefectReport WHERE reportId = 1;
    -- Order 테이블의 orderStatus 확인
    SELECT orderId, orderStatus FROM `Order` WHERE orderId = 4;
    -- Item 테이블에서 해당 상품의 가격과 주문 수량 확인 (v_amount 계산 검증용)
    -- SELECT I.price, O.quantity FROM `Order` O JOIN Item I ON O.itemId = I.itemId WHERE O.orderId = 4;
    ```
-   **예상 결과:**
    -   `proc_process_refund` 프로시저가 성공적으로 실행됩니다.
    -   `DefectReport` 테이블에서 `reportId = 1`인 보고의 `processed`가 `TRUE`로, `refundAmount`가 해당 주문의 상품 가격 * 수량으로 설정됩니다.
    -   `Order` 테이블에서 `orderId = 4`인 주문의 `orderStatus`가 'REFUNDED'로 업데이트됩니다.

---

## 시나리오 8: 주문 빈도에 따른 선호 등급 자동 업데이트 (프로시저 `proc_update_preferrank_from_orders` 테스트)

-   **설명:** 특정 고객이 특정 등급의 상품을 여러 번 주문한 경우, `proc_update_preferrank_from_orders` 프로시저를 실행하여 해당 등급을 고객의 선호 등급(`PreferRank`)에 자동으로 추가합니다. (임계값: 2회 초과 주문)
-   **선행 조건 (예시 `customerId = 1`, `itemRank = '특'`):**
    -   `dummy_data.sql`에서 `customerId = 1`은 `itemId = 1`('특' 등급)을 2번 주문했습니다 (orderId 1, 6). 프로시저의 기준이 `>2`이므로, 테스트를 위해 추가 주문이 필요합니다.
    ```sql
    -- customerId = 1이 itemId = 1 ('특' 등급) 상품을 추가 주문 (세 번째 주문)
    INSERT INTO `Order` (customerId, itemId, quantity, deliveryAddress) VALUES (1, 1, 1, '추가 주문 테스트 주소');

    -- 해당 고객의 해당 등급 선호도 초기 상태 확인 (선택적, 테스트 전 삭제하여 명확히 확인 가능)
    -- DELETE FROM PreferRank WHERE customerId = 1 AND itemRank = '특';
    ```
-   **실행:**
    ```sql
    CALL proc_update_preferrank_from_orders(1); -- customerId = 1 대상
    ```
-   **확인:**
    ```sql
    SELECT * FROM PreferRank WHERE customerId = 1 AND itemRank = '특';
    ```
-   **예상 결과:**
    -   `proc_update_preferrank_from_orders` 프로시저 실행 후, `customerId = 1`에 대해 `itemRank = '특'` 레코드가 `PreferRank` 테이블에 존재하게 됩니다.

---

## 시나리오 9: 상품별 불량률 계산 (함수 `fn_get_defectRate` 테스트)

-   **설명:** 특정 상품의 전체 주문 대비 불량 보고 비율을 계산합니다.
-   **실행:**
    ```sql
    -- (itemId = 4 가정, dummy_data.sql에 의해 주문 1건, 불량보고 1건 존재)
    SELECT fn_get_defectRate(4) AS defectRate_Item4;
    ```
-   **확인:**
    -   반환된 `defectRate_Item4` 값을 확인합니다. (예상: 1.0)
    -   (선택적) 수동 계산:
        ```sql
        -- SELECT
        --     (SELECT COUNT(*) FROM DefectReport WHERE itemId = 4) /
        --     (SELECT COUNT(*) FROM `Order` WHERE itemId = 4)
        -- AS manual_defect_rate_Item4;
        ```
-   **예상 결과:**
    -   `fn_get_defectRate` 함수가 `itemId = 4`인 상품의 불량률 (0.0 ~ 1.0 사이의 값)을 반환합니다.

---

## 시나리오 10: 품질 검사 등록 (프로시저 `proc_register_inspection` 테스트)

-   **설명:** 농장 작업자가 특정 상품 및 농장에 대한 품질 검사 결과를 시스템에 등록합니다.
-   **실행:**
    ```sql
    -- (itemId = 1, farmId = 1, 검사 결과 = 'PASS', 검사자 = '박철수' 가정)
    CALL proc_register_inspection(1, 1, 'PASS', '박철수');
    -- (QualityInspection 테이블의 auto_increment로 생성된 inspectionId 확인)
    ```
-   **확인:**
    ```sql
    SELECT * FROM QualityInspection
    WHERE itemId = 1 AND farmId = 1 AND inspectorName = '박철수'
    ORDER BY inspectionDate DESC LIMIT 1;
    ```
-   **예상 결과:**
    -   `proc_register_inspection` 프로시저가 성공적으로 실행됩니다.
    -   `QualityInspection` 테이블에 새로운 품질 검사 레코드가 생성됩니다.
    -   `inspectionDate`는 프로시저 실행 시점의 `CURDATE()`로 설정됩니다.

---
