---
name: dashboard-specification
description: 효과적인 대시보드를 위한 설계 사양을 제공합니다. Design specifications for effective dashboards. Use when planning new dashboards, improving existing ones, or documenting dashboard requirements before development.
---

# 대시보드 사양(Dashboard Specification)

## 단계(Phase)
Phase 6 — 시각화 및 전달

## 입력(Input)
- 이전 스킬: visualization-builder + insight-synthesis
- 받는 파일: `visualization-builder_report.md` + `insight-synthesis_report.md`

## 출력(Output)
- `dashboard-specification_report.md`

## 빠른 시작(Quick Start)

개발을 시작하기 전에 메트릭, 레이아웃, 상호 작용성 및 사용자 요구사항을 명확하게 정의하는 포괄적인 대시보드 사양을 만드세요.

## 컨텍스트 요구사항(Context Requirements)

1. **목적(Purpose)**: 대시보드가 어떤 의사 결정을 지원할 것인가
2. **사용자(Users)**: 누가 사용할 것이고 얼마나 자주
3. **메트릭(Metrics)**: 필요한 KPI 및 지원 메트릭
4. **데이터 소스(Data Sources)**: 데이터가 어디에서 나오는가
5. **새로 고침(Refresh)**: 데이터가 얼마나 자주 업데이트되는가

## 컨텍스트 수집(Context Gathering)

"대시보드 사양을 작성하기 위해 필요한 정보:
- 주요 사용 사례(어떤 의사 결정?)
- 사용자(역할, 빈도, 기술 수준)
- 필수 메트릭 vs 선택사항
- 데이터 가용성 및 신선도
- 대체 또는 개선할 기존 대시보드"

## 워크플로우(Workflow)

### 단계 1: 대시보드 목적 정의(Define Dashboard Purpose)

```python
from datetime import datetime

class DashboardSpec:
    def __init__(self, name, purpose):
        self.name = name
        self.purpose = purpose
        self.target_users = []
        self.use_cases = []
        self.metrics = []
        self.data_sources = []
        self.layout = None
        
    def add_user_persona(self, role, frequency, use_case):
        self.target_users.append({
            'role': role,
            'frequency': frequency,
            'use_case': use_case
        })
    
    def add_metric(self, name, definition, calculation, importance):
        self.metrics.append({
            'name': name,
            'definition': definition,
            'calculation': calculation,
            'importance': importance  # primary, secondary
        })
    
    def add_data_source(self, source, tables, refresh):
        self.data_sources.append({
            'source': source,
            'tables': tables,
            'refresh': refresh
        })

# Initialize
spec = DashboardSpec(
    name="Revenue Performance Dashboard",
    purpose="Monitor daily revenue performance, identify trends, and track against targets"
)

spec.add_user_persona(
    role="VP Sales",
    frequency="Daily (morning)",
    use_case="Check if on track for monthly target, identify at-risk deals"
)

spec.add_user_persona(
    role="Sales Reps",
    frequency="Multiple times daily",
    use_case="Track personal performance, pipeline health"
)

print(f"✅ Dashboard spec started: {spec.name}")
```

### 단계 2: 메트릭 계층 정의(Define Metrics Hierarchy)

```python
# Primary metrics (hero numbers)
spec.add_metric(
    name="MTD Revenue",
    definition="Total revenue closed month-to-date",
    calculation="SUM(deal_value) WHERE close_date >= start_of_month AND status = 'closed_won'",
    importance="primary"
)

spec.add_metric(
    name="Revenue vs Target",
    definition="Actual MTD revenue compared to monthly target",
    calculation="(MTD_revenue / monthly_target) * 100",
    importance="primary"
)

# Secondary metrics (supporting context)
spec.add_metric(
    name="Win Rate",
    definition="% of opportunities won this month",
    calculation="COUNT(won) / COUNT(total_opps) * 100",
    importance="secondary"
)

spec.add_metric(
    name="Average Deal Size",
    definition="Mean value of deals closed MTD",
    calculation="AVG(deal_value) WHERE status = 'closed_won'",
    importance="secondary"
)

print(f"✅ Metrics defined: {len(spec.metrics)}")
```

### 단계 3: 정보 아키텍처 설계(Design Information Architecture)

```python
def design_dashboard_layout(metrics, user_priority):
    """
    Create hierarchical layout based on user needs
    """
    
    layout = {
        'hero_section': {
            'size': 'large',
            'position': 'top',
            'metrics': []
        },
        'trend_section': {
            'size': 'medium',
            'position': 'middle_left',
            'charts': []
        },
        'breakdown_section': {
            'size': 'medium',
            'position': 'middle_right',
            'charts': []
        },
        'detail_section': {
            'size': 'small',
            'position': 'bottom',
            'tables': []
        }
    }
    
    # Primary metrics → Hero section
    for metric in metrics:
        if metric['importance'] == 'primary':
            layout['hero_section']['metrics'].append({
                'metric': metric['name'],
                'display': 'KPI card with sparkline'
            })
    
    # Trends
    layout['trend_section']['charts'] = [
        'Daily revenue trend (30 days)',
        'Revenue by product line (trend)',
        'Pipeline conversion funnel'
    ]
    
    # Breakdowns
    layout['breakdown_section']['charts'] = [
        'Revenue by sales rep (bar)',
        'Win rate by region (map)',
        'Deal size distribution (histogram)'
    ]
    
    # Details
    layout['detail_section']['tables'] = [
        'Top 10 deals closed MTD',
        'At-risk pipeline deals'
    ]
    
    return layout

spec.layout = design_dashboard_layout(spec.metrics, 'VP Sales')
print("✅ Layout designed")
```

### 단계 4: 상호 작용성 정의(Define Interactivity)

```python
def specify_interactions(layout):
    """Define filters, drill-downs, and actions"""
    
    interactions = {
        'global_filters': [
            {'filter': 'Date Range', 'default': 'MTD', 'options': ['MTD', 'QTD', 'YTD', 'Custom']},
            {'filter': 'Region', 'default': 'All', 'options': ['All', 'North America', 'EMEA', 'APAC']},
            {'filter': 'Product', 'default': 'All', 'options': ['All', 'Product A', 'Product B', 'Product C']}
        ],
        'drill_downs': [
            {'from': 'Revenue by Region', 'to': 'Revenue by Sales Rep'},
            {'from': 'Pipeline chart', 'to': 'Individual deals in stage'}
        ],
        'click_actions': [
            {'element': 'Deal in table', 'action': 'Open deal details in CRM'},
            {'element': 'Sales rep name', 'action': 'Filter to rep performance'}
        ],
        'hover_tooltips': [
            {'chart': 'All charts', 'show': 'Exact values, % change, vs target'}
        ]
    }
    
    return interactions

interactions = specify_interactions(spec.layout)
print("✅ Interactivity specified")
```

### 단계 5: 데이터 요구사항 문서화(Document Data Requirements)

```python
# Data sources
spec.add_data_source(
    source="Salesforce CRM",
    tables=["Opportunity", "Account", "User"],
    refresh="Real-time (15 min)"
)

spec.add_data_source(
    source="Finance Database",
    tables=["revenue_targets"],
    refresh="Daily at midnight"
)

def create_data_model_spec():
    """Document required data model"""
    
    model = """
    ## Required Data Model
    
    ### Fact Table: deal_facts
    - deal_id (PK)
    - close_date
    - deal_value
    - status (closed_won, closed_lost, open)
    - sales_rep_id (FK)
    - product_id (FK)
    - region
    
    ### Dimension: sales_reps
    - rep_id (PK)
    - rep_name
    - region
    - quota
    
    ### Dimension: products
    - product_id (PK)
    - product_name
    - category
    
    ### Metrics Table: targets
    - month
    - target_revenue
    - target_deals
    """
    
    return model

data_model = create_data_model_spec()
print("✅ Data model documented")
```

### 단계 6: 완전한 사양 생성(Generate Complete Specification)

```python
def generate_dashboard_spec(spec):
    """Create comprehensive dashboard specification document"""
    
    doc = f"# Dashboard Specification: {spec.name}\n\n"
    doc += f"**Purpose:** {spec.purpose}\n\n"
    doc += f"**Created:** {datetime.now().strftime('%Y-%m-%d')}\n\n"
    doc += "---\n\n"
    
    # Users
    doc += "## Target Users\n\n"
    for user in spec.target_users:
        doc += f"**{user['role']}**\n"
        doc += f"- Frequency: {user['frequency']}\n"
        doc += f"- Use Case: {user['use_case']}\n\n"
    
    # Metrics
    doc += "## Metrics\n\n"
    doc += "### Primary Metrics\n\n"
    for metric in spec.metrics:
        if metric['importance'] == 'primary':
            doc += f"**{metric['name']}**\n"
            doc += f"- Definition: {metric['definition']}\n"
            doc += f"- Calculation: `{metric['calculation']}`\n\n"
    
    # Layout
    doc += "## Dashboard Layout\n\n"
    doc += "```\n"
    doc += "┌─────────────────────────────────────────┐\n"
    doc += "│  HERO SECTION (KPI Cards)               │\n"
    doc += "│  MTD Revenue | vs Target | Win Rate     │\n"
    doc += "└─────────────────────────────────────────┘\n"
    doc += "┌───────────────────┬─────────────────────┐\n"
    doc += "│ TRENDS            │ BREAKDOWNS          │\n"
    doc += "│ Revenue trend     │ By sales rep        │\n"
    doc += "│ Pipeline funnel   │ By region           │\n"
    doc += "└───────────────────┴─────────────────────┘\n"
    doc += "┌─────────────────────────────────────────┐\n"
    doc += "│ DETAIL TABLES                           │\n"
    doc += "│ Top deals | At-risk pipeline            │\n"
    doc += "└─────────────────────────────────────────┘\n"
    doc += "```\n\n"
    
    # Data sources
    doc += "## Data Sources\n\n"
    for source in spec.data_sources:
        doc += f"**{source['source']}**\n"
        doc += f"- Tables: {', '.join(source['tables'])}\n"
        doc += f"- Refresh: {source['refresh']}\n\n"
    
    return doc

full_spec = generate_dashboard_spec(spec)

with open('dashboard_spec.md', 'w') as f:
    f.write(full_spec)

print("✅ Complete specification generated: dashboard_spec.md")
```

## 컨텍스트 검증(Context Validation)

- [ ] 사용자 요구사항이 명확하게 정의됨
- [ ] 메트릭에 명확한 정의가 있음
- [ ] 데이터 소스가 이용 가능하다고 확인됨
- [ ] 새로 고침 빈도가 현실적임
- [ ] 레이아웃이 가장 중요한 정보에 우선순위를 지정함
- [ ] 상호 작용성이 사용자 목표에 부합함

## 출력 템플릿(Output Template)

```
# 대시보드 사양(Dashboard Specification): 수익 성과 대시보드

**목적:** 일일 수익을 모니터링하고, 추세를 파악하고, 목표 대비 추적

---

## 대상 사용자(Target Users)

**판매 담당 부사장(VP Sales)** (일일)
- 월별 목표 달성률 확인
- 위험 상태의 거래 식별

**영업 사원(Sales Reps)** (하루 여러 번)
- 개인 성과 추적
- 파이프라인 상태 모니터링

## 메트릭(Metrics)

### 주요 메트릭(Primary - 영웅 섹션)
- 당월 수익: $XXX,XXX
- 월별 목표 대비: XX%
- 성약률: XX%

### 보조 메트릭(Secondary - 지원)
- 평균 거래 규모
- 종결까지의 날수
- 파이프라인 범위

## 레이아웃(Layout)

[KPI 카드, 추세 차트, 분해 차트, 상세 테이블을 보여주는 시각적 와이어프레임]

## 상호 작용성(Interactivity)

**필터(Filters):** 날짜 범위, 지역, 제품
**드릴다운(Drill-downs):** 지역 → 담당자 → 거래
**조치(Actions):** 거래 클릭 → CRM에서 열기

## 데이터 요구사항(Data Requirements)

**소스(Sources):**
- Salesforce (실시간, 15분 지연)
- Finance 데이터베이스(Finance DB)(일일 새로 고침)

**테이블(Tables):**
- Opportunity, Account, User
- revenue_targets

## 성공 메트릭(Success Metrics)

대시보드가 성공적이려면:
- 판매팀의 90%가 매일 로드
- 평균 세션 시간: 3-5분
- 임시 데이터 요청 50% 감소
```

## 일반적인 시나리오(Common Scenarios)

### 시나리오 1: "새로운 임원진 대시보드 설계"
→ 고급 KPI에 초점
→ 상호 작용 최소화
→ 자동화된 인사이트
→ 모바일 친화적
→ 오프라인 사용용 정적 스크린샷

### 시나리오 2: "기존 대시보드 개선"
→ 현재 사용 현황 감사
→ 사용자 인터뷰
→ 통증 포인트 파악
→ 단순화, 추가하지 않기
→ 변경사항 A/B 테스트

### 시나리오 3: "셀프 서비스 분석 대시보드"
→ 유연한 필터
→ 내보내기 기능
→ 저장된 보기
→ 드릴다운
→ 포괄적인 설명서

### 시나리오 4: "일일 사용을 위한 운영 대시보드"
→ 실시간 데이터
→ 이상 현상 알림
→ 빠른 로드 시간
→ 모바일 최적화
→ 오프라인 기능

## 누락된 컨텍스트 처리(Handling Missing Context)

**사용자가 "모든 것"을 원하는 경우:**
"우선순위를 정해봅시다:
- #1 답할 질문이 무엇인가요?
- 먼저 무엇을 확인하시나요?
- 무엇이 의사결정을 주도하나요?
MVP로 시작, 반복하세요."

**사용자가 불명확한 경우:**
"다양한 사용자는 다양한 대시보드가 필요합니다:
- 임원진: 고급, 전략적
- 관리자: 팀 성과
- 개별 기여자(ICs): 개인 메트릭, 상세사항
주 대상은 누구인가요?"

**데이터 모델이 없는 경우:**
"데이터 구조를 설계하는 데 도움을 드리겠습니다:
- 어떤 팩트를 측정하나요?
- 슬라이싱할 어떤 차원이 있나요?
- 어떤 세분화 수준이 필요한가요?
그런 다음 이용 가능한 데이터에 매핑합니다."

## 고급 옵션(Advanced Options)

**대시보드 생성기**: 사양에서 자동 생성

**사용 분석(Usage Analytics)**: 사용자가 실제로 보는 것을 추적

**점진적 개선(Progressive Enhancement)**: 단순하게 시작, 사용법에 따라 추가

**A/B 테스트**: 레이아웃 변형 테스트

**개인화(Personalization)**: 사용자별 맞춤 보기
