---
name: semantic-model-builder
description: 분석 자산을 위한 포괄적인 의미론적 계층 문서 생성. 데이터 모델 문서화, 비즈니스 지표 정의, 데이터 사전 생성, AI 보조 분석을 위한 문맥 작성 시 사용하세요. | Create comprehensive semantic layer documentation for analytics assets. Use when documenting data models, defining business metrics, creating data dictionaries, or building context for AI-assisted analysis.
---

# 의미론적 모델 빌더(Semantic Model Builder)

## 단계(Phase)
단계 3 — 지식 축적

## 입력(Input)
- 이전 스킬: data-quality-audit + schema-mapper
- 받는 파일: `data-quality-audit_result.csv` + `schema-mapper_report.md`

## 출력(Output)
- `semantic-model-builder_report.md`

## 빠른 시작(Quick Start)

AI 보조 분석을 위해 최적화된 형식으로 비즈니스 지표, 데이터 모델, 관계를 정의하는 구조화된 문서를 구축하세요.

## 문맥 요구사항(Context Requirements)

1. **문서화할 지표/엔터티(Metric/Entity to Document)**: 뭐가 필요한가
2. **계산 로직(Calculation Logic)**: 어떻게 계산되는가 (SQL, 공식, 또는 평문)
3. **비즈니스 문맥(Business Context)**: 왜 중요한가, 어떻게 사용되는가
4. **데이터 소스(Data Sources)**: 데이터가 어디에서 오는가

## 문맥 수집(Context Gathering)

### 초기 프롬프트:
"의미론적 문서를 작성해봅시다. 무엇을 문서화하고 싶으신가요?
- 특정 지표 (예: MRR, DAU, 전환율)
- 데이터 모델/테이블 (예: 사용자 테이블, 거래)
- 비즈니스 개념 (예: '활성 고객')
- 관련된 여러 항목"

### 지표를 위해:
"[지표 이름]에 대해, 다음이 필요합니다:

1. **정의**: 이것이 평문으로 무엇인가?
   예: '월간 반복 수익(MRR)은 활성 구독에서 매월 생성된 예측 가능한 수익'

2. **계산**: 어떻게 계산되는가?
   - SQL 쿼리 제공, 또는
   - 공식 (예: 'SUM(subscription_amount) WHERE status = active'), 또는
   - 평문 단계

3. **비즈니스 문맥**:
   - 이 지표가 왜 중요한가?
   - 누가 사용하는가?
   - 어떤 의사결정을 정보 제공하는가?
   - '좋은' 값이 뭐죠?

4. **엣지 케이스** (선택이지만 도움됨):
   - 무엇을 포함/제외할 것인가?
   - 특수 상황을 어떻게 처리할 것인가?
   - 알려진 계산 주의사항?"

### 데이터 모델을 위해:
"[테이블/모델 이름]에 대해, 다음이 필요합니다:

1. **목적**: 이 테이블이 무엇을 나타내는가?
   예: '사용자 가입당 1행'

2. **주요 열**: 가장 중요한 필드
   - 어떤 ID/키인가?
   - 어떤 지표인가?
   - 어떤 속성인가?

3. **관계**: 이것이 다른 테이블과 어떻게 연결되는가?
   예: 'users.id → orders.user_id'

4. **세분도(Grain)**: 1행이 뭐죠?
   예: '거래당 1행' 또는 '사용자당 일당 1행'"

### 비즈니스 개념을 위해:
"[개념]을 이해하는 데 도움을 주세요:

1. **정의**: 이것이 뭐죠?
2. **식별 방법**: 어떻게 뭔가가 이것인지 아닌지 알 것인가?
3. **관련 데이터**: 이것이 데이터에서 어디에 캡처되는가?
4. **중요한 이유**: 비즈니스적 중요성?"

## 워크플로우(Workflow)

### 1. 정보 수집

**제공된 것으로 시작, 격차에 대해 탐색:**

사용자가 SQL을 제공할 경우:
