---
name: query-validation
description: SQL 쿼리 검토 및 정확성, 성능 및 모범 사례에 대한 검증. 쿼리를 논리적 오류, 성능 최적화, SQL 안티패턴 확인, 비즈니스 로직 구현 검증 목적으로 검토할 때 사용하세요. | SQL query review and validation for correctness, performance, and best practices. Use when reviewing queries for logical errors, optimizing query performance, checking for SQL anti-patterns, or validating business logic implementation in SQL.
---

# SQL 쿼리 검증 스킬

SQL 쿼리의 논리적 정확성, 성능, 모범 사례 준수 여부를 체계적으로 검토합니다.
AI가 안티패턴·잠재적 오류를 탐지하고, 사용자가 비즈니스 로직 맥락에서 최종 확인합니다.

## Phase
Phase 2 — 데이터 이해 (programmatic-eda 또는 schema-mapper 이후)

## Input
- 이전 스킬: data-quality-audit 또는 schema-mapper (선택)
- 받는 파일: `data-quality-audit_report.md` (선택) + 검증할 SQL 쿼리

## Output
- `query-validation.ipynb` — 쿼리 실행 및 검증 테스트 코드
- `query-validation_result.csv` — 검증 항목별 결과 (통과/경고/오류)
- `query-validation_report.md` — 발견사항 및 개선 권장사항

---

## 빠른 시작

SQL 쿼리의 정확성, 성능 및 모범 사례 준수 여부를 검토합니다.
데이터베이스에 직접 접근하지 않아도 정적 분석으로 대부분의 문제를 탐지할 수 있습니다.

---

## 필요한 컨텍스트

1. **SQL 쿼리**: 검증할 쿼리 (붙여넣기 또는 파일)
2. **데이터베이스 유형**: PostgreSQL, MySQL, Snowflake, BigQuery, Redshift 등
3. **스키마 정보**: 관련 테이블 구조 (컬럼명, 타입, PK/FK)
4. **비즈니스 로직** (선택): 쿼리가 계산해야 할 것
5. **성능 컨텍스트** (선택): 예상 행 수, 현재 실행 시간

---

## 컨텍스트 수집

### 쿼리 입력의 경우:
"다음을 제공해주세요:
1. 검증할 SQL 쿼리
2. 사용 중인 데이터베이스 시스템 (PostgreSQL, Snowflake 등)
3. 관련 테이블 스키마 (또는 추출을 도와드릴 수 있습니다)"

### 스키마의 경우:
"조인 및 컬럼 참조를 검증하려면 테이블 스키마가 필요합니다. 다음 중 편한 방법으로 제공해주세요:

**옵션 1 — 간단하게:**
쿼리에서 사용되는 테이블명과 컬럼명만 알려주세요.

**옵션 2 — 상세하게:**
```sql
-- 예시 형식
CREATE TABLE orders (
    order_id BIGINT PRIMARY KEY,
    user_id  BIGINT,
    amount   NUMERIC(10, 2),
    created_at TIMESTAMP
);
```

**옵션 3 — 자동 추출:**
데이터베이스에 접근 가능하다면 아래 쿼리로 스키마를 추출해주세요:
```sql
-- PostgreSQL / Redshift
SELECT column_name, data_type, is_nullable
FROM information_schema.columns
WHERE table_name IN ('테이블명1', '테이블명2')
ORDER BY table_name, ordinal_position;
```"

---

## 워크플로우

### 1단계: 쿼리 파싱 및 구조 분석

```python
import re
import pandas as pd

def parse_query_structure(sql: str) -> dict:
    """SQL 쿼리의 구조적 특성을 분석합니다."""
    sql_upper = sql.upper()

    structure = {
        'query_type': None,
        'has_join': False,
        'join_types': [],
        'has_subquery': False,
        'has_cte': False,
        'has_window_function': False,
        'has_group_by': False,
        'has_having': False,
        'has_order_by': False,
        'has_limit': False,
        'has_distinct': False,
        'has_union': False,
        'table_aliases': {},
        'estimated_complexity': None
    }

    # 쿼리 유형
    for qt in ['SELECT', 'INSERT', 'UPDATE', 'DELETE', 'CREATE', 'WITH']:
        if sql_upper.lstrip().startswith(qt):
            structure['query_type'] = qt
            break

    # 주요 절 탐지
    structure['has_join'] = bool(re.search(r'\bJOIN\b', sql_upper))
    structure['join_types'] = re.findall(r'\b(INNER|LEFT|RIGHT|FULL OUTER|CROSS)\s+JOIN\b', sql_upper)
    structure['has_subquery'] = sql_upper.count('SELECT') > 1
    structure['has_cte'] = sql_upper.lstrip().startswith('WITH')
    structure['has_window_function'] = bool(re.search(r'\bOVER\s*\(', sql_upper))
    structure['has_group_by'] = bool(re.search(r'\bGROUP\s+BY\b', sql_upper))
    structure['has_having'] = bool(re.search(r'\bHAVING\b', sql_upper))
    structure['has_order_by'] = bool(re.search(r'\bORDER\s+BY\b', sql_upper))
    structure['has_limit'] = bool(re.search(r'\b(LIMIT|TOP|FETCH\s+FIRST)\b', sql_upper))
    structure['has_distinct'] = bool(re.search(r'\bSELECT\s+DISTINCT\b', sql_upper))
    structure['has_union'] = bool(re.search(r'\bUNION\b', sql_upper))

    # 복잡도 추정
    complexity_score = (
        sql_upper.count('JOIN') * 2 +
        (sql_upper.count('SELECT') - 1) * 3 +  # 서브쿼리
        int(structure['has_window_function']) * 2 +
        int(structure['has_cte']) +
        int(structure['has_union'])
    )
    if complexity_score <= 2:
        structure['estimated_complexity'] = '단순'
    elif complexity_score <= 6:
        structure['estimated_complexity'] = '중간'
    else:
        structure['estimated_complexity'] = '복잡'

    return structure

# 사용 예시
sql_query = """
-- 여기에 검증할 쿼리를 붙여넣으세요
SELECT
    u.user_id,
    u.name,
    COUNT(o.order_id) AS order_count,
    SUM(o.amount)     AS total_amount
FROM users u
LEFT JOIN orders o ON u.user_id = o.user_id
WHERE o.created_at >= '2024-01-01'
GROUP BY u.user_id, u.name
HAVING SUM(o.amount) > 100000
ORDER BY total_amount DESC
LIMIT 100;
"""

structure = parse_query_structure(sql_query)
print("=== 쿼리 구조 분석 ===")
for k, v in structure.items():
    if v and v != [] and v != {}:
        print(f"  {k}: {v}")
```

---

### 2단계: 안티패턴 및 논리 오류 탐지

```python
def detect_antipatterns(sql: str, db_type: str = 'postgresql') -> list:
    """
    SQL 안티패턴과 잠재적 논리 오류를 탐지합니다.
    각 항목: {'severity': 'error'|'warning'|'info', 'category': str, 'message': str, 'line': int|None}
    """
    sql_upper = sql.upper()
    findings = []

    # ── 오류 수준 (Error) ────────────────────────────────────────
    # SELECT * 사용
    if re.search(r'SELECT\s+\*', sql_upper):
        findings.append({
            'severity': 'warning',
            'category': '컬럼 선택',
            'message': 'SELECT * 사용 — 필요한 컬럼만 명시하면 성능 향상 및 스키마 변경 영향 최소화',
            'suggestion': '필요한 컬럼명을 명시적으로 나열하세요'
        })

    # WHERE 절 없는 UPDATE/DELETE
    if re.search(r'\b(UPDATE|DELETE)\b', sql_upper) and not re.search(r'\bWHERE\b', sql_upper):
        findings.append({
            'severity': 'error',
            'category': '데이터 안전',
            'message': 'WHERE 절 없는 UPDATE/DELETE — 전체 테이블에 적용될 위험',
            'suggestion': '반드시 WHERE 조건을 추가하고, 먼저 SELECT로 대상 행을 확인하세요'
        })

    # HAVING without GROUP BY
    if re.search(r'\bHAVING\b', sql_upper) and not re.search(r'\bGROUP\s+BY\b', sql_upper):
        findings.append({
            'severity': 'error',
            'category': '논리 오류',
            'message': 'HAVING이 GROUP BY 없이 사용됨 — 의도한 동작이 아닐 수 있음',
            'suggestion': 'GROUP BY를 추가하거나 HAVING을 WHERE로 변경하세요'
        })

    # ── 경고 수준 (Warning) ──────────────────────────────────────
    # 암묵적 CROSS JOIN (쉼표 조인)
    if re.search(r'FROM\s+\w+\s*,\s*\w+', sql_upper):
        findings.append({
            'severity': 'warning',
            'category': '조인 스타일',
            'message': '암묵적 CROSS JOIN (FROM a, b) 감지 — 명시적 JOIN 문법 권장',
            'suggestion': 'FROM a, b WHERE a.id = b.id 대신 FROM a JOIN b ON a.id = b.id 사용'
        })

    # NOT IN with NULL 위험
    if re.search(r'\bNOT\s+IN\b', sql_upper):
        findings.append({
            'severity': 'warning',
            'category': 'NULL 처리',
            'message': 'NOT IN 사용 — 서브쿼리 결과에 NULL이 포함되면 전체 결과가 빈 집합이 됨',
            'suggestion': 'NOT EXISTS 또는 LEFT JOIN + IS NULL 패턴으로 변경 권장'
        })

    # OR 조건의 인덱스 무력화
    if re.search(r'\bWHERE\b.*\bOR\b', sql_upper):
        findings.append({
            'severity': 'info',
            'category': '성능',
            'message': 'WHERE 절의 OR 조건 — 인덱스를 활용하지 못할 수 있음',
            'suggestion': 'UNION ALL로 분리하거나 인덱스 설계를 확인하세요'
        })

    # LIKE 앞 와일드카드
    if re.search(r"LIKE\s+'%\w", sql_upper):
        findings.append({
            'severity': 'warning',
            'category': '성능',
            'message': "LIKE '%...' 앞 와일드카드 — 인덱스 풀스캔 발생",
            'suggestion': '전문 검색(Full-Text Search)이나 역색인 방식 검토'
        })

    # 함수 적용된 WHERE 컬럼 (인덱스 무력화)
    if re.search(r'WHERE\s+\w+\s*\(', sql_upper):
        findings.append({
            'severity': 'warning',
            'category': '성능',
            'message': 'WHERE 절에서 컬럼에 함수 적용 — 인덱스 사용 불가',
            'suggestion': '함수를 반대편(상수 측)에 적용하거나 인덱스 기반 컬럼을 직접 비교하세요'
        })

    # ── 정보 수준 (Info) ────────────────────────────────────────
    # DISTINCT 사용
    if re.search(r'\bSELECT\s+DISTINCT\b', sql_upper):
        findings.append({
            'severity': 'info',
            'category': '설계 검토',
            'message': 'DISTINCT 사용 — 중복이 발생하는 근본 원인(조인 조건, 그룹핑)을 확인 권장',
            'suggestion': '중복이 왜 발생하는지 파악 후 조인 조건 또는 집계 방식 수정 검토'
        })

    # LIMIT 없는 대용량 SELECT
    if (structure.get('query_type') == 'SELECT'
            and not re.search(r'\b(LIMIT|TOP|FETCH\s+FIRST)\b', sql_upper)
            and re.search(r'\bJOIN\b', sql_upper)):
        findings.append({
            'severity': 'info',
            'category': '성능',
            'message': 'LIMIT 없는 JOIN 쿼리 — 대용량 테이블에서 전체 결과를 반환할 수 있음',
            'suggestion': '개발/검증 단계에서는 LIMIT을 추가하여 먼저 샘플 확인'
        })

    return findings

findings = detect_antipatterns(sql_query, db_type='postgresql')

print("=== 안티패턴 탐지 결과 ===")
errors   = [f for f in findings if f['severity'] == 'error']
warnings = [f for f in findings if f['severity'] == 'warning']
infos    = [f for f in findings if f['severity'] == 'info']

print(f"\n🔴 오류 ({len(errors)}건)")
for f in errors:
    print(f"  [{f['category']}] {f['message']}")
    print(f"    → {f['suggestion']}")

print(f"\n🟡 경고 ({len(warnings)}건)")
for f in warnings:
    print(f"  [{f['category']}] {f['message']}")
    print(f"    → {f['suggestion']}")

print(f"\n🔵 참고 ({len(infos)}건)")
for f in infos:
    print(f"  [{f['category']}] {f['message']}")
    print(f"    → {f['suggestion']}")
```

---

### 3단계: 비즈니스 로직 검증 체크리스트

```python
def business_logic_checklist(sql: str, business_intent: str = "") -> list:
    """
    비즈니스 로직 관점에서 확인해야 할 항목을 생성합니다.
    사용자가 직접 체크하는 수동 검증 목록입니다.
    """
    sql_upper = sql.upper()
    checklist = []

    # 집계 관련
    if re.search(r'\b(SUM|AVG|COUNT|MAX|MIN)\b', sql_upper):
        checklist.append({
            'item': 'NULL이 집계 함수에 미치는 영향 확인',
            'detail': 'SUM(NULL)=NULL, AVG는 NULL 제외, COUNT(*)와 COUNT(col) 차이 확인',
            'checked': None  # True/False/None
        })
        if re.search(r'\bAVG\b', sql_upper):
            checklist.append({
                'item': 'AVG의 분모가 0인 경우 처리 확인',
                'detail': '데이터가 없는 그룹에서 AVG가 NULL을 반환하는지 확인',
                'checked': None
            })

    # 날짜 필터
    if re.search(r'\b(DATE|TIMESTAMP|DATETIME)\b', sql_upper) or re.search(r"'\d{4}-\d{2}-\d{2}'", sql):
        checklist.append({
            'item': '날짜 범위 경계값 확인 (포함/제외)',
            'detail': "BETWEEN '2024-01-01' AND '2024-12-31'은 마지막 날 23:59:59를 포함하지 않을 수 있음",
            'checked': None
        })
        checklist.append({
            'item': '타임존 처리 확인',
            'detail': '서버/DB 타임존과 비즈니스 기준 타임존이 다른 경우 날짜 집계 오류 발생',
            'checked': None
        })

    # 조인 관련
    if re.search(r'\bLEFT\s+JOIN\b', sql_upper):
        checklist.append({
            'item': 'LEFT JOIN 결과에서 NULL 처리 확인',
            'detail': '매칭 안 된 행이 집계에 0으로 포함되는지 제외되는지 의도 확인',
            'checked': None
        })

    # 중복 처리
    if re.search(r'\bGROUP\s+BY\b', sql_upper):
        checklist.append({
            'item': 'GROUP BY 기준 컬럼이 비즈니스 집계 단위와 일치하는지 확인',
            'detail': '예: user_id + date로 집계 시 같은 날 여러 주문이 합산되는지 확인',
            'checked': None
        })

    # 분모 0 위험
    if re.search(r'/', sql):
        checklist.append({
            'item': '나눗셈 분모가 0인 경우 처리 확인',
            'detail': 'NULLIF(denominator, 0) 또는 CASE WHEN denominator = 0 THEN NULL 패턴 사용',
            'checked': None
        })

    return checklist

checklist = business_logic_checklist(sql_query, business_intent="월별 사용자 구매 금액 집계")
print("\n=== 비즈니스 로직 검증 체크리스트 ===")
print("(각 항목을 직접 확인하세요)\n")
for i, item in enumerate(checklist, 1):
    status = "☐"
    print(f"{status} {i}. {item['item']}")
    print(f"     → {item['detail']}")
```

---

### 4단계: 결과 저장

```python
# 검증 결과 CSV 저장
results = []
for f in findings:
    results.append({
        'severity': f['severity'],
        'category': f['category'],
        'message': f['message'],
        'suggestion': f['suggestion']
    })

result_df = pd.DataFrame(results)
result_df.to_csv("query-validation_result.csv", index=False, encoding='utf-8-sig')
print(f"✅ query-validation_result.csv 저장 완료 ({len(result_df)}건)")

# 요약 출력
print(f"\n=== 검증 요약 ===")
print(f"  🔴 오류:  {len(errors)}건")
print(f"  🟡 경고:  {len(warnings)}건")
print(f"  🔵 참고:  {len(infos)}건")
print(f"  쿼리 복잡도: {structure['estimated_complexity']}")
if not findings:
    print("  ✅ 탐지된 안티패턴 없음")
```

---

## 컨텍스트 검증

검증 완료 전 확인하세요:

- [ ] 모든 테이블명과 컬럼명이 실제 스키마와 일치하는가?
- [ ] JOIN 조건이 올바른 키를 참조하는가? (PK-FK 관계)
- [ ] NULL 처리가 비즈니스 의도와 일치하는가?
- [ ] 날짜/시간 필터의 경계값이 정확한가? (>= vs >, BETWEEN 포함 여부)
- [ ] 집계 함수의 수준(granularity)이 비즈니스 질문과 맞는가?
- [ ] 오류·경고 항목 중 수정이 필요한 것을 모두 처리했는가?

---

## 출력 템플릿

### `query-validation_report.md` 구조

```
# SQL 쿼리 검증 보고서

## 검증 개요
- 쿼리 유형: {SELECT / INSERT / UPDATE 등}
- 데이터베이스: {PostgreSQL / Snowflake 등}
- 쿼리 복잡도: {단순 / 중간 / 복잡}
- 검증 일시: {날짜}

## 탐지 결과 요약
| 수준 | 건수 |
|------|------|
| 🔴 오류 | {n}건 |
| 🟡 경고 | {n}건 |
| 🔵 참고 | {n}건 |

## 상세 발견사항

### 🔴 오류 (즉시 수정 필요)
| 카테고리 | 문제 | 권장 조치 |

### 🟡 경고 (검토 권장)
| 카테고리 | 문제 | 권장 조치 |

### 🔵 참고 (인지 사항)
| 카테고리 | 내용 | 권장 조치 |

## 비즈니스 로직 검증 결과
| 항목 | 확인 여부 | 비고 |

## 수정된 쿼리 (해당 시)
(오류 수정 및 권장사항 반영 버전)

## 다음 단계
- 권장: 수정 후 query-validation 재실행 또는 programmatic-eda 진행
```
