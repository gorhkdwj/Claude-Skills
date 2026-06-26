---
name: root-cause-investigation
description: 지표 변화 및 이상치를 체계적으로 조사합니다. 지표가 예상치 않게 변경되거나, 비즈니스 지표 감소를 조사하거나, 성능 변동을 설명하거나, 집계된 지표 동인을 분석할 때 사용합니다. | Systematic investigation of metric changes and anomalies. Use when a metric unexpectedly changes, investigating business metric drops, explaining performance variations, or drilling into aggregated metric drivers.
---

# 근본 원인 조사

## Phase
Phase 4 — 분석 수행 (비즈니스 분석 레이어)

## 진입 조건

이 스킬은 **선행 스킬 완료 여부와 무관하게, 지표 이상이 감지된 시점에 언제든 진입할 수 있습니다.**

- EDA 중 이상 패턴 발견 → 즉시 진입 가능
- 비즈니스 지표 대시보드에서 하락 감지 → 데이터 없이 대화로 시작 가능
- stats-basic 결과에서 유의미한 차이 발견 → 원인 탐색 목적으로 진입 가능

아래 Input 파일들은 있으면 분석 품질을 높이지만, 없어도 지표명과 변화 상황만으로 시작할 수 있습니다.

## Input
- 권장 선행 스킬: programmatic-eda, data-quality-audit (선택)
- 참고 파일 (선택): `programmatic-eda_result.csv`, `data-quality-audit_result.csv`, `semantic-model-builder_report.md`, `analysis-assumptions-log_report.md`

## Output
- `root-cause-investigation.ipynb`
- `root-cause-investigation_result.csv`
- `root-cause-investigation_report.md`

## 데이터 로딩

파일 확장자에 따라 적절한 pandas 로더를 사용하세요: `.csv` → `pd.read_csv()`, `.json` → `pd.read_json()`, `.parquet` → `pd.read_parquet()`, `.xlsx/.xls` → `pd.read_excel()`, `.tsv` → `pd.read_csv(sep='\t')`.

## 빠른 시작

지표가 변경된 이유를 체계적으로 조사합니다. 구조화된 드릴다운, 통계 분석 및 가설 검정을 사용하여 근본 원인을 파악하고 실행 가능한 설명을 제공합니다.

## 컨텍스트 요구사항

조사하기 전에 다음이 필요합니다:

1. **지표**: 무엇이 변경되었고 얼마나 변경되었는가
2. **시간 맥락**: 변경이 발생한 시기
3. **역사적 데이터**: 비교를 위한 시간 경과에 따른 지표 값
4. **드릴다운 차원**: 지표를 분할하는 방법 (지리, 제품, 채널 등)
5. **알려진 이벤트(선택사항)**: 제품 변경, 캠페인, 외부 요인

## 컨텍스트 수집

### 지표를 위해:
"Tell me about the metric change you're investigating:

**What metric changed?**
- Example: 'Daily Active Users', 'Revenue', 'Conversion Rate', 'Page Load Time'

**What happened?**
- Dropped from X to Y
- Increased unexpectedly
- Suddenly became volatile
- Plateaued after growing

**When did you notice it?**
- Specific date or date range
- Gradual change or sudden jump?

**How big is the change?**
- Absolute: +/- 1,000 users
- Percentage: -15%
- Is this normal variance or unusual?"

### 역사적 데이터를 위해:
"To understand if this change is unusual, I need historical context:

**Option 1 - Provide Data:**
```
date       | metric_value
2024-12-01 | 10,000
2024-12-02 | 10,200
...
2024-12-15 | 8,500  ← drop happened
```

**Option 2 - Database Query:**
```sql
SELECT date, SUM(metric) as metric_value
FROM metrics_table
WHERE date >= '2024-11-01'
GROUP BY date
ORDER BY date
```

**Option 3 - Dashboard Export:**
Export your dashboard data to CSV

How much history should I analyze? Recommend at least 2-3x the investigation period."

### 드릴다운 차원을 위해:
"To find what's driving the change, which dimensions can we analyze?

**Common Dimensions:**
- **Geographic**: Country, region, city
- **Product**: SKU, category, brand
- **Customer**: Segment, cohort, plan tier
- **Channel**: Organic, paid, email, direct
- **Platform**: Mobile, desktop, iOS, Android
- **Time**: Day of week, hour, season

Which dimensions are available in your data and most likely to reveal insights?"

### 알려진 이벤트를 위해:
"Were there any changes around the time of the metric change?

**Product Changes:**
- New feature launches
- UI/UX changes
- Bug fixes or incidents
- Algorithm updates

**Marketing:**
- Campaign starts/stops
- Budget changes
- New channels

**External:**
- Seasonality
- Competitor actions
- Market events
- Press coverage

Any of these apply?"

### 기본 기대치를 위해:
"What's 'normal' for this metric?

- Historical average
- Expected growth rate
- Acceptable variance range
- Seasonal patterns

This helps determine if the change is truly anomalous."

## 워크플로우

### 1단계: 변경 검증

```python
import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
import seaborn as sns
from scipy import stats
from datetime import datetime, timedelta

# Load historical data
df = pd.read_csv('metric_data.csv')
df['date'] = pd.to_datetime(df['date'])
df = df.sort_values('date')

print(f"📊 Data Loaded:")
print(f"  Date Range: {df['date'].min()} to {df['date'].max()}")
print(f"  Total Days: {len(df)}")

# Define investigation period
investigation_date = '2024-12-15'
baseline_days = 30  # Compare to previous 30 days

investigation_value = df[df['date'] == investigation_date]['metric_value'].values[0]
baseline = df[df['date'] < investigation_date].tail(baseline_days)
baseline_mean = baseline['metric_value'].mean()
baseline_std = baseline['metric_value'].std()

# Calculate change
absolute_change = investigation_value - baseline_mean
percent_change = (absolute_change / baseline_mean) * 100
z_score = (investigation_value - baseline_mean) / baseline_std

print(f"\n🔍 Change Detection:")
print(f"  Investigation Date: {investigation_date}")
print(f"  Current Value: {investigation_value:,.0f}")
print(f"  Baseline (30d avg): {baseline_mean:,.0f}")
print(f"  Change: {absolute_change:+,.0f} ({percent_change:+.1f}%)")
print(f"  Z-Score: {z_score:.2f}")

if abs(z_score) > 2:
    print(f"  ⚠️  SIGNIFICANT: Change is {abs(z_score):.1f} std deviations from normal")
else:
    print(f"  ℹ️  MINOR: Change is within normal variance")
```

**Checkpoint**: "Confirmed the change is real and significant. Ready to investigate root cause?"

### 2단계: 트렌드 시각화

```python
def plot_metric_trend(df, investigation_date, metric_col='metric_value'):
    """Visualize metric over time with investigation date marked"""
    
    fig, ax = plt.subplots(figsize=(14, 6))
    
    # Plot full trend
    ax.plot(df['date'], df[metric_col], marker='o', linewidth=2, markersize=4)
    
    # Mark investigation date
    inv_date = pd.to_datetime(investigation_date)
    ax.axvline(inv_date, color='red', linestyle='--', linewidth=2, label='Investigation Date')
    
    # Add baseline mean line
    baseline = df[df['date'] < inv_date].tail(30)
    ax.axhline(baseline[metric_col].mean(), color='blue', linestyle=':', 
               alpha=0.5, label='30-Day Baseline')
    
    # Highlight unusual period
    unusual = df[df['date'] >= inv_date]
    ax.scatter(unusual['date'], unusual[metric_col], color='red', s=100, zorder=5)
    
    ax.set_xlabel('Date')
    ax.set_ylabel('Metric Value')
    ax.set_title(f'Metric Trend Analysis - Investigation Date: {investigation_date}')
    ax.legend()
    ax.grid(True, alpha=0.3)
    
    plt.xticks(rotation=45)
    plt.tight_layout()
    plt.savefig('metric_trend.png', dpi=300, bbox_inches='tight')
    plt.show()

plot_metric_trend(df, investigation_date)
```

### 3단계: 체계적인 드릴다운

```python
def drill_down_analysis(detailed_df, metric_col, dimension, investigation_date):
    """
    Compare metric by dimension before vs after investigation date
    """
    
    # Split data into before and after
    before = detailed_df[detailed_df['date'] < investigation_date]
    after = detailed_df[detailed_df['date'] >= investigation_date]
    
    # Aggregate by dimension
    before_agg = before.groupby(dimension)[metric_col].mean()
    after_agg = after.groupby(dimension)[metric_col].mean()
    
    # Calculate change
    comparison = pd.DataFrame({
        'before': before_agg,
        'after': after_agg
    })
    comparison['change'] = comparison['after'] - comparison['before']
    comparison['pct_change'] = (comparison['change'] / comparison['before']) * 100
    comparison['contribution'] = comparison['change'].abs()
    
    # Sort by contribution to find biggest drivers
    comparison = comparison.sort_values('contribution', ascending=False)
    
    return comparison

# Load detailed data (with dimensions)
detailed_df = pd.read_csv('detailed_metric_data.csv')
detailed_df['date'] = pd.to_datetime(detailed_df['date'])

# Drill down by each dimension
dimensions = ['country', 'product_category', 'channel', 'device_type']

print("\n🔬 Systematic Drill-Down Analysis:")

for dim in dimensions:
    if dim not in detailed_df.columns:
        continue
    
    print(f"\n{'='*60}")
    print(f"Dimension: {dim.upper()}")
    print('='*60)
    
    analysis = drill_down_analysis(detailed_df, 'metric_value', dim, investigation_date)
    
    # Show top contributors to change
    top_5 = analysis.head(5)
    print(f"\nTop Contributors to Change:")
    for idx, row in top_5.iterrows():
        print(f"\n  {idx}:")
        print(f"    Before: {row['before']:,.0f}")
        print(f"    After:  {row['after']:,.0f}")
        print(f"    Change: {row['change']:+,.0f} ({row['pct_change']:+.1f}%)")
```

### 4단계: 가설 검정

```python
def test_hypotheses(detailed_df, investigation_date):
    """
    Test common hypotheses for metric changes
    """
    
    before = detailed_df[detailed_df['date'] < investigation_date]
    after = detailed_df[detailed_df['date'] >= investigation_date]
    
    hypotheses = []
    
    # Hypothesis 1: Change concentrated in specific segment
    for dim in ['country', 'channel', 'device_type']:
        if dim not in detailed_df.columns:
            continue
            
        before_dist = before.groupby(dim)['metric_value'].sum() / before['metric_value'].sum()
        after_dist = after.groupby(dim)['metric_value'].sum() / after['metric_value'].sum()
        
        # Check if distribution shifted significantly
        max_shift = (after_dist - before_dist).abs().max()
        
        if max_shift > 0.05:  # >5% shift in any segment
            shifted_segment = (after_dist - before_dist).abs().idxmax()
            hypotheses.append({
                'hypothesis': f'Mix shift in {dim}',
                'evidence': f'{shifted_segment} changed by {max_shift*100:.1f}%',
                'strength': 'Strong' if max_shift > 0.10 else 'Moderate'
            })
    
    # Hypothesis 2: Volume drop (fewer total events)
    before_count = len(before)
    after_count = len(after)
    count_change = (after_count - before_count) / before_count
    
    if abs(count_change) > 0.10:
        hypotheses.append({
            'hypothesis': 'Volume change',
            'evidence': f'Event count {count_change:+.1%}',
            'strength': 'Strong' if abs(count_change) > 0.20 else 'Moderate'
        })
    
    # Hypothesis 3: Quality drop (per-unit metric changed)
    if 'user_count' in before.columns:
        before_per_user = before['metric_value'].sum() / before['user_count'].sum()
        after_per_user = after['metric_value'].sum() / after['user_count'].sum()
        per_user_change = (after_per_user - before_per_user) / before_per_user
        
        if abs(per_user_change) > 0.05:
            hypotheses.append({
                'hypothesis': 'Per-user metric changed',
                'evidence': f'Metric per user {per_user_change:+.1%}',
                'strength': 'Strong' if abs(per_user_change) > 0.15 else 'Moderate'
            })
    
    return hypotheses

hypotheses = test_hypotheses(detailed_df, investigation_date)

print(f"\n🧪 Hypothesis Testing Results:")
for i, hyp in enumerate(hypotheses, 1):
    print(f"\n  {i}. {hyp['hypothesis']} [{hyp['strength']}]")
    print(f"     Evidence: {hyp['evidence']}")
```

### 5단계: 상관 분석

```python
def find_correlations(df, metric_col, investigation_date):
    """
    Find what else changed around the same time
    """
    
    # Look for other metrics that changed
    numeric_cols = df.select_dtypes(include=[np.number]).columns
    
    correlations = []
    
    for col in numeric_cols:
        if col == metric_col:
            continue
            
        # Calculate change in this metric
        before = df[df['date'] < investigation_date][col].mean()
        after = df[df['date'] >= investigation_date][col].mean()
        change = (after - before) / before if before != 0 else 0
        
        if abs(change) > 0.05:  # Changed by more than 5%
            # Calculate correlation with target metric
            corr = df[metric_col].corr(df[col])
            
            correlations.append({
                'metric': col,
                'change': change,
                'correlation': corr
            })
    
    # Sort by absolute correlation
    correlations = sorted(correlations, key=lambda x: abs(x['correlation']), reverse=True)
    
    return correlations[:5]  # Top 5

correlated_metrics = find_correlations(detailed_df, 'metric_value', investigation_date)

print(f"\n📈 Correlated Metrics That Also Changed:")
for metric in correlated_metrics:
    print(f"\n  {metric['metric']}:")
    print(f"    Changed: {metric['change']:+.1%}")
    print(f"    Correlation: {metric['correlation']:.2f}")
```

### 6단계: 근본 원인 파악

```python
def synthesize_root_cause(drill_down_results, hypotheses, correlations):
    """
    Synthesize findings into root cause explanation
    """
    
    print(f"\n{'='*60}")
    print("🎯 ROOT CAUSE ANALYSIS")
    print('='*60)
    
    # Find the dimension with biggest contribution
    biggest_contributor = None
    biggest_impact = 0
    
    for dim, results in drill_down_results.items():
        top_impact = results['contribution'].iloc[0]
        if top_impact > biggest_impact:
            biggest_impact = top_impact
            biggest_contributor = (dim, results.index[0], results.iloc[0])
    
    if biggest_contributor:
        dim, segment, data = biggest_contributor
        print(f"\n PRIMARY DRIVER:")
        print(f"   Dimension: {dim}")
        print(f"   Segment: {segment}")
        print(f"   Impact: {data['change']:+,.0f} ({data['pct_change']:+.1f}%)")
        print(f"   This explains {biggest_impact / abs(absolute_change) * 100:.0f}% of total change")
    
    # Summarize hypotheses
    strong_hypotheses = [h for h in hypotheses if h['strength'] == 'Strong']
    if strong_hypotheses:
        print(f"\n SUPPORTING EVIDENCE:")
        for hyp in strong_hypotheses:
            print(f"   ✓ {hyp['hypothesis']}: {hyp['evidence']}")
    
    # Highlight correlations
    if correlations:
        print(f"\n RELATED CHANGES:")
        for metric in correlations[:3]:
            print(f"   • {metric['metric']}: {metric['change']:+.1%}")
    
    return {
        'primary_driver': biggest_contributor,
        'supporting_hypotheses': strong_hypotheses,
        'correlations': correlations
    }

# Collect drill-down results
drill_down_results = {}
for dim in dimensions:
    if dim in detailed_df.columns:
        drill_down_results[dim] = drill_down_analysis(
            detailed_df, 'metric_value', dim, investigation_date
        )

root_cause = synthesize_root_cause(drill_down_results, hypotheses, correlated_metrics)
```

### 7단계: 조사 보고서 생성

```python
def generate_investigation_report(
    metric_name, 
    investigation_date,
    baseline_mean,
    investigation_value,
    absolute_change,
    percent_change,
    root_cause,
    known_events=None
):
    """Create comprehensive investigation report"""
    
    report = []
    report.append("=" * 70)
    report.append(f"ROOT CAUSE INVESTIGATION: {metric_name}")
    report.append("=" * 70)
    report.append(f"\nDate: {investigation_date}")
    report.append(f"Analyst: [Your Name]")
    report.append(f"Generated: {datetime.now().strftime('%Y-%m-%d %H:%M')}")
    
    report.append(f"\n{'='*70}")
    report.append("WHAT HAPPENED")
    report.append("=" * 70)
    report.append(f"\n{metric_name} changed significantly on {investigation_date}:")
    report.append(f"  • Previous 30-day average: {baseline_mean:,.0f}")
    report.append(f"  • Value on {investigation_date}: {investigation_value:,.0f}")
    report.append(f"  • Change: {absolute_change:+,.0f} ({percent_change:+.1f}%)")
    
    if root_cause['primary_driver']:
        dim, segment, data = root_cause['primary_driver']
        report.append(f"\n{'='*70}")
        report.append("ROOT CAUSE")
        report.append("=" * 70)
        report.append(f"\nPrimary Driver: {segment} ({dim})")
        report.append(f"  • Before: {data['before']:,.0f}")
        report.append(f"  • After: {data['after']:,.0f}")
        report.append(f"  • Impact: {data['change']:+,.0f} ({data['pct_change']:+.1f}%)")
    
    if root_cause['supporting_hypotheses']:
        report.append(f"\nSupporting Evidence:")
        for hyp in root_cause['supporting_hypotheses']:
            report.append(f"  • {hyp['hypothesis']}: {hyp['evidence']}")
    
    if known_events:
        report.append(f"\n{'='*70}")
        report.append("KNOWN EVENTS")
        report.append("=" * 70)
        for event in known_events:
            report.append(f"  • {event['date']}: {event['description']}")
    
    report.append(f"\n{'='*70}")
    report.append("RECOMMENDATIONS")
    report.append("=" * 70)
    report.append("\n1. [Specific action based on root cause]")
    report.append("2. [Monitoring recommendation]")
    report.append("3. [Prevention strategy]")
    
    report.append(f"\n{'='*70}")
    report.append("APPENDIX")
    report.append("=" * 70)
    report.append("\nFiles Generated:")
    report.append("  • metric_trend.png - Visual timeline")
    report.append("  • drill_down_analysis.csv - Detailed breakdowns")
    report.append("  • investigation_data.csv - Raw data used")
    
    return "\n".join(report)

report_text = generate_investigation_report(
    metric_name="Daily Active Users",
    investigation_date=investigation_date,
    baseline_mean=baseline_mean,
    investigation_value=investigation_value,
    absolute_change=absolute_change,
    percent_change=percent_change,
    root_cause=root_cause,
    known_events=[
        {'date': '2024-12-14', 'description': 'New app version released'},
        {'date': '2024-12-15', 'description': 'Bug reported in Android app'}
    ]
)

print(report_text)

# Save report
with open('root_cause_investigation_report.txt', 'w') as f:
    f.write(report_text)
```

## 컨텍스트 검증

진행하기 전에 확인하세요:
- [ ] 충분한 역사적 데이터 보유 (최소 조사 기간의 2배)
- [ ] 지표 정의가 시간 기간 전체에서 일관성 있음
- [ ] 드릴다운 차원을 사용 가능하고 신뢰할 수 있음
- [ ] 비즈니스 맥락과 최근 변경사항 이해
- [ ] 필요한 경우 깊이 있는 분석을 위해 세분화된 데이터 접근 가능

## 출력 템플릿

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
근본 원인 조사
Metric: Daily Active Users (DAU)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

📅 Investigation Date: December 15, 2024
📊 Change Detected: -15% drop (25,000 → 21,250)

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🎯 ROOT CAUSE IDENTIFIED
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

PRIMARY DRIVER: Android Mobile App (Platform)
  Before: 12,000 users
  After: 8,000 users  
  Impact: -4,000 users (-33%)
  
This explains 107% of total drop (other segments up slightly)

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📊 DRILL-DOWN ANALYSIS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

By Platform:
  ✅ Desktop: +500 (+5%)
  ✅ iOS: +200 (+3%)
  🔴 Android: -4,000 (-33%)  ← Problem
  ✅ Web Mobile: +100 (+2%)

By Geography:
  ✅ US: +100
  ✅ UK: +50
  ✅ All regions stable (no geographic concentration)

By User Cohort:
  ✅ New users: Stable
  🔴 Returning users: -4,200 (driven by Android)

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🧪 HYPOTHESIS TESTING
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

✅ CONFIRMED: Platform-specific issue
   Evidence: Only Android affected

✅ CONFIRMED: Affects existing users
   Evidence: New user acquisition stable

❌ REJECTED: Marketing/Channel issue
   Evidence: All channels show Android drop

❌ REJECTED: Geographic issue
   Evidence: Uniform across all regions

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📈 CORRELATED CHANGES
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

• Android crash rate: +450% (correlation: -0.85)
• App store rating: -0.5 stars (correlation: -0.62)
• Support tickets: +120% (correlation: -0.71)

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🔍 TIMELINE CORRELATION
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Dec 14, 10:00 PM: Android app v3.2.0 released
Dec 15, 12:00 AM: First crash reports
Dec 15, 8:00 AM: DAU drop visible
Dec 15, 10:00 AM: Bug ticket filed (#4523)

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
💡 ROOT CAUSE CONCLUSION
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

The 15% DAU drop was caused by Android app version 3.2.0
crash on launch, affecting existing users. Bug prevents
app from loading, causing immediate 33% drop in Android
DAU. Other platforms unaffected.

Confidence: 95%

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🎯 RECOMMENDATIONS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

IMMEDIATE (Today):
1. Roll back Android app to v3.1.9
2. Halt v3.2.0 rollout
3. Notify users via email about temporary fix

SHORT-TERM (This Week):
4. Root cause bug in v3.2.0 code
5. Add crash detection to pre-release testing
6. Implement gradual rollout (10% → 50% → 100%)

LONG-TERM (This Month):
7. Set up automated alerting for platform-specific drops
8. Improve QA process for mobile releases
9. Create rollback playbook

EXPECTED RECOVERY:
- Rollback deployed: +3,000 users within 24h
- Full recovery: 3-5 days as users update
- Estimated user loss: 5% churn from bad experience

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📁 SUPPORTING FILES
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

✓ metric_trend.png (timeline visualization)
✓ drill_down_analysis.csv (full breakdown)
✓ hypothesis_testing.csv (test results)
✓ crash_logs.txt (Android error logs)
```

## 일반적인 시나리오

### Scenario 1: "Conversion rate suddenly dropped"
→ Validate drop is real vs noise
→ Drill down by funnel step to find which step broke
→ Analyze by traffic source, device, geography
→ Check for recent product/site changes
→ Identify technical issue or user experience problem

### Scenario 2: "Revenue is down but we don't know why"
→ Decompose revenue = volume × price × mix
→ Determine if it's fewer customers, lower spending, or different product mix
→ Drill down by customer segment and product category
→ Compare to seasonal patterns
→ Identify specific segment driving the decline

### Scenario 3: "Metric improved but team doesn't trust it"
→ Validate improvement is real (not data bug)
→ Determine what actually changed
→ Connect to known initiatives or changes
→ Rule out technical explanations (logging bug, etc.)
→ Provide evidence-based explanation

### Scenario 4: "Weekly metric is volatile, hard to understand"
→ Separate signal from noise with statistics
→ Identify if volatility is new or normal
→ Find patterns (day of week effects, etc.)
→ Recommend smoothing or better baseline
→ Set up proper thresholds for alerting

### Scenario 5: "Metric plateaued after growing steadily"
→ Identify when growth rate changed
→ Check if it's saturation (hitting ceiling)
→ Analyze if new user growth slowed or retention dropped
→ Compare to market benchmarks
→ Provide strategic recommendations

## 누락된 컨텍스트 처리

**User reports "metric dropped" without specifics:**
"Let me help investigate. I need:
1. What's the specific metric?
2. What time period are you comparing?
3. Do you have historical data I can analyze?
4. What dimensions can we drill down by?"

**User doesn't know what dimensions to analyze:**
"Let me examine the data to see what's available. Common patterns:
- Geographic (country, region)
- Platform (mobile/desktop, iOS/Android)
- Source (organic, paid, channels)
- Customer (new vs returning, segments)

Which of these are in your data?"

**User suspects a cause but isn't sure:**
"Great hypothesis! Let's test it systematically:
1. I'll compare the suspected segment to others
2. Check if timing aligns
3. Look for counter-evidence
4. Quantify the impact

What's your hypothesis?"

**Incomplete historical data:**
"I can work with what you have. If data is limited, I'll:
- Use shorter comparison periods
- Focus on largest changes
- Note limitations in conclusions
- Recommend data to collect going forward"

## 고급 옵션

기본 조사 후 제안할 사항:

**Statistical Significance Testing**:
"Want me to calculate if this change is statistically significant vs random variance?"

**Decomposition Analysis**:
"I can break down the metric mathematically (e.g., revenue = users × avg order value × frequency)"

**Synthetic Control**:
"I can create a 'what if nothing changed' baseline using historical patterns"

**Anomaly Detection**:
"I can build a model to automatically detect future anomalies in this metric"

**Impact Quantification**:
"Want me to estimate the business impact in $ or user terms?"

**Prevention Playbook**:
"I can create monitoring alerts and investigation runbooks to catch this faster next time"
