---
name: metric-reconciliation
description: 교차 소스 메트릭 검증 및 차이 조사. 다양한 소스의 메트릭이 일치하지 않거나, 시스템 간 데이터 품질 문제를 조사하거나, 데이터 마이그레이션 정확성을 검증할 때 사용하세요. | Cross-source metric validation and discrepancy investigation. Use when metrics from different sources don't match, investigating data quality issues between systems, or validating data migration accuracy.
---

# Metric Reconciliation

## Phase
Phase 2 — 데이터 이해

## Input
- 이전 스킬: data-quality-audit
- 받는 파일: `data-quality-audit_result.csv`

## Output
- `metric-reconciliation.ipynb`
- `metric-reconciliation_result.csv`
- `metric-reconciliation_report.md`

## 데이터 로딩

파일 확장자에 따라 적절한 pandas 로더를 사용하세요: `.csv` → `pd.read_csv()`, `.json` → `pd.read_json()`, `.parquet` → `pd.read_parquet()`, `.xlsx/.xls` → `pd.read_excel()`, `.tsv` → `pd.read_csv(sep='\t')`.

## 빠른 시작

다양한 데이터 소스에서 메트릭을 체계적으로 비교하고, 차이를 식별하고, 근본 원인을 조사하고, 실행 가능한 수정 사항이 있는 조정 보고서를 생성합니다.

## 필요한 컨텍스트

메트릭을 조정하기 전에 다음이 필요합니다:

1. **데이터 소스**: 비교할 2개 이상의 시스템/데이터셋
2. **메트릭 정의**: 각 소스가 메트릭을 계산하는 방식
3. **예상 분산**: 허용 가능한 차이 vs 우려스러운 차이
4. **시간 범위**: 조정할 날짜 범위
5. **조인 키**: 소스 간 레코드를 일치시키는 방법

## 컨텍스트 수집

### 데이터 소스의 경우:
"각 소스의 데이터에 접근해야 합니다. 다음을 제공해주세요:

**소스 1** (예: 프로덕션 데이터베이스):
- 연결 세부 정보 또는 CSV 내보내기 또는 데이터를 가져오는 SQL 쿼리
- 시스템 이름: 'Postgres Production DB'
- 메트릭: 'Total Revenue'

**소스 2** (예: Analytics Warehouse):
- 연결 세부 정보 또는 CSV 내보내기 또는 데이터를 가져오는 SQL 쿼리
- 시스템 이름: 'Snowflake Analytics'
- 메트릭: 'Total Revenue'

**추가 소스** (3개 이상 시스템 비교하는 경우):
- 각 추가 소스에 대해 동일한 정보

각 소스의 데이터 내보내기 또는 연결 세부 정보를 제공할 수 있나요?"

### 메트릭 정의의 경우:
"메트릭이 다를 수 있는 이유를 이해하려면 다음이 필요합니다:

**메트릭이 각 소스에서 어떻게 계산되나요?**

'총 수익'의 예:
- **소스 1 (프로덕션)**: `SUM(orders.total_amount) WHERE status = 'completed'`
- **소스 2 (Analytics)**: `SUM(daily_revenue.amount) WHERE type = 'sale'`

**알려진 계산 차이:**
- 소스 1이 환불을 포함하나요? (예/아니요)
- 소스 2가 특정 거래 유형을 제외하나요? (어느 것들?)
- 다른 시간대? (UTC vs EST)
- 다른 세분화? (거래 수준 vs 일일 집계)

이것을 이해하면 예상되는 차이 vs 예상치 못한 차이를 식별하는 데 도움이 됩니다."

### 예상 분산의 경우:
"조사하기 전에 허용 가능한 분산은 얼마인가요?

**일반적인 임계값:**
- **재정 메트릭** (수익, 지불): <0.1% 분산 허용
- **사용자 메트릭** (가입, 세션): <2% 분산 허용
- **행동 메트릭** (클릭, 조회): <5% 분산 허용

당신의 메트릭에 대해 어떤 % 차이가 조사를 촉발할까요?

또한:
- 일부 기간이 다를 것으로 예상되나요? (최근 데이터 아직 동기화 중?)
- 소스 간 알려진 지연? (예: 데이터 웨어하우스 매일 업데이트)"

### 시간 범위의 경우:
"어떤 시간 범위를 조정해야 하나요?

**옵션:**
- **특정 날짜**: '2024-12-01' ~ '2024-12-31'
- **최근 N일**: 최근 7일, 최근 30일
- **상대 기간**: 지난 달, 지난 분기
- **전체 시간**: 전체 역사적 비교

참고: 더 긴 기간은 시간이 더 걸릴 수 있지만 분산의 추세를 보여줍니다."

### 조인 키의 경우:
"소스 간 레코드를 어떻게 일치시켜야 하나요?

**일반적인 조인 전략:**

1. **집계 비교** (가장 간단):
   - 합계만 비교
   - 예: 소스 1 vs 소스 2의 총 수익

2. **시간 기반 비교**:
   - 날짜/시간/분 단위로 일치
   - 예: 소스 1 vs 소스 2의 일일 수익

3. **엔티티 기반 비교**:
   - 거래 ID, 주문 ID, 고객 ID로 일치
   - 예: 두 시스템의 주문 #12345

4. **다중 키 비교**:
   - 날짜 + 엔티티로 일치
   - 예: 2024-12-15의 고객 X의 수익

어느 접근 방식이 당신의 사용 사례에 적합할까요?"

## 워크플로우

### Step 1: 각 소스에서 데이터 로드

```python
import pandas as pd
import numpy as np
from datetime import datetime, timedelta

# 소스 1 로드
if source1_type == 'database':
    source1_df = pd.read_sql(source1_query, source1_connection)
elif source1_type == 'csv':
    source1_df = pd.read_csv(source1_file)

# 소스 2 로드
if source2_type == 'database':
    source2_df = pd.read_sql(source2_query, source2_connection)
elif source2_type == 'csv':
    source2_df = pd.read_csv(source2_file)

print(f"📊 Data Loaded:")
print(f"  Source 1 ({source1_name}): {len(source1_df):,} records")
print(f"  Source 2 ({source2_name}): {len(source2_df):,} records")
```

**체크포인트**: "데이터가 성공적으로 로드되었습니다. 레코드 수가 합리적으로 보이나요?"

### Step 2: 데이터 형식 표준화

```python
def standardize_data(df, date_col, metric_col, source_name):
    """비교를 위한 데이터 형식 표준화"""

    # 날짜를 datetime으로 변환
    df[date_col] = pd.to_datetime(df[date_col])

    # 메트릭이 숫자인지 확인
    df[metric_col] = pd.to_numeric(df[metric_col], errors='coerce')

    # null 제거
    original_count = len(df)
    df = df.dropna(subset=[date_col, metric_col])
    dropped = original_count - len(df)

    if dropped > 0:
        print(f"⚠️  {source_name}: Dropped {dropped} records with null date/metric")

    # 소스 식별자 추가
    df['source'] = source_name

    return df

source1_df = standardize_data(source1_df, 'date', 'revenue', 'Source1')
source2_df = standardize_data(source2_df, 'date', 'revenue', 'Source2')
```

### Step 3: 비교 수준에서 집계

```python
# 날짜별로 집계 (또는 사용 중인 모든 조인 키)
source1_agg = source1_df.groupby('date')['revenue'].sum().reset_index()
source1_agg.columns = ['date', 'source1_revenue']

source2_agg = source2_df.groupby('date')['revenue'].sum().reset_index()
source2_agg.columns = ['date', 'source2_revenue']

print(f"\n📈 Aggregated Data:")
print(f"  Source 1: {len(source1_agg)} date periods")
print(f"  Source 2: {len(source2_agg)} date periods")
```

### Step 4: 조인 및 비교

```python
# 한 소스에는 있지만 다른 소스에는 없는 레코드를 잡기 위해 전체 외부 조인
comparison = source1_agg.merge(source2_agg, on='date', how='outer')

# 누락된 날짜는 0으로 채우기
comparison['source1_revenue'] = comparison['source1_revenue'].fillna(0)
comparison['source2_revenue'] = comparison['source2_revenue'].fillna(0)

# 차이 계산
comparison['difference'] = comparison['source1_revenue'] - comparison['source2_revenue']
comparison['abs_difference'] = comparison['difference'].abs()
comparison['pct_difference'] = (
    (comparison['difference'] / comparison['source1_revenue'].replace(0, np.nan)) * 100
).fillna(0)

# 날짜로 정렬
comparison = comparison.sort_values('date')

print(f"\n🔍 Comparison Summary:")
print(f"  Total periods compared: {len(comparison)}")
print(f"  Perfect matches: {(comparison['difference'] == 0).sum()}")
print(f"  Discrepancies: {(comparison['difference'] != 0).sum()}")
```

### Step 5: 차이 분석

```python
def analyze_discrepancies(comparison, threshold_pct=2.0):
    """차이 식별 및 분류"""

    # 심각도별 분류
    comparison['status'] = 'MATCH'
    comparison.loc[comparison['abs_difference'] > 0, 'status'] = 'MINOR'
    comparison.loc[comparison['pct_difference'].abs() > threshold_pct, 'status'] = 'SIGNIFICANT'

    # 통계
    stats = {
        'total_source1': comparison['source1_revenue'].sum(),
        'total_source2': comparison['source2_revenue'].sum(),
        'total_difference': comparison['difference'].sum(),
        'total_pct_diff': (comparison['difference'].sum() /
                          comparison['source1_revenue'].sum() * 100),
        'periods_matched': (comparison['status'] == 'MATCH').sum(),
        'periods_minor': (comparison['status'] == 'MINOR').sum(),
        'periods_significant': (comparison['status'] == 'SIGNIFICANT').sum(),
        'max_abs_diff': comparison['abs_difference'].max(),
        'avg_abs_diff': comparison['abs_difference'].mean()
    }

    return stats

stats = analyze_discrepancies(comparison, threshold_pct=2.0)

print(f"\n📊 Reconciliation Statistics:")
print(f"  Source 1 Total: ${stats['total_source1']:,.2f}")
print(f"  Source 2 Total: ${stats['total_source2']:,.2f}")
print(f"  Difference: ${stats['total_difference']:,.2f} ({stats['total_pct_diff']:.2f}%)")
print(f"\n  Perfect Matches: {stats['periods_matched']}")
print(f"  Minor Variances: {stats['periods_minor']}")
print(f"  Significant Variances: {stats['periods_significant']}")
```

### Step 6: 근본 원인 조사

```python
# 가장 큰 차이 찾기
worst_discrepancies = comparison.nlargest(10, 'abs_difference')

print(f"\n🔍 Top 10 Largest Discrepancies:")
for _, row in worst_discrepancies.iterrows():
    print(f"\n  Date: {row['date'].strftime('%Y-%m-%d')}")
    print(f"    Source 1: ${row['source1_revenue']:,.2f}")
    print(f"    Source 2: ${row['source2_revenue']:,.2f}")
    print(f"    Difference: ${row['difference']:,.2f} ({row['pct_difference']:.1f}%)")

# 패턴 조사
print(f"\n📈 Patterns:")

# 차이가 시간 경과에 따라 추세가 있는지 확인
comparison['month'] = pd.to_datetime(comparison['date']).dt.to_period('M')
monthly_variance = comparison.groupby('month')['pct_difference'].mean()

improving = monthly_variance.iloc[-3:].mean() < monthly_variance.iloc[:3].mean()
print(f"  Variance trend: {'Improving' if improving else 'Worsening'}")

# 체계적 편향이 있는지 확인
bias = "Source 1 consistently higher" if stats['total_difference'] > 0 else "Source 2 consistently higher"
print(f"  Systematic bias: {bias}")

# 요일별로 확인
comparison['day_of_week'] = pd.to_datetime(comparison['date']).dt.day_name()
dow_variance = comparison.groupby('day_of_week')['abs_difference'].mean()
worst_day = dow_variance.idxmax()
print(f"  Worst day of week: {worst_day}")
```

### Step 7: 특정 차이에 대해 더 파고들기

```python
def investigate_specific_date(date, source1_df, source2_df):
    """특정 날짜의 차이를 파고들기"""

    # 해당 날짜로 필터링
    s1_detail = source1_df[source1_df['date'] == date]
    s2_detail = source2_df[source2_df['date'] == date]

    print(f"\n🔬 Detailed Investigation: {date}")
    print(f"\n  Source 1:")
    print(f"    Records: {len(s1_detail)}")
    print(f"    Total: ${s1_detail['revenue'].sum():,.2f}")
    print(f"    Sample transactions:")
    print(s1_detail[['transaction_id', 'revenue', 'status']].head())

    print(f"\n  Source 2:")
    print(f"    Records: {len(s2_detail)}")
    print(f"    Total: ${s2_detail['revenue'].sum():,.2f}")
    print(f"    Sample transactions:")
    print(s2_detail[['transaction_id', 'revenue', 'status']].head())

    # 누락된 거래 찾기
    s1_ids = set(s1_detail['transaction_id'])
    s2_ids = set(s2_detail['transaction_id'])

    missing_in_s2 = s1_ids - s2_ids
    missing_in_s1 = s2_ids - s1_ids

    if missing_in_s2:
        print(f"\n  ⚠️  In Source 1 but not Source 2: {len(missing_in_s2)} transactions")
        print(f"    Total value: ${s1_detail[s1_detail['transaction_id'].isin(missing_in_s2)]['revenue'].sum():,.2f}")

    if missing_in_s1:
        print(f"\n  ⚠️  In Source 2 but not Source 1: {len(missing_in_s1)} transactions")
        print(f"    Total value: ${s2_detail[s2_detail['transaction_id'].isin(missing_in_s1)]['revenue'].sum():,.2f}")

# 가장 큰 차이를 조사
worst_date = worst_discrepancies.iloc[0]['date']
investigate_specific_date(worst_date, source1_df, source2_df)
```

### Step 8: 조정 보고서 생성

```python
def generate_reconciliation_report(comparison, stats):
    """포괄적인 조정 보고서 생성"""

    report = []
    report.append("=" * 60)
    report.append("METRIC RECONCILIATION REPORT")
    report.append("=" * 60)
    report.append(f"\nGenerated: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
    report.append(f"Period: {comparison['date'].min()} to {comparison['date'].max()}")
    report.append(f"\n{'Source 1':20} ${stats['total_source1']:>15,.2f}")
    report.append(f"{'Source 2':20} ${stats['total_source2']:>15,.2f}")
    report.append(f"{'-'*40}")
    report.append(f"{'Difference':20} ${stats['total_difference']:>15,.2f}")
    report.append(f"{'Variance %':20} {stats['total_pct_diff']:>14.2f}%")

    report.append(f"\n{'='*60}")
    report.append("SUMMARY")
    report.append("=" * 60)
    report.append(f"  Perfect Matches: {stats['periods_matched']}")
    report.append(f"  Minor Variances: {stats['periods_minor']}")
    report.append(f"  Significant Variances: {stats['periods_significant']}")
    report.append(f"  Average Daily Variance: ${stats['avg_abs_diff']:,.2f}")
    report.append(f"  Maximum Daily Variance: ${stats['max_abs_diff']:,.2f}")

    report.append(f"\n{'='*60}")
    report.append("TOP DISCREPANCIES")
    report.append("=" * 60)

    top_10 = comparison.nlargest(10, 'abs_difference')
    for i, row in top_10.iterrows():
        report.append(f"\n{row['date'].strftime('%Y-%m-%d')}:")
        report.append(f"  Source 1: ${row['source1_revenue']:>12,.2f}")
        report.append(f"  Source 2: ${row['source2_revenue']:>12,.2f}")
        report.append(f"  Diff: ${row['difference']:>12,.2f} ({row['pct_difference']:>6.1f}%)")

    return "\n".join(report)

report = generate_reconciliation_report(comparison, stats)
print(report)

# 보고서 저장
with open('reconciliation_report.txt', 'w') as f:
    f.write(report)

# 상세 비교를 CSV로 저장
comparison.to_csv('detailed_comparison.csv', index=False)
```

## 컨텍스트 검증

진행하기 전에 확인하세요:
- [ ] 비교 중인 모든 소스의 데이터에 접근할 수 있습니다
- [ ] 메트릭 정의가 명확하고 문서화되었습니다
- [ ] 허용 가능한 분산과 우려스러운 분산을 알고 있습니다
- [ ] 소스 간 시간 범위가 일치합니다
- [ ] 상세 조정을 하려면 레코드를 일치시킬 고유 식별자가 있습니다

## 출력 템플릿

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
METRIC RECONCILIATION REPORT
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Metric: Total Revenue
Period: 2024-12-01 to 2024-12-31
Generated: 2025-01-11 15:30:00

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
SUMMARY
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Production DB        $1,234,567.89
Analytics DW         $1,229,123.45
────────────────────────────────
Difference           $    5,444.44
Variance %                  0.44%

Status: ✅ WITHIN THRESHOLD (< 2%)

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
BREAKDOWN
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Total Days Compared: 31
  ✅ Perfect Matches: 23 days (74%)
  ⚠️  Minor Variances: 6 days (19%)
  🔴 Significant Variances: 2 days (7%)

Average Daily Variance: $175.63
Maximum Daily Variance: $2,345.67

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
TOP 5 DISCREPANCIES
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

1. 2024-12-15
   Production: $45,678.90
   Analytics:  $43,333.23
   Difference: $2,345.67 (5.1%)

2. 2024-12-22
   Production: $38,901.23
   Analytics:  $37,123.45
   Difference: $1,777.78 (4.6%)

[... continues ...]

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
ROOT CAUSE ANALYSIS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Pattern: Source 1 consistently higher
Likely Causes:
1. Timing: Production DB updated real-time,
   Analytics DW has 2-hour delay
2. Refunds: Production includes, Analytics excludes
3. Missing Data: 15 transactions on 2024-12-15
   present in Production but not in Analytics

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
RECOMMENDATIONS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

IMMEDIATE:
1. Investigate 2024-12-15 missing transactions
2. Document refund handling difference

ONGOING:
3. Set up daily reconciliation alerts
4. Standardize metric definitions across systems

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
FILES GENERATED
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

✓ reconciliation_report.txt
✓ detailed_comparison.csv (daily breakdown)
✓ discrepancies_only.csv (issues for investigation)
```

## 일반적인 시나리오

### Scenario 1: "시스템 간 일일 수익이 일치하지 않습니다"
→ 집계된 일일 수익 비교
→ 차이가 있는 날 식별
→ 특정 날의 차이를 파고들어 누락/추가 거래 찾기
→ 알려진 시간 차이 문서화

### Scenario 2: "마이그레이션 검증 - 이전 시스템 vs 새 시스템"
→ 겹치는 기간 동안 시스템 간 동일 메트릭 비교
→ 거래 ID로 일치시켜 누락/변경된 레코드 찾기
→ 계산 로직이 동일한 결과를 생성하는지 검증
→ 알려진 차이에 대한 매핑 생성

### Scenario 3: "월말 마감을 위한 재정 조정"
→ 총계정원장을 데이터 웨어하우스와 비교
→ 엄격한 임계값 (<0.1% 분산)
→ 모든 차이 조사
→ 감사 추적 문서 생성

### Scenario 4: "대시보드가 보고서와 다른 숫자를 보여주는 이유는?"
→ 각각의 기본 쿼리 비교
→ 필터 차이, 시간 차이 식별
→ 어느 숫자가 "올바른"지와 이유 문서화
→ 잘못된 소스 수정 또는 주석

### Scenario 5: "분기별 비즈니스 검토 - 모든 KPI 검증"
→ 여러 메트릭을 체계적으로 조정
→ 조정 매트릭스 생성 (메트릭 × 소스)
→ 정의 정렬이 필요한 메트릭에 플래그
→ 비즈니스 영향으로 우선 순위 지정

## 누락된 컨텍스트 처리

**사용자가 "숫자가 일치하지 않습니다"라고 구체적 정보 없이 말할 때:**
"조정을 도와드리겠습니다. 다음이 필요합니다:
1. 메트릭이 무엇인가요? (수익, 사용자 수 등)
2. 보는 두 숫자는 뭔가요?
3. 각 숫자가 어디서 나온 건가요? (시스템, 보고서, 대시보드)
4. 어떤 시간 기간인가요?"

**사용자가 메트릭 정의를 모를 때:**
"문제 없습니다. 각 소스의 기본 쿼리/데이터를 추출하고 역으로 메트릭 계산 방식을 파악하겠습니다. 그러면 어디서 분기되는지 볼 수 있습니다."

**사용자가 직접 데이터 접근할 수 없을 때:**
"각 소스에서 데이터를 CSV로 내보낼 수 있나요? 아니면 요약 숫자를 스크린샷할 수 있나요? 사용 가능한 것이면 작업할 수 있습니다."

**거래 수준 데이터 사용 불가:**
"집계 비교만 진행합니다. 이것은 차이의 규모를 보여주지만 특정 누락 거래를 정확히 식별하지는 않습니다."

## 고급 옵션

기본 조정 후 다음을 제시할 수 있습니다:

**자동화된 모니터링**:
"이 조정이 매일 실행되고 분산이 임계값을 초과할 때 알림을 주는 스크립트를 만들고 싶으신가요?"

**다중 소스 조정**:
"3개 이상의 소스를 비교하려면 모든 쌍별 비교를 보여주는 조정 매트릭스를 만들 수 있습니다."

**추세 분석**:
"시간이 지남에 따라 조정을 추적하여 데이터 품질이 개선되고 있는지 악화되고 있는지 보여줄 수 있습니다."

**근본 원인 분류**:
"차이를 가능한 원인(시간 지연, 누락 데이터, 계산 차이 등)별로 분류하여 우선순위를 지정할 수 있습니다."

**문서 생성**:
"팀 참조용 소스 간 알려진 차이의 공식 문서를 만들 수 있습니다."
