---
name: schema-mapper
description: 데이터베이스 스키마 이해 및 관계 매핑. 낯선 데이터베이스를 탐색하거나, 테이블 관계를 문서화하거나, 조인 경로를 파악하거나, 기존 스키마에 대한 ERD 문서를 생성할 때 사용하세요. | Database schema understanding and relationship mapping. Use when exploring unfamiliar databases, documenting table relationships, identifying join paths, or generating ERD documentation for existing schemas.
---

# Schema Mapper

## Phase
- **Phase 0 (경로 G-DB)**: DB/SQL 환경에서 분석을 시작할 때 첫 번째 스킬로 실행
- **지원 스킬**: 파일 기반 분석 중 DB 스키마 이해가 필요할 때 언제든 사용

## Input

**경로 G-DB (Phase 0) 진입 시:**
- 이전 스킬: analysis-path-guide (data_source_type = 'db' 확인됨)
- 받는 것: DB 연결 정보 또는 스키마 내보내기 SQL 결과
- context_packet.json의 `db_type` 필드 자동 참조

**지원 스킬로 사용 시:**
- 이전 스킬: context-packager (또는 임의 진입)
- 받는 파일: `context-packager_report.md` + DB/데이터 접근

## Output
- `schema-mapper.ipynb`
- `schema-mapper_result.csv`
- `schema-mapper_report.md`

## 빠른 시작

데이터베이스의 테이블, 컬럼, 관계 및 조인 경로를 포함한 스키마를 자동으로 발견하고, 문서화하고, 시각화합니다. 낯선 데이터베이스를 이해하거나 문서를 작성할 때 필수적입니다.

## 필요한 컨텍스트

스키마를 매핑하기 전에 다음이 필요합니다:

1. **데이터베이스 접근**: 연결 세부 정보 또는 스키마 내보내기
2. **범위**: 어떤 테이블/스키마를 매핑할지 (또는 전체)
3. **문서화 목표**: 필요한 것 (ERD, 조인 경로, 데이터 딕셔너리 등)
4. **알려진 관계** (선택사항): 명시적 외래 키 또는 암묵적 관계

## 컨텍스트 수집

### 데이터베이스 접근의 경우:
"다음 방식으로 스키마를 매핑할 수 있습니다:

**옵션 1 - 직접 데이터베이스 연결:**
```python
connection_details = {
    'host': 'your-db.example.com',
    'database': 'production',
    'user': 'readonly_user',
    'password': '***',
    'type': 'postgresql'  # or mysql, snowflake, bigquery, redshift
}
```

**옵션 2 - 스키마 내보내기:**
```sql
-- PostgreSQL:
SELECT table_schema, table_name, column_name, data_type,
       is_nullable, column_default
FROM information_schema.columns
WHERE table_schema = 'public'
ORDER BY table_name, ordinal_position;

-- Also export constraints:
SELECT * FROM information_schema.table_constraints;
SELECT * FROM information_schema.key_column_usage;
```

**옵션 3 - dbt 프로젝트:**
`dbt_project.yml`과 `models/` 디렉토리를 공유하세요 - dbt 문서에서 스키마를 추출하겠습니다

**옵션 4 - 기존 문서:**
가지고 있는 ERD, 데이터 딕셔너리, 스키마 문서를 공유하세요"

### 범위의 경우:
"다음 중 어떻게 매핑할까요?
- **데이터베이스의 모든 테이블**?
- **특정 스키마** (예: 'public', 'analytics', 'staging')?
- **특정 테이블** (중요한 것들을 나열하세요)?
- **패턴과 일치하는 테이블** (예: 모든 'fct_*' 및 'dim_*' 테이블)?"

### 문서화 목표의 경우:
"이 스키마 매핑에서 무엇이 필요하신가요?

**일반적인 목표:**
1. **시각적 ERD** - 테이블 관계를 그래픽으로 보기
2. **조인 경로 찾기** - 테이블 A를 테이블 B와 조인하는 방법
3. **데이터 딕셔너리** - 테이블 및 컬럼의 완전한 카탈로그
4. **선형도(Lineage Map)** - 테이블을 통한 데이터 흐름 이해
5. **빠른 참조** - 일반적인 조인을 위한 치트 시트

어느 것이 가장 유용할까요?"

### 관계의 경우:
"다음에서 관계를 자동으로 감지합니다:
- 외래 키 제약 조건
- 컬럼 이름 패턴 (id, user_id 등)
- 명명 규칙

암묵적 관계가 있다면 (FK 제약 조건으로 강제되지 않음) 알려주세요:
- 예: 'orders.customer_email은 customers.email과 관련되지만 FK가 없음'"

## 워크플로우

### Step 1: 스키마 연결 및 발견

```python
import pandas as pd
import json, os
import sqlalchemy
from sqlalchemy import create_engine, inspect

# ── context_packet에서 DB 타입 자동 로드 ─────────────────────────
packet_path = "context_packet.json"
packet = {}
if os.path.exists(packet_path):
    with open(packet_path) as f:
        packet = json.load(f)

db_type = packet.get("db_type", None)
if db_type:
    print(f"📥 context_packet에서 DB 타입 로드: {db_type}")
else:
    print("⚠️  context_packet 없음 — connection_string을 직접 입력하세요")

# ── connection_string 설정 (DB 타입별 예시) ──────────────────────
# PostgreSQL: "postgresql://user:password@host:5432/dbname"
# MySQL:      "mysql+pymysql://user:password@host:3306/dbname"
# Snowflake:  "snowflake://user:password@account/dbname/schema"
# BigQuery:   "bigquery://project/dataset"
connection_string = "YOUR_CONNECTION_STRING_HERE"  # ← 실제 연결 정보 입력
# ─────────────────────────────────────────────────────────────────

# 데이터베이스 연결
engine = create_engine(connection_string)
inspector = inspect(engine)

# 모든 스키마 가져오기
schemas = inspector.get_schema_names()
print(f"📚 Schemas found: {schemas}")

# 대상 스키마의 테이블 가져오기
tables = inspector.get_table_names(schema='public')
print(f"📊 Tables in 'public': {len(tables)}")
for table in sorted(tables):
    print(f"  - {table}")
```

**체크포인트**: "스키마에서 {N}개의 테이블을 찾았습니다. 올바르게 보이나요? 누락되거나 예상치 못한 테이블이 있나요?"

### Step 2: 테이블 메타데이터 추출

```python
def extract_table_metadata(engine, schema, table_name):
    """단일 테이블의 포괄적인 메타데이터 추출"""
    inspector = inspect(engine)

    # 컬럼 가져오기
    columns = inspector.get_columns(table_name, schema=schema)

    # 기본 키 가져오기
    pk = inspector.get_pk_constraint(table_name, schema=schema)
    pk_columns = pk.get('constrained_columns', [])

    # 외래 키 가져오기
    fks = inspector.get_foreign_keys(table_name, schema=schema)

    # 인덱스 가져오기
    indexes = inspector.get_indexes(table_name, schema=schema)

    # 고유 제약 조건 가져오기
    unique = inspector.get_unique_constraints(table_name, schema=schema)

    return {
        'table_name': table_name,
        'schema': schema,
        'columns': columns,
        'primary_keys': pk_columns,
        'foreign_keys': fks,
        'indexes': indexes,
        'unique_constraints': unique
    }

# 모든 테이블의 메타데이터 추출
schema_metadata = {}
for table in tables:
    schema_metadata[table] = extract_table_metadata(engine, 'public', table)
    print(f"✓ Extracted metadata for {table}")
```

### Step 3: 관계 추론

```python
def infer_relationships(schema_metadata):
    """
    다음에서 관계 추론:
    1. 명시적 외래 키
    2. 컬럼 명명 패턴 (user_id → users.id)
    3. 일반적인 패턴 (created_by → users.id)
    """
    relationships = []

    for table_name, metadata in schema_metadata.items():
        # 명시적 FK
        for fk in metadata['foreign_keys']:
            relationships.append({
                'type': 'explicit_fk',
                'from_table': table_name,
                'from_column': fk['constrained_columns'][0],
                'to_table': fk['referred_table'],
                'to_column': fk['referred_columns'][0],
                'confidence': 'high'
            })

        # 명명 패턴에서 추론
        for col in metadata['columns']:
            col_name = col['name']

            # 패턴: table_id → table.id
            if col_name.endswith('_id') and col_name != 'id':
                potential_table = col_name[:-3] + 's'  # users_id → users
                if potential_table in schema_metadata:
                    relationships.append({
                        'type': 'inferred_naming',
                        'from_table': table_name,
                        'from_column': col_name,
                        'to_table': potential_table,
                        'to_column': 'id',
                        'confidence': 'medium'
                    })

    return relationships

relationships = infer_relationships(schema_metadata)
print(f"🔗 Found {len(relationships)} relationships")
```

### Step 4: 데이터 딕셔너리 생성

```python
def generate_data_dictionary(schema_metadata):
    """포괄적인 데이터 딕셔너리 생성"""

    dictionary = []

    for table_name, metadata in schema_metadata.items():
        for col in metadata['columns']:
            dictionary.append({
                'table': table_name,
                'column': col['name'],
                'type': str(col['type']),
                'nullable': col['nullable'],
                'default': col.get('default'),
                'is_pk': col['name'] in metadata['primary_keys'],
                'is_fk': any(col['name'] in fk['constrained_columns']
                           for fk in metadata['foreign_keys'])
            })

    df_dict = pd.DataFrame(dictionary)
    return df_dict

data_dict = generate_data_dictionary(schema_metadata)
print(f"\n📖 Data Dictionary:")
print(data_dict.head(20))

# CSV로 저장
data_dict.to_csv('data_dictionary.csv', index=False)
```

### Step 5: 조인 경로 찾기

```python
def find_join_path(from_table, to_table, relationships):
    """
    from_table에서 to_table로 조인하는 방법을 찾습니다
    BFS를 사용하여 가장 짧은 경로를 찾습니다
    """
    from collections import deque

    # 인접 그래프 구축
    graph = {}
    for rel in relationships:
        if rel['from_table'] not in graph:
            graph[rel['from_table']] = []
        graph[rel['from_table']].append({
            'to_table': rel['to_table'],
            'from_col': rel['from_column'],
            'to_col': rel['to_column'],
            'type': rel['type']
        })

    # BFS를 사용하여 경로 찾기
    queue = deque([(from_table, [])])
    visited = {from_table}

    while queue:
        current_table, path = queue.popleft()

        if current_table == to_table:
            return path

        if current_table in graph:
            for edge in graph[current_table]:
                if edge['to_table'] not in visited:
                    visited.add(edge['to_table'])
                    new_path = path + [edge]
                    queue.append((edge['to_table'], new_path))

    return None  # No path found

# 예: orders를 customers와 조인하는 방법?
path = find_join_path('orders', 'customers', relationships)

if path:
    print("\n🛤️  Join Path: orders → customers")
    for i, step in enumerate(path, 1):
        print(f"  Step {i}: JOIN {step['to_table']} " +
              f"ON {path[i-1]['to_table'] if i > 1 else 'orders'}.{step['from_col']} = " +
              f"{step['to_table']}.{step['to_col']}")
else:
    print("❌ No join path found")
```

### Step 6: ERD 생성

```python
def generate_erd_mermaid(schema_metadata, relationships):
    """Mermaid ERD 다이어그램 생성"""

    mermaid = ["erDiagram"]

    # 컬럼이 있는 테이블 추가
    for table_name, metadata in schema_metadata.items():
        mermaid.append(f"    {table_name.upper()} {{")

        for col in metadata['columns'][:10]:  # 주요 컬럼으로 제한
            col_type = str(col['type'])[:20]
            pk_marker = " PK" if col['name'] in metadata['primary_keys'] else ""
            fk_marker = " FK" if any(col['name'] in fk['constrained_columns']
                                    for fk in metadata['foreign_keys']) else ""

            mermaid.append(f"        {col_type} {col['name']}{pk_marker}{fk_marker}")

        mermaid.append("    }")

    # 관계 추가
    for rel in relationships:
        if rel['type'] == 'explicit_fk':
            mermaid.append(
                f"    {rel['from_table'].upper()} ||--o{{ " +
                f"{rel['to_table'].upper()} : {rel['from_column']}"
            )

    return "\n".join(mermaid)

erd = generate_erd_mermaid(schema_metadata, relationships)
print("\n📊 ERD (Mermaid format):")
print(erd)

# 파일에 저장
with open('schema_erd.mmd', 'w') as f:
    f.write(erd)
```

### Step 7: 빠른 참조 가이드 생성

```python
def generate_quick_reference(schema_metadata, relationships):
    """일반적인 조인을 위한 빠른 참조 생성"""

    ref = []
    ref.append("# Schema Quick Reference\n")

    # 테이블 요약
    ref.append("## Tables Overview\n")
    for table_name, metadata in sorted(schema_metadata.items()):
        row_count = f"(~{metadata.get('row_count', '?')} rows)" if 'row_count' in metadata else ""
        ref.append(f"- **{table_name}** {row_count}")
        ref.append(f"  - Primary Key: {', '.join(metadata['primary_keys']) or 'None'}")
        ref.append(f"  - Columns: {len(metadata['columns'])}\n")

    # 일반적인 조인
    ref.append("\n## Common Join Patterns\n")

    # from_table별로 관계 그룹화
    joins_by_table = {}
    for rel in relationships:
        if rel['from_table'] not in joins_by_table:
            joins_by_table[rel['from_table']] = []
        joins_by_table[rel['from_table']].append(rel)

    for table, rels in sorted(joins_by_table.items()):
        ref.append(f"\n### From {table}:\n")
        for rel in rels:
            ref.append(
                f"```sql\n"
                f"JOIN {rel['to_table']} ON {table}.{rel['from_column']} = " +
                f"{rel['to_table']}.{rel['to_column']}\n"
                f"```\n"
            )

    return "\n".join(ref)

quick_ref = generate_quick_reference(schema_metadata, relationships)
print(quick_ref)

# 마크다운으로 저장
with open('schema_quick_reference.md', 'w') as f:
    f.write(quick_ref)
```

## 컨텍스트 검증

진행하기 전에 확인하세요:
- [ ] 데이터베이스 연결이 작동하거나 스키마 내보내기가 완료되었습니다
- [ ] 대상 테이블/스키마가 명확하게 정의되었습니다
- [ ] INFORMATION_SCHEMA를 쿼리할 권한이 있습니다
- [ ] 명시적 관계와 추론된 관계를 구별합니다
- [ ] 필요한 문서 형식을 알고 있습니다

## 출력 템플릿

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
SCHEMA MAPPING REPORT
Database: production_db
Schema: public
Generated: 2025-01-11
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

📊 SCHEMA OVERVIEW
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Total Tables: 42
Total Columns: 387
Total Relationships: 56
  - Explicit (FK): 38
  - Inferred: 18

🗂️  TABLE CATEGORIES
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Fact Tables (fct_*): 8
Dimension Tables (dim_*): 12
Staging Tables (stg_*): 15
Raw Tables (raw_*): 7

📋 KEY TABLES
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

1. users (dim_users)
   - PK: id
   - Columns: 15
   - Referenced by: orders, sessions, events

2. orders (fct_orders)
   - PK: id
   - FK: user_id → users.id, product_id → products.id
   - Columns: 23

3. products (dim_products)
   - PK: id
   - Columns: 12
   - Referenced by: orders, cart_items

🔗 RELATIONSHIP MAP
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

orders → users (user_id)
orders → products (product_id)
sessions → users (user_id)
events → sessions (session_id)
cart_items → products (product_id)

🛤️  COMMON JOIN PATHS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

users → orders:
  JOIN orders ON users.id = orders.user_id

orders → products:
  JOIN products ON orders.product_id = products.id

users → events (via sessions):
  JOIN sessions ON users.id = sessions.user_id
  JOIN events ON sessions.id = events.session_id

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
FILES GENERATED
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

✓ schema_erd.mmd (Mermaid ERD)
✓ data_dictionary.csv (All columns)
✓ schema_quick_reference.md (Join guide)
✓ relationship_graph.json (Machine-readable)
```

## 일반적인 시나리오

### Scenario 1: "새로운 데이터베이스이며 개요가 필요합니다"
→ ERD 및 데이터 딕셔너리를 포함한 전체 스키마 맵
→ 팩트 및 차원 테이블 강조
→ 가장 일반적인 조인 패턴 표시

### Scenario 2: "테이블 A를 테이블 B와 조인하는 방법은?"
→ find_join_path를 사용하여 정확한 SQL 표시
→ 직접 경로가 없으면 다중 홉 조인 표시
→ 경로가 비즈니스 관점에서 의미가 있는지 검증

### Scenario 3: "새 팀원을 위한 스키마 문서화"
→ 포괄적인 빠른 참조 생성
→ 주요 테이블에 대한 비즈니스 컨텍스트 포함
→ 개요를 위한 시각적 ERD 생성

### Scenario 4: "사용자와 관련된 모든 테이블 찾기"
→ 사용자 테이블에서 관계 그래프 순회
→ 직접 및 간접 관계 표시
→ 관계 유형별로 분류

### Scenario 5: "스키마를 예상과 비교하여 검증"
→ 실제 스키마를 문서화된 스키마와 비교
→ 누락된 테이블, 컬럼, 관계에 플래그 지정
→ 스키마 드리프트 식별

## 누락된 컨텍스트 처리

**사용자가 데이터베이스를 제공하지만 컨텍스트 없음:**
"전체 스키마를 매핑하고 개요를 제시하겠습니다. 그런 다음 어느 영역을 깊이 있게 탐색할지 알려주세요."

**사용자가 부분 접근만 가능함 (읽기 전용):**
"쓰기 권한이 필요하지 않은 INFORMATION_SCHEMA 쿼리를 사용하겠습니다. 이것은 구조를 보여주지만 데이터 샘플은 표시하지 않습니다."

**사용자가 데이터베이스 대신 dbt 프로젝트를 가짐:**
"좋습니다! dbt 모델과 문서에서 스키마를 추출하겠습니다. 이것은 종종 원본 데이터베이스 스키마보다 더 나은 비즈니스 컨텍스트를 가집니다."

**사용자가 특정 테이블만 원함:**
"이 테이블들과 직접 관계에 집중하겠습니다. 관련 테이블로 확장하기를 원하시면 알려주세요."

**외래 키가 강제되지 않음:**
"컬럼 명명 패턴에서 관계를 추론하겠습니다. '추론된' 관계를 검토하고 어느 것이 올바른지 확인해주세요."

## 고급 옵션

기본 스키마 매핑 후 다음을 제시합니다:

**선형도 추적**:
"데이터 선형도를 추적하고 싶으신가요? 원본 테이블에서 최종 팩트 테이블로의 데이터 흐름을 보여줄 수 있습니다."

**스키마 비교**:
"환경 간(dev vs prod) 또는 시간이 지남에 따라 스키마를 비교하여 변경 사항을 식별할 수 있습니다."

**쿼리 패턴 분석**:
"쿼리 로그를 제공하면 가장 많이 사용되는 조인 패턴을 식별하고 문서화를 최적화할 수 있습니다."

**dbt 통합**:
"이 매핑에서 dbt schema.yml 파일을 생성하여 모델을 문서화할 수 있습니다."

**자동 문서화**:
"스키마가 변경될 때 업데이트하는 자동 스키마 문서화를 설정할 수 있습니다."

**성능 인사이트**:
"테이블 크기 및 조인 패턴을 기반으로 잠재적 성능 병목 지점을 식별할 수 있습니다."

---

## 경로 G-DB 다음 단계

schema-mapper 완료 후 아래 순서로 진행합니다:

```
schema-mapper 완료
  │  schema-mapper_report.md (ERD + 조인 가이드 + 데이터 딕셔너리)
  ▼
programmatic-eda
  │  ← schema-mapper_report.md를 참고하여 SQL 쿼리 작성
  │    어떤 테이블에서 데이터를 추출할지 결정
  ▼
data-quality-audit
  │
  ▼
analysis-path-guide (재실행)
  → 경로 A~F 중 선택
```

> schema-mapper_report.md의 조인 가이드를 programmatic-eda에 전달하면,
> EDA 단계에서 어떤 컬럼을 조인해 가져올지 바로 결정할 수 있습니다.
