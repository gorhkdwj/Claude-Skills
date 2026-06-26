---
name: sql-to-business-logic
description: SQL 쿼리를 평문 비즈니스 로직으로 변환합니다. 쿼리 문서화, 비기술 이해관계자에게 분석 설명, 코드 리뷰, 사용자 친화적 쿼리 설명 생성 시 사용하세요. | Translate SQL queries into plain language business logic. Use when documenting queries, explaining analysis to non-technical stakeholders, code review, or creating user-friendly query descriptions.
---

# SQL에서 비즈니스 로직으로의 변환기(SQL to Business Logic Translator)

## 단계(Phase)
단계 3 — 지식 축적

## 입력(Input)
- 이전 스킬: data-quality-audit + schema-mapper
- 받는 파일: `data-quality-audit_result.csv` + `schema-mapper_report.md`

## 출력(Output)
- `sql-to-business-logic_report.md`

## 빠른 시작(Quick Start)

복잡한 SQL 쿼리를 비기술 이해관계자들이 이해하고 검증할 수 있는 명확한 평문 설명으로 변환하세요.

## 문맥 요구사항(Context Requirements)

SQL을 변환하기 전에 필요한 것:

1. **SQL 쿼리(SQL Query)**: 변환할 쿼리
2. **문맥(Context)**: 어떤 비즈니스 질문에 답하는가
3. **대상(Audience)**: 누가 이를 이해해야 하는가
4. **스키마 정보(Schema Info)**: 테이블/열 비즈니스 의미
5. **출력 형식(Output Format)**: 서술, 항목, 또는 순서도

## 문맥 수집(Context Gathering)

### SQL 쿼리를 위해:
"변환하고 싶은 SQL 쿼리를 공유하세요:

```sql
SELECT
  DATE_TRUNC('month', order_date) as month,
  COUNT(DISTINCT customer_id) as customers,
  SUM(total_amount) as revenue
FROM orders
WHERE status = 'completed'
  AND order_date >= '2024-01-01'
GROUP BY 1
ORDER BY 1 DESC
```

평문으로 무엇을 하는지 설명하겠습니다."

### 문맥을 위해:
"이 쿼리가 답하는 비즈니스 질문이 뭐죠?

**예:**
- '경영진 대시보드를 위한 월간 수익 추세'
- '가격 분석을 위한 제품별 고객 수'
- '유지팀을 위한 이탈율 계산'

이것이 변환을 적절하게 프레임하는 데 도움이 됩니다."

### 대상을 위해:
"이 쿼리를 누가 이해해야 하나요?

**기술 대상** (분석가, 엔지니어):
- 로직에 더 자세함
- 엣지 케이스 설명
- 성능 고려사항 언급

**비즈니스 대상** (이해관계자, 경영진):
- 비즈니스 의미에 초점
- 기술 전문 용어 피함
- 비즈니스 규칙 강조

**혼합 대상**:
- 비즈니스 설명으로 시작
- 기술 부록 추가"

### 스키마를 위해:
"테이블/열 설명이 있나요?

**도움이 되는 정보:**
- 테이블 비즈니스 이름 (orders = '고객 주문')
- 주요 열이 나타내는 것
- 일반적인 상태 값
- 중요한 비즈니스 규칙

예:
- `status = 'completed'`는 '결제 완료 및 이행됨'을 의미
- `total_amount`는 세금과 배송 포함
- `order_date`는 배송되지 않은 배치된 시간"

### 출력 형식을 위해:
"변환을 어떻게 제시할까요?

**서술** (단락):
'이 쿼리는 월간 수익을 계산함으로써...'

**항목** (구조화됨):
• 단계 1: 완료된 주문으로 필터
• 단계 2: 월별로 그룹화
• 단계 3: 합계 계산

**순서도** (시각적):
데이터 → 필터 → 그룹화 → 집계 → 정렬

어떤 것이 당신의 사용 사례에 가장 잘 작동할까요?"

## 워크플로우(Workflow)

### 단계 1: SQL 구조 파싱

```python
import sqlparse
from sqlparse.sql import IdentifierList, Identifier, Where, Comparison
from sqlparse.tokens import Keyword, DML

def parse_sql_structure(sql_query):
    """
    SQL 쿼리의 주요 구성 요소 추출
    """

    parsed = sqlparse.parse(sql_query)[0]

    structure = {
        'type': None,
        'tables': [],
        'columns': [],
        'where_conditions': [],
        'group_by': [],
        'order_by': [],
        'having': [],
        'joins': []
    }

    # 쿼리 유형 식별
    for token in parsed.tokens:
        if token.ttype is DML:
            structure['type'] = token.value.upper()

    # 구성 요소 추출 (단순화됨)
    sql_upper = sql_query.upper()

    # 테이블
    if 'FROM' in sql_upper:
        from_part = sql_query.split('FROM')[1].split('WHERE')[0] if 'WHERE' in sql_upper else sql_query.split('FROM')[1]
        from_part = from_part.split('GROUP BY')[0] if 'GROUP BY' in sql_upper else from_part
        structure['tables'] = [t.strip() for t in from_part.split('JOIN') if t.strip()]

    # WHERE 조건
    if 'WHERE' in sql_upper:
        where_part = sql_query.split('WHERE')[1].split('GROUP BY')[0] if 'GROUP BY' in sql_upper else sql_query.split('WHERE')[1]
        where_part = where_part.split('ORDER BY')[0] if 'ORDER BY' in sql_upper else where_part
        structure['where_conditions'] = [c.strip() for c in where_part.split('AND') if c.strip()]

    # GROUP BY
    if 'GROUP BY' in sql_upper:
        group_part = sql_query.split('GROUP BY')[1].split('ORDER BY')[0] if 'ORDER BY' in sql_upper else sql_query.split('GROUP BY')[1]
        structure['group_by'] = [g.strip() for g in group_part.split(',')]

    return structure

# 예시
sql = """
SELECT
  DATE_TRUNC('month', order_date) as month,
  COUNT(DISTINCT customer_id) as customers,
  SUM(total_amount) as revenue
FROM orders
WHERE status = 'completed'
  AND order_date >= '2024-01-01'
GROUP BY 1
ORDER BY 1 DESC
"""

structure = parse_sql_structure(sql)
print("✅ SQL 파싱됨")
print(f"   유형: {structure['type']}")
print(f"   테이블: {structure['tables']}")
print(f"   필터: {len(structure['where_conditions'])}")
```

### 단계 2: SELECT 절 변환

```python
def translate_select(select_clause, schema_info=None):
    """
    SELECT를 비즈니스 언어로 변환
    """

    translations = []

    # 일반적인 집계
    agg_patterns = {
        'COUNT(DISTINCT': '고유 수 세기',
        'COUNT(': '총 수 세기',
        'SUM(': '합계',
        'AVG(': '평균',
        'MAX(': '최대',
        'MIN(': '최소',
        'DATE_TRUNC': '다음으로 그룹화'
    }

    # select 절 분할
    for item in select_clause.split(','):
        item = item.strip()

        translation = item

        # 패턴 적용
        for pattern, replacement in agg_patterns.items():
            if pattern in item:
                translation = replacement + ' ' + item.split(pattern)[1].split(')')[0]

                # 별칭 처리
                if ' as ' in item.lower():
                    alias = item.split(' as ')[1].strip()
                    translation = f"{translation} (''{alias}''라고 불림)"

                break

        # 사용 가능하면 비즈니스 문맥 추가
        if schema_info:
            for col, meaning in schema_info.items():
                if col in item:
                    translation = translation.replace(col, meaning)

        translations.append(translation)

    return translations

# 예시
schema_info = {
    'customer_id': '고객',
    'order_date': '주문 배치 날짜',
    'total_amount': '주문 가치'
}

selects = translate_select(
    "DATE_TRUNC('month', order_date) as month, COUNT(DISTINCT customer_id) as customers, SUM(total_amount) as revenue",
    schema_info
)

print("\n📊 SELECT는 다음으로 변환됨:")
for s in selects:
    print(f"   • {s}")
```

### 단계 3: WHERE 절 변환

```python
def translate_where(where_conditions, schema_info=None):
    """
    WHERE 필터를 비즈니스 규칙으로 변환
    """

    translations = []

    operators = {
        '=': '같음',
        '!=': '같지 않음',
        '<>': '같지 않음',
        '>': '보다 큼',
        '<': '보다 작음',
        '>=': '이상',
        '<=': '이하',
        'LIKE': '패턴과 일치',
        'IN': '다음 중 하나',
        'BETWEEN': '다음 사이',
        'IS NULL': '비어있음',
        'IS NOT NULL': '비어있지 않음'
    }

    for condition in where_conditions:
        condition = condition.strip()

        # 연산자 찾기
        translation = condition
        for op, meaning in operators.items():
            if op in condition:
                parts = condition.split(op)
                field = parts[0].strip()
                value = parts[1].strip() if len(parts) > 1 else ''

                # 따옴표 제거
                value = value.replace("'", "")

                # 비즈니스 문맥 추가
                if schema_info and field in schema_info:
                    field = schema_info[field]

                translation = f"{field} {meaning} {value}"
                break

        translations.append(translation)

    return translations

where_translates = translate_where(
    ["status = 'completed'", "order_date >= '2024-01-01'"],
    schema_info={'status': '주문 상태', 'order_date': '주문 날짜'}
)

print("\n🔍 WHERE는 다음으로 변환됨:")
for w in where_translates:
    print(f"   • {w}")
```

### 단계 4: GROUP BY & 집계 변환

```python
def translate_grouping(group_by_cols, schema_info=None):
    """
    그룹화 로직 설명
    """

    if not group_by_cols:
        return None

    translations = []

    for col in group_by_cols:
        col = col.strip()

        # 숫자 참조 처리 (GROUP BY 1)
        if col.isdigit():
            translations.append(f"SELECT의 {col}번째 열")
        else:
            col_name = col
            if schema_info and col in schema_info:
                col_name = schema_info[col]
            translations.append(col_name)

    if len(translations) == 1:
        return f"각 {translations[0]}에 대해 별도로 계산"
    else:
        return f"각 {', '.join(translations)} 조합에 대해 별도로 계산"

group_translate = translate_grouping(['1'], {})
print(f"\n📦 GROUP BY는 다음으로 변환됨:")
print(f"   {group_translate}")
```

### 단계 5: 비즈니스 로직 서술 생성

```python
def generate_business_narrative(sql, schema_info, business_context):
    """
    완전한 평문 설명 생성
    """

    structure = parse_sql_structure(sql)

    narrative = []

    # 시작
    if business_context:
        narrative.append(f"**목적:** {business_context}\n")

    narrative.append("**작동 방식:**\n")

    # 단계 1: 데이터 소스
    tables = structure['tables'][0] if structure['tables'] else 'unknown'
    table_name = schema_info.get('tables', {}).get(tables, tables)
    narrative.append(f"1. **시작:** {table_name}")

    # 단계 2: 필터
    if structure['where_conditions']:
        narrative.append(f"\n2. **다음으로 필터:")
        for condition in translate_where(structure['where_conditions'], schema_info.get('columns', {})):
            narrative.append(f"   • {condition}")

    # 단계 3: 그룹화
    if structure['group_by']:
        group_explain = translate_grouping(structure['group_by'], schema_info.get('columns', {}))
        narrative.append(f"\n3. **계산:** {group_explain}")

    # 단계 4: 지표
    narrative.append(f"\n4. **표시:**")
    # SELECT 변환을 여기에 추출
    narrative.append(f"   • 고유 고객 수")
    narrative.append(f"   • 총 수익")
    narrative.append(f"   • 월별로 그룹화됨")

    # 단계 5: 정렬
    if 'ORDER BY' in sql.upper():
        narrative.append(f"\n5. **정렬:** 월별 (가장 최근 먼저)")

    # 결과
    narrative.append(f"\n**결과:** 2024년 완료된 주문에 대한 월간 고객 수 및 수익")

    return "\n".join(narrative)

business_context = "성능 모니터링을 위한 월간 수익 및 고객 성장 추적"
schema = {
    'tables': {'orders': '고객 주문 테이블'},
    'columns': {
        'order_date': '주문이 배치된 날짜',
        'status': '주문 상태',
        'customer_id': '고객',
        'total_amount': '주문 가치'
    }
}

narrative = generate_business_narrative(sql, schema, business_context)
print("\n" + "="*60)
print("비즈니스 로직 설명")
print("="*60)
print(narrative)
```

### 단계 6: 항목 요약 생성

```python
def generate_bullet_summary(sql, schema_info):
    """
    간결한 항목 설명 생성
    """

    summary = "## 쿼리 요약\n\n"

    # 뭐
    summary += "**이 쿼리가 하는 것:**\n"
    summary += "• 월간 수익 및 고객 수 계산\n"
    summary += "• 완료된 주문만\n"
    summary += "• 2024년 1월 이후\n\n"

    # 데이터
    summary += "**사용된 데이터:**\n"
    summary += "• 소스: 고객 주문 테이블\n"
    summary += "• 시간 기간: 2024년 이후\n"
    summary += "• 상태: 완료된 주문만\n\n"

    # 출력
    summary += "**출력 열:**\n"
    summary += "• month: 연도의 월\n"
    summary += "• customers: 그 달의 고유 고객 수\n"
    summary += "• revenue: 모든 주문의 총 가치\n\n"

    # 비즈니스 규칙
    summary += "**적용된 비즈니스 규칙:**\n"
    summary += "• 각 고객이 월별로 한 번만 계산됨\n"
    summary += "• 수익에 세금 및 배송 포함\n"
    summary += "• '완료된' 주문만 (결제 및 이행됨)\n"

    return summary

bullet_summary = generate_bullet_summary(sql, schema)
print("\n" + bullet_summary)
```

### 단계 7: 시각적 순서도 생성

```python
def generate_flowchart_ascii(sql):
    """
    ASCII 순서도 표현 생성
    """

    flowchart = """
    ┌─────────────────────────┐
    │  고객 주문 테이블       │
    └───────────┬─────────────┘
                │
                ▼
    ┌─────────────────────────┐
    │   필터 조건:            │
    │  • status = 'completed' │
    │  • order_date >= 2024   │
    └───────────┬─────────────┘
                │
                ▼
    ┌─────────────────────────┐
    │    월별로 그룹화        │
    └───────────┬─────────────┘
                │
                ▼
    ┌─────────────────────────┐
    │  월별로 계산:           │
    │  • 고유 고객            │
    │  • 총 수익              │
    └───────────┬─────────────┘
                │
                ▼
    ┌─────────────────────────┐
    │  월별로 정렬 (내림차순) │
    └───────────┬─────────────┘
                │
                ▼
    ┌─────────────────────────┐
    │    최종 결과            │
    │  month | customers | $  │
    └─────────────────────────┘
    """

    return flowchart

flowchart = generate_flowchart_ascii(sql)
print("\n📊 쿼리 흐름:")
print(flowchart)
```

### 단계 8: 검증 질문 추가

```python
def generate_validation_questions(sql, business_context):
    """
    쿼리가 의도와 일치하는지 검증하는 질문
    """

    questions = [
        "❓ '완료된' 주문만 포함해야 하나요, 아니면 '배송됨'도?",
        "❓ 2024가 올바른 시작 날짜인가요, 아니면 모든 역사적 데이터를 원하시나요?",
        "❓ 수익이 세금과 배송을 포함해야 하나요, 아니면 제품 가치만?",
        "❓ 각 고객이 월별로 한 번 계산되나요, 아니면 반복 주문을 계산하나요?",
        "❓ 취소된 주문을 제외해야 하나요?"
    ]

    print("\n🔍 검증 질문:")
    print("\n이 쿼리가 당신의 의도와 일치하는지 확인하려면:\n")
    for q in questions:
        print(q)

    print("\n검토하고 조정이 필요한 로직이 있는지 알려주세요.")

generate_validation_questions(sql, business_context)
```

## 문맥 검증

변환 공유 전에 확인:
- [ ] SQL 쿼리가 완전하고 구문이 올바름
- [ ] 비즈니스 문맥이 명확
- [ ] 테이블/열 의미 문서화됨
- [ ] 대상 수준이 적절
- [ ] 주요 비즈니스 규칙이 설명됨
- [ ] 엣지 케이스가 다루어짐

## 출력 템플릿

```
# SQL 쿼리 변환

## 비즈니스 목적

성능 모니터링을 위해 월간 수익 및 고객 성장을 추적합니다.

## 이 쿼리가 하는 것

이 쿼리는 2024년 각 월에 대해 두 가지 주요 지표를 계산합니다:
1. 주문을 배치한 고유 고객 수
2. 생성된 총 수익

완료된 (결제 및 이행된) 주문만 포함합니다.

## 단계별 로직

**단계 1: 고객 주문으로 시작**
- 테이블: orders (완전한 주문 이력)

**단계 2: 필터 적용**
두 조건을 충족하는 주문만 포함:
- 주문 상태가 '완료됨' (결제 및 이행됨)
- 주문 날짜가 2024년 1월 1일 이후

**단계 3: 월별로 그룹화**
각 달력월에 대해 별도로 지표 계산

**단계 4: 지표 계산**
각 월에 대해:
- 고유 고객 수 계산 (각 고객은 한 번만 계산)
- 모든 주문 값의 합계 (세금 및 배송 포함)

**단계 5: 결과 정렬**
가장 최근 월을 먼저 표시

## 출력 형식

| 열 | 설명 |
|--------|-------------|
| month | 달력 월 (YYYY-MM 형식) |
| customers | 그 달의 고유 고객 수 |
| revenue | 그 달의 모든 주문의 총 $ 가치 |

## 비즈니스 규칙

✓ 각 고객이 월별로 한 번 계산됨 (반복 주문은 수를 늘리지 않음)
✓ 수익에 세금과 배송 포함
✓ 완료된 주문만 (보류 중, 취소됨, 환불 제외)
✓ 주문 날짜는 배송된 시간이 아닌 배치된 시간

## 검증 질문

당신의 의도와 일치하는지 확인하려면:

1. '완료된' 주문만 계산해야 하나요?
2. 2024가 올바른 시작 날짜인가요?
3. 수익이 세금/배송을 포함해야 하나요?
4. 다른 주문 상태를 포함/제외할 건가요?

## 기술 참고사항

**성능:** 쿼리는 (status, order_date)의 인덱스를 사용하여 효율성을 위해

**처리된 엣지 케이스:**
- NULL customer_id가 있는 주문 제외 (있으면 안 됨)
- 시간대: 모든 날짜가 UTC
- NULL을 가진 이동 제외

**새로고침 빈도:** 실시간 (orders 테이블이 지속적으로 업데이트됨)
```

## 일반적인 시나리오

### 시나리오 1: "이 쿼리를 관리자에게 설명"
→ 비즈니스 서술 생성
→ 뭐와 왜에 초점
→ 기술 전문 용어 피함
→ 검증 질문 포함
→ 비즈니스 영향 강조

### 시나리오 2: "향후 분석가를 위해 이 쿼리 문서화"
→ 기술 + 비즈니스 설명
→ 가정 문서화
→ 엣지 케이스 설명
→ 성능 참고사항 추가
→ 수정 예시 포함

### 시나리오 3: "실행 전에 쿼리 로직 검증"
→ 단계별 분석 생성
→ 검증 체크리스트 생성
→ 잠재적 문제 식별
→ 테스트 케이스 제안
→ 이해관계자 서명 획득

### 시나리오 4: "사용자 친화적 쿼리 카탈로그 생성"
→ 모든 일반 쿼리 변환
→ 형식 표준화
→ 검색 태그 추가
→ 사용 사례 예시 포함
→ 셀프 서비스 만들기

### 시나리오 5: "코드 검토 - 이 쿼리가 맞는가?"
→ 비즈니스 로직으로 변환
→ 요구사항과 비교
→ 불일치 표시
→ 수정 제안
→ 가정 문서화

## 누락된 문맥 처리

**사용자가 SQL만 제공:**
"기술 단계를 변환할 수 있지만, 유용하게 만들려면 비즈니스 문맥이 필요합니다:
- 어떤 질문에 답하려는 건가요?
- 누가 이 설명을 사용할 건가요?
- 중요한 비즈니스 규칙이 있나요?

5분의 문맥이 변환을 10배 더 좋게 만듭니다."

**복잡한 중첩 쿼리:**
"이 쿼리에 여러 계층이 있습니다. 다음을 설명하겠습니다:
1. 내부 쿼리 먼저 (무엇을 하는가)
2. 외부 쿼리 (어떻게 내부 결과를 사용하는가)
3. 전체 비즈니스 로직

SQL도 단순화해야 하나요?"

**사용자가 쿼리가 맞는지 불확실:**
"함께 변환하고 검증해봅시다:
1. 무엇을 하는지 설명하겠습니다
2. 무엇을 해야 하는지 말씀해주세요
3. 불일치를 찾겠습니다

종종 비즈니스 로직을 보면 문제가 드러납니다."

**스키마 정보 사용 불가:**
"기술 이름을 사용하여 변환하겠습니다. 매핑에 도움을 줄 수 있나요:
- 'orders' 테이블이 뭘 나타내나요?
- 'status' 필드가 뭐죠?
- '완료됨'이 뭐를 의미하나요?

그러면 비즈니스 용어로 재생성하겠습니다."

## 고급 옵션

기본 변환 후 제공:

**SQL 최적화 검토**:
"쿼리가 더 빠를 수 있는지 확인할 수 있습니다 - 인덱스 사용, 재쓰기 패턴을 제안합니다."

**데이터 품질 검사**:
"검증 추가: 실행 전에 NULL, 중복, 예상 범위를 확인합니다."

**쿼리 비교**:
"이전 버전이 있으면, 버전 간 변경 사항을 보여드립니다."

**테스트 케이스 생성**:
"쿼리가 예상대로 작동하는지 검증할 샘플 입력/출력을 생성합니다."

**자동 문서화**:
"카탈로그의 모든 저장된 쿼리에 대해 자동 변환을 설정합니다."

**대화형 설명기**:
"마우스를 가져가면 설명이 표시되는 클릭 가능한 쿼리를 생성합니다."
