---
name: data-catalog-entry
description: 데이터 자산을 위한 표준화된 메타데이터 생성. 새로운 데이터 세트 문서화, 데이터 카탈로그 구축, 데이터 검색성 개선, 팀용 데이터 사전 생성 시 사용하세요. | Create standardized metadata for data assets. Use when documenting new datasets, building data catalogs, improving data discoverability, or creating data dictionaries for teams.
---

# 데이터 카탈로그 항목(Data Catalog Entry)

## 단계(Phase)
단계 3 — 지식 축적

## 입력(Input)
- 이전 스킬: data-quality-audit + schema-mapper
- 받는 파일: `data-quality-audit_result.csv` + `schema-mapper_report.md`

## 출력(Output)
- `data-catalog-entry_report.md`

## 빠른 시작(Quick Start)

조직 전체에서 발견성, 이해, 적절한 사용을 개선하기 위해 데이터 자산에 대한 포괄적인 표준화된 메타데이터 항목을 생성하세요.

## 문맥 요구사항(Context Requirements)

데이터 자산을 카탈로그화하기 전에 필요한 것:

1. **데이터 자산 세부사항(Data Asset Details)**: 어떤 데이터가 존재하고 어디에 있는가
2. **비즈니스 문맥(Business Context)**: 이것이 무엇을 나타내고 왜 중요한가
3. **기술 사양(Technical Specifications)**: 스키마, 형식, 크기
4. **접근 & 거버넌스(Access & Governance)**: 누가 사용할 수 있고 어떻게 사용하는가
5. **품질 지표(Quality Metrics)**: 신뢰성과 완전성

## 문맥 수집(Context Gathering)

### 데이터 자산을 위해:
"우리가 카탈로그화할 데이터 자산이 뭐죠?

**자산 유형:**
- 데이터베이스 테이블
- 뷰
- 데이터셋 (CSV, Parquet)
- API 엔드포인트
- 대시보드
- 보고서

**기본 정보:**
- 이름: `orders_fact`
- 위치: `postgres://prod/analytics.orders_fact`
- 소유자: 데이터 엔지니어링팀
- 생성: 2024-01-15"

### 비즈니스 문맥을 위해:
"비즈니스 목적을 이해하는 데 도움을 주세요:

**목적:**
- 어떤 비즈니스 프로세스를 이 데이터가 나타내나요?
- 누가 사용하고 어떤 의사결정을 위해?
- 얼마나 중요한가? (미션 크리티컬, 중요, 필수적)

**예:**
- '`orders_fact`는 모든 고객 주문을 포함. 재무팀이 수익 보고, 제품팀이 전환 분석에 사용. 미션 크리티컬.'
- '`user_sessions`은 웹 방문 추적. 성장팀이 참여 분석에 사용. 중요하지만 차단하지 않음.'"

### 스키마를 위해:
"이 데이터셋에 뭐가 있나요?

**필요:**
- 열 이름과 데이터 타입
- 각 필드의 설명
- 다른 테이블과의 관계
- 샘플 값
- 비즈니스 규칙

`DESCRIBE TABLE` 출력 또는 스키마 문서를 제공할 수 있나요?"

### 품질을 위해:
"이 데이터가 얼마나 신뢰할 수 있나요?

**품질 차원:**
- **완전성:** 필드의 %가 채워짐
- **정확성:** 알려진 데이터 품질 문제?
- **신선도:** 얼마나 자주 업데이트? 지연?
- **일관성:** 다른 소스와 일치?

**예:** 'orders_fact는 99.9% 완전, 실시간 업데이트, Stripe와 일일 $10 내에서 일치'"

### 접근을 위해:
"누가 이를 사용할 수 있나요?

**접근 제어:**
- 공개 (모든 직원)
- 제한적 (특정 팀)
- 기밀 (특수 승인)
- PII/민감 데이터 포함?

**사용 지침:**
- 사용에 제약이 있나요?
- 필수 승인?
- 규정 준수 요구사항?"

## 워크플로우(Workflow)

### 단계 1: 기술 메타데이터 추출

```python
import pandas as pd
import sqlalchemy
from datetime import datetime

def extract_table_metadata(connection_string, schema, table_name):
    """
    데이터베이스 테이블에서 기술 메타데이터 추출
    """

    engine = sqlalchemy.create_engine(connection_string)
    inspector = sqlalchemy.inspect(engine)

    metadata = {
        'name': table_name,
        'schema': schema,
        'type': 'table',
        'location': f"{schema}.{table_name}",
        'extracted_at': datetime.now().isoformat()
    }

    # 열 가져오기
    columns = inspector.get_columns(table_name, schema=schema)
    metadata['columns'] = []

    for col in columns:
        metadata['columns'].append({
            'name': col['name'],
            'type': str(col['type']),
            'nullable': col['nullable'],
            'default': col.get('default'),
            'primary_key': False,  # 아래에서 업데이트
            'foreign_key': False
        })

    # 기본 키 가져오기
    pk = inspector.get_pk_constraint(table_name, schema=schema)
    pk_columns = pk.get('constrained_columns', [])

    for col in metadata['columns']:
        if col['name'] in pk_columns:
            col['primary_key'] = True

    # 외래 키 가져오기
    fks = inspector.get_foreign_keys(table_name, schema=schema)
    fk_columns = []
    for fk in fks:
        fk_columns.extend(fk['constrained_columns'])

    for col in metadata['columns']:
        if col['name'] in fk_columns:
            col['foreign_key'] = True

    # 행 수 가져오기
    query = f"SELECT COUNT(*) as row_count FROM {schema}.{table_name}"
    result = pd.read_sql(query, engine)
    metadata['row_count'] = int(result['row_count'].iloc[0])

    # 샘플 데이터 가져오기
    query = f"SELECT * FROM {schema}.{table_name} LIMIT 5"
    sample = pd.read_sql(query, engine)
    metadata['sample_data'] = sample.to_dict('records')

    return metadata

# 메타데이터 추출
metadata = extract_table_metadata(
    connection_string='postgresql://user:pass@host:5432/db',
    schema='analytics',
    table_name='orders_fact'
)

print(f"✅ {metadata['name']}에 대한 메타데이터 추출됨")
print(f"   열: {len(metadata['columns'])}")
print(f"   행: {metadata['row_count']:,}")
```

### 단계 2: 비즈니스 문맥 추가

```python
def add_business_context(metadata, business_info):
    """
    기술 메타데이터를 비즈니스 문맥으로 강화
    """

    metadata.update({
        'display_name': business_info.get('display_name', metadata['name']),
        'description': business_info['description'],
        'business_owner': business_info['business_owner'],
        'technical_owner': business_info['technical_owner'],
        'domain': business_info['domain'],  # 예: '판매', '마케팅', '재무'
        'criticality': business_info['criticality'],  # 중요, 높음, 중간, 낮음
        'use_cases': business_info['use_cases'],
        'stakeholders': business_info['stakeholders']
    })

    return metadata

# 비즈니스 문맥 추가
business_info = {
    'display_name': '주문 팩트 테이블',
    'description': '모든 고객 주문의 완전한 이력 (주문 상세, 가격, 이행 상태 포함). 주문 데이터의 단일 정보 소스.',
    'business_owner': '재무 담당 이사',
    'technical_owner': '데이터 엔지니어링팀',
    'domain': '판매 & 수익',
    'criticality': 'critical',
    'use_cases': [
        '수익 보고 및 예측',
        '고객 분석 및 세분화',
        '제품 성능 분석',
        '재고 계획'
    ],
    'stakeholders': [
        '재무팀 (일일 수익 보고)',
        '제품팀 (전환 분석)',
        '운영팀 (이행 추적)'
    ]
}

metadata = add_business_context(metadata, business_info)
print("✅ 비즈니스 문맥 추가됨")
```

### 단계 3: 열 정의 문서화

```python
def add_column_business_definitions(metadata, column_definitions):
    """
    열에 비즈니스 친화적 설명 추가
    """

    for col in metadata['columns']:
        col_name = col['name']

        if col_name in column_definitions:
            col.update({
                'business_name': column_definitions[col_name].get('business_name', col_name),
                'description': column_definitions[col_name]['description'],
                'example_values': column_definitions[col_name].get('examples'),
                'business_rules': column_definitions[col_name].get('rules'),
                'common_values': column_definitions[col_name].get('common_values')
            })

    return metadata

# 열 정의
column_definitions = {
    'order_id': {
        'business_name': '주문 ID',
        'description': '각 주문을 위한 고유 식별자',
        'examples': ['ORD-2024-00001', 'ORD-2024-00002'],
        'rules': ['형식: ORD-YYYY-NNNNN', '연도별 순차', '절대 NULL이 아님']
    },
    'customer_id': {
        'business_name': '고객 ID',
        'description': '주문을 한 고객의 참조',
        'examples': ['CUST-12345', 'CUST-67890'],
        'rules': ['고객 테이블로의 외래 키', '필수 필드']
    },
    'order_date': {
        'business_name': '주문 날짜',
        'description': '주문이 배치된 날짜 및 시간',
        'examples': ['2024-12-15 10:30:00'],
        'rules': ['UTC 시간대', '절대 미래에 없음', '고객 가입 날짜 이후 불가']
    },
    'total_amount': {
        'business_name': '주문 합계',
        'description': '세금과 배송을 포함한 USD 기준 총 주문 가치',
        'examples': ['49.99', '129.50'],
        'rules': ['항상 양수', '세금과 배송 포함', '환불 제외']
    },
    'status': {
        'business_name': '주문 상태',
        'description': '주문의 현재 이행 상태',
        'examples': ['pending', 'shipped', 'delivered', 'cancelled'],
        'common_values': {
            'pending': '주문 배치, 결제 확인, 이행 대기 중',
            'shipped': '주문이 고객에게 발송됨',
            'delivered': '고객이 주문 수신함',
            'cancelled': '주문 취소 (배송 전후)'
        },
        'rules': ['상태 전환: pending → shipped → delivered', '돌아갈 수 없음 (취소 제외)']
    }
}

metadata = add_column_business_definitions(metadata, column_definitions)
print("✅ 열 정의 문서화됨")
```

### 단계 4: 데이터 품질 지표 추가

```python
def assess_data_quality(connection_string, schema, table_name):
    """
    데이터 품질 지표 계산
    """

    engine = sqlalchemy.create_engine(connection_string)

    quality_metrics = {
        'assessed_date': datetime.now().isoformat()
    }

    # 열별 완전성
    query = f"""
    SELECT
        column_name,
        COUNT(*) as total_rows,
        COUNT(column_name) as non_null_rows,
        ROUND(COUNT(column_name)::numeric / COUNT(*) * 100, 2) as completeness_pct
    FROM {schema}.{table_name}
    CROSS JOIN (
        SELECT column_name
        FROM information_schema.columns
        WHERE table_schema = '{schema}' AND table_name = '{table_name}'
    ) cols
    GROUP BY column_name
    """

    completeness = pd.read_sql(query, engine)
    quality_metrics['completeness'] = completeness.to_dict('records')

    # 전체 완전성 점수
    quality_metrics['overall_completeness'] = completeness['completeness_pct'].mean()

    # 신선도
    query = f"""
    SELECT MAX(updated_at) as last_updated
    FROM {schema}.{table_name}
    """

    freshness = pd.read_sql(query, engine)
    last_updated = pd.to_datetime(freshness['last_updated'].iloc[0])
    hours_old = (datetime.now() - last_updated).total_seconds() / 3600

    quality_metrics['freshness'] = {
        'last_updated': last_updated.isoformat(),
        'hours_since_update': hours_old,
        'status': 'fresh' if hours_old < 24 else 'stale'
    }

    # 중복 검사
    query = f"""
    SELECT COUNT(*) as duplicates
    FROM (
        SELECT order_id, COUNT(*)
        FROM {schema}.{table_name}
        GROUP BY order_id
        HAVING COUNT(*) > 1
    ) dups
    """

    duplicates = pd.read_sql(query, engine)
    quality_metrics['duplicates'] = int(duplicates['duplicates'].iloc[0])

    # 품질 점수 (0-100)
    quality_score = (
        quality_metrics['overall_completeness'] * 0.4 +
        (100 if hours_old < 24 else max(0, 100 - hours_old)) * 0.3 +
        (100 if quality_metrics['duplicates'] == 0 else 90) * 0.3
    )

    quality_metrics['quality_score'] = round(quality_score, 1)

    return quality_metrics

quality = assess_data_quality('postgresql://...', 'analytics', 'orders_fact')
metadata['quality_metrics'] = quality

print(f"✅ 품질 평가됨: {quality['quality_score']}/100")
```

### 단계 5: 데이터 계보 문서화

```python
def document_lineage(upstream_sources, downstream_consumers):
    """
    데이터가 어디에서 오고 어디로 가는지 문서화
    """

    lineage = {
        'upstream': [],
        'downstream': []
    }

    # 상위 소스
    for source in upstream_sources:
        lineage['upstream'].append({
            'source': source['name'],
            'type': source['type'],
            'refresh_frequency': source.get('refresh', 'unknown'),
            'transformation': source.get('transformation', 'none')
        })

    # 하위 소비자
    for consumer in downstream_consumers:
        lineage['downstream'].append({
            'consumer': consumer['name'],
            'type': consumer['type'],
            'use_case': consumer['use_case']
        })

    return lineage

# 계보 문서화
upstream = [
    {
        'name': 'production.orders (Postgres)',
        'type': 'database_table',
        'refresh': 'real-time replication',
        'transformation': 'dbt 모델과 비즈니스 로직'
    },
    {
        'name': 'stripe_api',
        'type': 'api',
        'refresh': 'daily sync',
        'transformation': '결제 세부사항으로 강화'
    }
]

downstream = [
    {
        'name': '수익 대시보드',
        'type': 'dashboard',
        'use_case': '일일 수익 모니터링'
    },
    {
        'name': 'customer_lifetime_value 모델',
        'type': 'ml_model',
        'use_case': 'LTV 예측'
    },
    {
        'name': 'monthly_revenue_report',
        'type': 'scheduled_report',
        'use_case': '이사회 보고'
    }
]

metadata['lineage'] = document_lineage(upstream, downstream)
print("✅ 계보 문서화됨")
```

### 단계 6: 접근 & 거버넌스 추가

```python
def add_governance_info(metadata, governance):
    """
    접근 제어 및 규정 준수 정보 추가
    """

    metadata['governance'] = {
        'access_level': governance['access_level'],  # public, restricted, confidential
        'sensitivity': governance['sensitivity'],  # none, pii, financial, health
        'compliance_tags': governance.get('compliance_tags', []),
        'retention_policy': governance.get('retention_policy'),
        'access_instructions': governance['access_instructions'],
        'approved_use_cases': governance.get('approved_uses'),
        'restricted_use_cases': governance.get('restricted_uses')
    }

    return metadata

governance = {
    'access_level': 'restricted',
    'sensitivity': 'financial',
    'compliance_tags': ['SOX', 'GDPR'],
    'retention_policy': '규제 요구사항당 7년',
    'access_instructions': 'ServiceNow 티켓을 통해 접근 요청. 관리자 승인 필요.',
    'approved_uses': [
        '재무 보고 및 분석',
        '제품 분석',
        '고객 세분화'
    ],
    'restricted_uses': [
        '동의 없이 개별 고객을 대상으로 함',
        '법무 검토 없이 외부 공유'
    ]
}

metadata = add_governance_info(metadata, governance)
print("✅ 거버넌스 정책 문서화됨")
```

### 단계 7: 카탈로그 항목 생성

```python
def generate_catalog_entry_markdown(metadata):
    """
    인간이 읽을 수 있는 카탈로그 항목 생성
    """

    doc = f"# {metadata['display_name']}\n\n"

    # 개요
    doc += "## 개요(Overview)\n\n"
    doc += f"**이름:** `{metadata['location']}`\n"
    doc += f"**유형:** {metadata['type']}\n"
    doc += f"**도메인:** {metadata['domain']}\n"
    doc += f"**중요도:** {metadata['criticality'].upper()}\n\n"
    doc += f"**설명:**\n{metadata['description']}\n\n"

    # 소유권
    doc += "## 소유권(Ownership)\n\n"
    doc += f"- **비즈니스 소유자:** {metadata['business_owner']}\n"
    doc += f"- **기술 소유자:** {metadata['technical_owner']}\n\n"

    # 품질
    doc += "## 데이터 품질(Data Quality)\n\n"
    quality = metadata['quality_metrics']
    doc += f"**품질 점수:** {quality['quality_score']}/100\n\n"
    doc += f"- **완전성:** {quality['overall_completeness']:.1f}%\n"
    doc += f"- **신선도:** 마지막 업데이트 {quality['freshness']['hours_since_update']:.1f}시간 전\n"
    doc += f"- **중복:** {quality['duplicates']}개 발견\n\n"

    # 스키마
    doc += "## 스키마(Schema)\n\n"
    doc += f"**행 수:** {metadata['row_count']:,}\n"
    doc += f"**열:** {len(metadata['columns'])}\n\n"

    doc += "| 열 | 유형 | 설명 | NULL 가능 | 키 |\n"
    doc += "|--------|------|-------------|----------|------|\n"

    for col in metadata['columns']:
        keys = []
        if col.get('primary_key'):
            keys.append('PK')
        if col.get('foreign_key'):
            keys.append('FK')
        keys_str = ', '.join(keys) if keys else '-'

        desc = col.get('description', '-')[:50]
        doc += f"| {col['name']} | {col['type']} | {desc} | {'예' if col['nullable'] else '아니오'} | {keys_str} |\n"

    doc += "\n"

    # 사용 사례
    doc += "## 사용 사례(Use Cases)\n\n"
    for use_case in metadata['use_cases']:
        doc += f"- {use_case}\n"
    doc += "\n"

    # 계보
    doc += "## 데이터 계보(Data Lineage)\n\n"
    doc += "**상위 소스:**\n"
    for source in metadata['lineage']['upstream']:
        doc += f"- {source['source']} ({source['type']})\n"

    doc += "\n**하위 소비자:**\n"
    for consumer in metadata['lineage']['downstream']:
        doc += f"- {consumer['consumer']} - {consumer['use_case']}\n"

    doc += "\n"

    # 접근
    doc += "## 접근 & 거버넌스(Access & Governance)\n\n"
    gov = metadata['governance']
    doc += f"**접근 수준:** {gov['access_level'].upper()}\n"
    doc += f"**민감도:** {gov['sensitivity'].upper()}\n"
    doc += f"**규정 준수:** {', '.join(gov['compliance_tags'])}\n\n"
    doc += f"**접근 지침:**\n{gov['access_instructions']}\n\n"

    # 바닥글
    doc += "---\n\n"
    doc += f"*마지막 업데이트: {metadata['extracted_at']}*\n"

    return doc

catalog_entry = generate_catalog_entry_markdown(metadata)

# 저장
with open(f"{metadata['name']}_catalog_entry.md", 'w') as f:
    f.write(catalog_entry)

print(f"✅ 카탈로그 항목 생성됨: {metadata['name']}_catalog_entry.md")

# JSON으로도 저장 (프로그래매틱 접근용)
import json
with open(f"{metadata['name']}_metadata.json", 'w') as f:
    json.dump(metadata, f, indent=2, default=str)

print(f"✅ 메타데이터 JSON 저장됨: {metadata['name']}_metadata.json")
```

## 문맥 검증

카탈로그 항목을 게시하기 전에 확인:
- [ ] 기술 메타데이터가 정확하게 추출됨
- [ ] 비즈니스 문맥이 데이터 소유자에 의해 검토됨
- [ ] 열 설명이 비기술 사용자에게 명확
- [ ] 품질 지표가 현재 및 정확
- [ ] 접근 정책이 올바르게 문서화됨
- [ ] 계보가 완전하고 최신

## 출력 템플릿

```
# 주문 팩트 테이블

## 개요

**이름:** `analytics.orders_fact`
**유형:** table
**도메인:** 판매 & 수익
**중요도:** CRITICAL

**설명:**
모든 고객 주문의 완전한 이력 (주문 상세, 가격, 이행 상태 포함). 주문 데이터의 단일 정보 소스.

## 소유권

- **비즈니스 소유자:** 재무 담당 이사
- **기술 소유자:** 데이터 엔지니어링팀

## 데이터 품질

**품질 점수:** 98.5/100

- **완전성:** 99.8%
- **신선도:** 마지막 업데이트 0.5시간 전
- **중복:** 0개 발견

## 스키마

**행 수:** 1,250,000
**열:** 12

| 열 | 유형 | 설명 | NULL 가능 | 키 |
|--------|------|-------------|----------|------|
| order_id | VARCHAR | 각 주문을 위한 고유 식별자 | 아니오 | PK |
| customer_id | INTEGER | 고객에 대한 참조 | 아니오 | FK |
| order_date | TIMESTAMP | 주문이 배치된 날짜/시간 | 아니오 | - |
| total_amount | DECIMAL | USD 기준 주문 합계 | 아니오 | - |
| status | VARCHAR | 현재 이행 상태 | 아니오 | - |

## 사용 사례

- 수익 보고 및 예측
- 고객 분석 및 세분화
- 제품 성능 분석
- 재고 계획

## 데이터 계보

**상위 소스:**
- production.orders (Postgres) - 실시간 레플리케이션
- stripe_api - 일일 결제 데이터 동기화

**하위 소비자:**
- 수익 대시보드 - 일일 수익 모니터링
- customer_lifetime_value 모델 - LTV 예측
- monthly_revenue_report - 이사회 보고

## 접근 & 거버넌스

**접근 수준:** RESTRICTED
**민감도:** FINANCIAL
**규정 준수:** SOX, GDPR

**접근 지침:**
ServiceNow 티켓을 통해 접근 요청. 관리자 승인 필요.

**승인된 사용:**
- 재무 보고 및 분석
- 제품 분석
- 고객 세분화

**제한된 사용:**
- 동의 없이 개별 고객 대상화
- 법무 검토 없이 외부 공유

---

*마지막 업데이트: 2025-01-11T15:30:00*
```

## 일반적인 시나리오

### 시나리오 1: "새 테이블 생성, 카탈로그 항목 필요"
→ 기술 메타데이터 자동 추출
→ 테이블 소유자에게 비즈니스 문맥 인터뷰
→ 열 정의 문서화
→ 초기 데이터 품질 평가
→ 카탈로그에 게시

### 시나리오 2: "데이터 카탈로그 완전성 감사"
→ 데이터베이스의 모든 테이블 나열
→ 카탈로그 항목이 없는 테이블 식별
→ 사용/중요도별로 우선순위 지정
→ 체계적으로 항목 생성
→ 자동 업데이트 설정

### 시나리오 3: "사용자가 필요한 데이터를 찾을 수 없음"
→ 더 나은 설명으로 검색 개선
→ 비즈니스 친화적 이름 추가
→ 관련 도메인으로 태그
→ 일반적인 사용 사례 문서화
→ 관련 데이터셋 링크

### 시나리오 4: "규정 준수 감사 필요"
→ 모든 민감 데이터 문서화
→ 규정 준수 태그 추가
→ 보관 정책 기록
→ 접근 제어 문서화
→ 감사 보고서 생성

### 시나리오 5: "새 분석가 온보딩"
→ 주요 데이터셋의 가이드 투어 생성
→ 방법 예시 문서화
→ 관련 리소스로 링크
→ 샘플 쿼리 제공
→ 교육 경로 설정

## 누락된 문맥 처리

**사용자가 테이블 이름만 가짐:**
"기술 메타데이터를 자동으로 추출할 수 있습니다. 하지만 이것을 도와주면 좋겠습니다:
- 이 데이터가 무엇을 나타내나요?
- 누가 사용하고 왜?
- 누가 소유하나요?
- 특별한 고려사항이 있나요?

5분 대화가 이것을 10배 더 유용하게 만듭니다."

**사용자가 품질 지표 확실하지 않음:**
"기본 품질 (완전성, 신선도, 중복)을 계산할 수 있습니다. 추가하고 싶으신가요:
- 알고 있는 특정 검증 규칙?
- 알려진 데이터 품질 문제?
- 수용 기준?

이렇게 하면 사용자가 데이터를 신뢰합니다."

**사용자가 계보를 모름:**
"함께 추적해봅시다:
- 이 데이터가 원래 어디에서 왔나요?
- 어떤 변환이 발생하나요?
- 알고 있는 하위 사용처가 뭐죠?

지금 아는 것을 문서화하고, 나중에 더 추가합시다."

**사용자가 접근 정책 불확실:**
"확실해질 때까지 '제한적'으로 기본값 설정:
- PII 또는 민감 데이터를 포함하나요?
- 규정 준수 요구사항이 있나요?
- 현재 누가 접근할 수 있나요?

민감 데이터를 실수로 노출시키지 않는 것이 더 나습니다."

## 고급 옵션

기본 카탈로그 항목 후 제공:

**자동화된 메타데이터 추출**:
"매일 밤 자동으로 메타데이터를 새로 고칠 파이프라인을 설정 - 카탈로그를 최신 상태로 유지."

**데이터 프로파일링**:
"각 열에 대해 통계 프로필 생성 (분포, 상관관계)."

**샘플 데이터 미리보기**:
"빠른 탐색을 위한 샘플 행 (첫 100개)이 있는 대화형 미리보기 추가."

**쿼리 예시**:
"이 테이블에 대한 일반적인 SQL 패턴 포함 - 사용자가 시작하는 데 도움."

**스키마 변경 추적**:
"스키마가 변경될 때 경고 (열 추가/제거/이름 변경)."

**사용 분석**:
"이 테이블을 누가 얼마나 자주 쿼리하는지 추적 - 인기 있는 데이터셋을 식별합니다."
