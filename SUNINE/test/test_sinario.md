# 순이네 샤인머스캣 농장: 데이터베이스 테스트 시나리오

이 문서는 "순이네 샤인머스캣 농장" 데이터베이스의 주요 기능에 대한 테스트 시나리오를 정의합니다.
각 시나리오는 설명, 실행을 위한 예제 SQL 쿼리 또는 프로시저 호출, 그리고 예상되는 결과를 포함합니다.

**참고:** 아래 예제 쿼리에 사용된 ID (예: `customerId = 1`, `itemId = 1`)는 플레이스홀더입니다. `master_setup.sql` 스크립트에 의해 실제로 삽입된 데이터에 따라 적절한 ID로 조정해야 합니다.

---

## 시나리오 1: 신규 고객 등록 및 선호 등급 설정

-   **설명:** 신규 고객이 시스템에 가입하고, 선호하는 샤인머스캣 등급을 설정합니다.
-   **실행:**
    ```sql
    -- 1. 신규 고객 등록
    INSERT INTO Customer (password, address) VALUES ('new_password123', '서울시 마포구 월드컵북로 400');
    -- (생성된 customerId 확인, 예: 6 가정)

    -- 2. 선호 등급 설정 (방금 가입한 고객 ID 사용)
    INSERT INTO PreferRank (customerId, itemRank) VALUES (6, '특');
    INSERT INTO PreferRank (customerId, itemRank) VALUES (6, '상');
    ```
-   **확인:**
    ```sql
    -- Customer 테이블 확인
    SELECT * FROM Customer WHERE customerId = 6;
    -- PreferRank 테이블 확인
    SELECT * FROM PreferRank WHERE customerId = 6;
    ```
-   **예상 결과:**
    -   `Customer` 테이블에 새로운 고객 레코드가 생성됩니다.
    -   `PreferRank` 테이블에 해당 고객의 선호 등급 정보가 저장됩니다.

---

## 시나리오 2: 고객 상품 주문

-   **설명:** 기존 고객이 특정 샤인머스캣 상품을 주문합니다.
-   **실행:**
    ```sql
    -- (customerId = 1, itemId = 2, 수량 = 1 가정)
    INSERT INTO `Order` (customerId, itemId, quantity, deliveryAddress)
    VALUES (1, 2, 1, '서울시 강남구 테헤란로 123 (기존 주소와 동일)');
    -- (생성된 orderId 확인, 예: 8 가정)
    ```
-   **확인:**
    ```sql
    SELECT * FROM `Order` WHERE orderId = 8;
    ```
-   **예상 결과:**
    -   `Order` 테이블에 새로운 주문 레코드가 생성됩니다.
    -   `orderStatus`는 기본값인 'ORDERED'로 설정됩니다.
    -   `orderDate`는 현재 시간으로 자동 설정됩니다.

---

## 시나리오 3: 고객 리뷰 작성 (트리거 `trg_update_avg_rating` 테스트)

-   **설명:** 고객이 주문했던 상품에 대해 리뷰를 작성합니다. 이 때, `Item` 테이블의 `averageRating`이 올바르게 업데이트되는지 확인합니다.
-   **실행:**
    ```sql
    -- (customerId = 1, itemId = 1 (주문 1번 상품) 가정, 평점 = 5)
    INSERT INTO Review (customerId, itemId, rating, comment)
    VALUES (1, 1, 5, '역시 믿고 먹는 햇살농장 샤인머스캣! 최고예요.');
    -- (생성된 reviewId 확인)
    ```
-   **확인:**
    ```sql
    -- Review 테이블 확인
    SELECT * FROM Review WHERE customerId = 1 AND itemId = 1 ORDER BY createdAt DESC LIMIT 1;
    -- Item 테이블의 averageRating 확인
    SELECT itemId, itemName, averageRating FROM Item WHERE itemId = 1;
    ```
-   **예상 결과:**
    -   `Review` 테이블에 새로운 리뷰 레코드가 생성됩니다.
    -   `trg_update_avg_rating` 트리거가 실행되어 `Item` 테이블에서 `itemId = 1`인 상품의 `averageRating`이 새 리뷰를 포함하여 다시 계산됩니다.

---

## 시나리오 4: 고객 불량/결함 보고 (트리거 `trg_update_order_status_on_defect` 테스트)

-   **설명:** 고객이 주문한 상품에 대해 불량/결함을 보고합니다. 이 때, 해당 주문의 상태가 'REFUND_REQUESTED'로 변경되는지 확인합니다.
-   **실행:**
    ```sql
    -- (orderId = 3 (고객 3, 아이템 2), itemId = 2, customerId = 3 가정)
    INSERT INTO DefectReport (orderId, itemId, customerId, reason, imageUrl)
    VALUES (3, 2, 3, '포장 상태 불량 및 일부 포도알 터짐.', 'http://example.com/defect_image.jpg');
    -- (생성된 reportId 확인, 예: 4 가정)
    ```
-   **확인:**
    ```sql
    -- DefectReport 테이블 확인
    SELECT * FROM DefectReport WHERE reportId = 4;
    -- Order 테이블의 orderStatus 확인
    SELECT orderId, orderStatus FROM `Order` WHERE orderId = 3;
    ```
-   **예상 결과:**
    -   `DefectReport` 테이블에 새로운 불량 보고 레코드가 생성됩니다.
    -   `trg_update_order_status_on_defect` 트리거가 실행되어 `Order` 테이블에서 `orderId = 3`인 주문의 `orderStatus`가 'REFUND_REQUESTED'로 업데이트됩니다.

---

## 시나리오 5: 환불 처리 (프로시저 `proc_process_refund` 테스트)

-   **설명:** 관리자가 접수된 불량 보고에 대해 환불을 처리합니다.
-   **선행 조건:**
    -   `Order` 테이블에 `orderStatus = 'REFUND_REQUESTED'`인 주문이 존재해야 합니다 (예: `orderId = 4`).
    -   `DefectReport` 테이블에 해당 `orderId`와 연결된 보고가 존재해야 합니다 (예: `reportId = 1`).
-   **실행:**
    ```sql
    -- (orderId = 4, reportId = 1 가정)
    CALL proc_process_refund(4, 1);
    ```
-   **확인:**
    ```sql
    -- DefectReport 테이블 확인
    SELECT reportId, processed, refundAmount FROM DefectReport WHERE reportId = 1;
    -- Order 테이블의 orderStatus 확인
    SELECT orderId, orderStatus FROM `Order` WHERE orderId = 4;
    -- Item 테이블에서 해당 상품의 가격과 주문 수량 확인 (v_amount 계산 검증용)
    SELECT I.price, O.quantity 
    FROM `Order` O JOIN Item I ON O.itemId = I.itemId 
    WHERE O.orderId = 4; 
    ```
-   **예상 결과:**
    -   `proc_process_refund` 프로시저가 성공적으로 실행됩니다.
    -   `DefectReport` 테이블에서 `reportId = 1`인 보고의 `processed`가 `TRUE`로, `refundAmount`가 해당 주문의 상품 가격 * 수량으로 설정됩니다.
    -   `Order` 테이블에서 `orderId = 4`인 주문의 `orderStatus`가 'REFUNDED'로 업데이트됩니다.

---

## 시나리오 6: 상품별 불량률 계산 (함수 `fn_get_defectRate` 테스트)

-   **설명:** 특정 상품의 전체 주문 대비 불량 보고 비율을 계산합니다.
-   **실행:**
    ```sql
    -- (itemId = 4 가정)
    SELECT fn_get_defectRate(4) AS defectRate;
    ```
-   **확인:**
    -   반환된 `defectRate` 값을 확인합니다.
    -   (선택적) 수동 계산:
        ```sql
        SELECT 
            (SELECT COUNT(*) FROM DefectReport WHERE itemId = 4) / 
            (SELECT COUNT(*) FROM `Order` WHERE itemId = 4) 
        AS manual_defect_rate;
        ```
-   **예상 결과:**
    -   `fn_get_defectRate` 함수가 `itemId = 4`인 상품의 불량률 (0.0 ~ 1.0 사이의 값)을 반환합니다.
    -   예: `itemId = 4`에 대해 주문이 1건, 불량 보고가 1건이면 1.0을 반환합니다. `dummy_data.sql` 기준으로 Item 4는 Order 4에서 1번 주문되었고, DefectReport 1번으로 보고되었습니다.

---

## 시나리오 7: 품질 검사 등록 (프로시저 `proc_register_inspection` 테스트)

-   **설명:** 농장 작업자가 특정 상품 및 농장에 대한 품질 검사 결과를 시스템에 등록합니다.
-   **실행:**
    ```sql
    -- (itemId = 1, farmId = 1, 검사 결과 = 'PASS', 검사자 = '홍길동' 가정)
    CALL proc_register_inspection(1, 1, 'PASS', '홍길동');
    -- (QualityInspection 테이블의 auto_increment로 생성된 inspectionId 확인)
    ```
-   **확인:**
    ```sql
    SELECT * FROM QualityInspection 
    WHERE itemId = 1 AND farmId = 1 AND inspectorName = '홍길동' 
    ORDER BY inspectionDate DESC LIMIT 1;
    ```
-   **예상 결과:**
    -   `proc_register_inspection` 프로시저가 성공적으로 실행됩니다.
    -   `QualityInspection` 테이블에 새로운 품질 검사 레코드가 생성됩니다.
    -   `inspectionDate`는 프로시저 실행 시점의 `CURDATE()`로 설정됩니다.

---
