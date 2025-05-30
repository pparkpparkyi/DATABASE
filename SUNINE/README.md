# 🍇 순이네 샤인머스캣 농장 DB 시스템

**2025 데이터베이스설계 및 응용 프로젝트**  
**작성자**: 박서진 (20221367)

---

## 📌 프로젝트 개요

가족이 운영하는 소규모 농장인 **순이네 샤인머스캣 농장**은 주문, 리뷰, 환불 등 주요 업무를 수기로 관리해오다,  
고객 불만, 응답 지연, 불량 상품 관리 부재 등의 문제를 겪었습니다.

이에 따라 **운영 자동화 및 품질 관리 강화를 위한 통합 DB 시스템**을 설계하였습니다.

---

## 🎯 프로젝트 목표

> “농장 운영 최적화를 위한 주문/리뷰/불량 트랜잭션 기반 DB 시스템 구축”

- 수작업 업무의 **자동화 전환**
- **리뷰, 불량률, 선호도** 등 데이터 기반 품질 평가 체계 구축
- **불량 신고 → 환불 처리** 자동 트랜잭션 설계
- 품질 통계를 통해 **경영 피드백 제공**

---

## 🗂️ 핵심 기능

| 영역 | 기능 |
|------|------|
| 고객 관리 | 회원가입, 주소 및 선호 등급 등록, 리뷰 작성 |
| 주문 처리 | 상품 주문, 상태 갱신, 배송 처리 |
| 품질 관리 | 리뷰 평균 별점 자동 갱신, 불량 신고 및 환불 처리 |
| 출고 검수 | 출고 전 품질 검사 기록 관리 |
| 통계 분석 | 상품별 불량률, 평균 평점, 선호 등급 분석 |

---

## 🧩 테이블 요약 (CamelCase 적용)

| 테이블명 | 설명 |
|----------|------|
| `Customer` | 고객 정보 |
| `Item` | 상품 정보 (가격, 등급, 재배일 등) |
| `Order` | 주문 정보 및 상태 |
| `Review` | 리뷰(별점, 코멘트) 정보 |
| `PreferRank` | 고객별 선호 상품 등급 |
| `Farm` | 농장 정보 |
| `Owner` | 농장 소유자 정보 |
| `DefectReport` | 고객 불량 신고 및 환불 요청 |
| `QualityInspection` | 출고 전 품질 검사 이력 |

---

## 🧱 테이블 구조 요약

### ✅ Customer
- `customerId`, `password`, `address`

### ✅ Item
- `itemId`, `itemName`, `itemRank`, `price`, `cultivationDate`, `farmId`, `averageRating`

### ✅ Order
- `orderId`, `customerId`, `itemId`, `quantity`, `orderDate`, `deliveryAddress`, `orderStatus`

### ✅ Review
- `reviewId`, `customerId`, `itemId`, `rating`, `comment`, `createdAt`

### ✅ PreferRank
- `customerId`, `itemRank` (복합키)

### ✅ DefectReport
- `reportId`, `orderId`, `itemId`, `customerId`, `reason`, `imageUrl`, `reportedAt`, `processed`, `refundAmount`

### ✅ QualityInspection
- `inspectionId`, `itemId`, `farmId`, `inspectorName`, `inspectionDate`, `inspectionResult`, `notes`

---

## 🔁 트랜잭션 설계

| 트랜잭션 코드 | 설명 |
|---------------|------|
| T1 | 고객 주문 등록 |
| T2 | 리뷰 작성 및 저장 |
| T3 | 불량 신고 및 환불 요청 |
| T4 | 고객 회원가입 |
| T5 | 선호 등급 등록 |
| T6 | 상품 등록 |
| T7 | 리뷰 통계 조회 |
| T8 | 불량 신고 등록 자동 상태 변경 |
| T9 | 품질 검사 결과 등록 |
| T10 | 상품 불량률 및 품질 통계 분석 |

---

## 🧠 자동화 요소

### ✅ 트리거 (Trigger)

- `trg_update_order_status_on_defect`  
  → 불량 신고 시 주문 상태를 `REFUND_REQUESTED`로 자동 변경

- `trg_update_avg_rating`  
  → 리뷰가 작성되면 상품 평균 별점을 자동 갱신

---

### ✅ 프로시저 (Stored Procedure)

- `proc_process_refund(orderId)`  
  → 주문 환불 처리 및 환불 이력 등록

- `proc_register_inspection(itemId, result, inspector)`  
  → 품질 검사 결과 저장

---

### ✅ 함수 (Function)

- `fn_get_defectRate(itemId)`  
  → 특정 상품의 누적 불량률 계산

---

## 📊 품질 분석 활용

- **불량률 높은 상품 탐지** → 재배/배송 문제 추적
- **별점 낮은 상품 자동 필터링**
- **고객 선호 등급 기반 추천 기능 구현 가능**
- **검수 없는 출고 상품 탐지** → 예방적 품질 관리

---

## 📁 디렉토리 구조 예시

```bash
project-root/
│
├─ schema/             # DDL, 테이블 생성 스크립트
│   └─ create_tables.sql
│
├─ triggers_procs/     # 트리거, 프로시저, 함수
│   ├─ triggers.sql
│   ├─ procedures.sql
│   └─ functions.sql
│
├─ docs/               # 문서 및 발표 자료
│   └─ 중간발표_20221367_박서진.pdf
│
└─ README.md           # 프로젝트 개요 설명 파일
