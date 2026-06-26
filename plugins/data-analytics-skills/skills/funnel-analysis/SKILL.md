---
name: funnel-analysis
description: 이탈 조사를 포함한 전환 퍼널(Conversion Funnel) 분석을 수행합니다. 다단계 프로세스를 분석하거나, 전환 병목 현상을 식별하거나, 퍼널 성능을 A/B 테스트하거나, 사용자 여정을 최적화할 때 사용합니다. | Conversion funnel analysis with drop-off investigation. Use when analyzing multi-step processes, identifying conversion bottlenecks, A/B testing funnel performance, or optimizing user journeys.
---

# 퍼널 분석

## Phase
Phase 4 — 분석 수행 (비즈니스 분석 레이어)

## Input
- 이전 스킬: programmatic-eda + data-quality-audit + semantic-model-builder + analysis-assumptions-log
- 받는 파일: `programmatic-eda_result.csv` + `data-quality-audit_result.csv` + `semantic-model-builder_report.md` + `analysis-assumptions-log_report.md`

## Output
- `funnel-analysis.ipynb`
- `funnel-analysis_result.csv`
- `funnel-analysis_report.md`

## 데이터 로딩

파일 확장자에 따라 적절한 pandas 로더를 사용하세요: `.csv` → `pd.read_csv()`, `.json` → `pd.read_json()`, `.parquet` → `pd.read_parquet()`, `.xlsx/.xls` → `pd.read_excel()`, `.tsv` → `pd.read_csv(sep='\t')`.

## 빠른 시작

다단계 사용자 여정을 분석하여 전환율을 측정하고, 이탈 지점을 식별하고, 세그먼트를 비교하고, 실행 가능한 인사이트로 퍼널 성능을 최적화합니다.

## 컨텍스트 요구사항

퍼널을 분석하기 전에 다음이 필요합니다:

1. **퍼널 단계**: 사용자가 취하는 일련의 행동
2. **이벤트 데이터**: 각 단계를 완료한 사람을 보여주는 사용자 활동
3. **시간 윈도우**: 사용자가 퍼널을 완료하는 데 걸리는 시간
4. **성공 기준**: 각 단계에서 완료로 간주되는 것
5. **세그먼트(선택사항)**: 비교할 그룹 (예: 채널, 기기, 코호트별)

## 컨텍스트 수집

### 퍼널 단계를 위해:
"Please define the funnel steps in order. For example:

**E-commerce Purchase Funnel:**
1. View Product Page
2. Add to Cart
3. Begin Checkout
4. Enter Payment Info
5. Complete Purchase

**SaaS Onboarding Funnel:**
1. Sign Up
2. Email Verified
3. Complete Profile
4. Invite Team Member
5. First Project Created

What are your funnel steps?"

### 이벤트 데이터를 위해:
"I need data showing which users completed which steps. Provide:

**Option 1 - Event Log:**
```
user_id | event_name        | timestamp
123     | view_product      | 2024-12-15 10:00:00
123     | add_to_cart       | 2024-12-15 10:05:00
123     | begin_checkout    | 2024-12-15 10:10:00
456     | view_product      | 2024-12-15 11:00:00
```

**Option 2 - Pre-aggregated:**
```
user_id | reached_step_1 | reached_step_2 | reached_step_3 |...
123     | TRUE           | TRUE           | TRUE           |...
456     | TRUE           | FALSE          | FALSE          |...
```

**Option 3 - Database Query:**
Share SQL to fetch relevant events

Which format works for you?"

### 시간 윈도우를 위해:
"How long do users have to complete the funnel?

**Common Windows:**
- **Session-based**: Within single session (30 min)
- **Same-day**: Within 24 hours
- **Multi-day**: Within 7 days, 30 days
- **Unlimited**: Any time eventually

What makes sense for your use case?"

### 성공 기준을 위해:
"For each step, what counts as completion?

**Examples:**
- Step 1 (View Product): Page view event
- Step 2 (Add to Cart): Click 'Add to Cart' button
- Step 3 (Checkout): Land on checkout page
- Step 4 (Payment): Submit payment form
- Step 5 (Complete): Order confirmation

Any nuances? (e.g., 'view product for >10 seconds', 'add any item', etc.)"

### 세그먼트를 위해:
"Want to compare funnel performance across groups?

**Common Segments:**
- Acquisition channel (organic, paid, referral)
- Device type (mobile, desktop, tablet)
- User type (new, returning, power user)
- Geographic region
- Product/plan tier
- Time period (weekday vs weekend)

Which segments are most important?"

## 워크플로우

### 1단계: 이벤트 데이터 로드 및 검증

```python
import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
import seaborn as sns
from datetime import datetime, timedelta

# Load event data
events = pd.read_csv('user_events.csv')
events['timestamp'] = pd.to_datetime(events['timestamp'])

# 분석 기간 계산 (ab-test 연결 시 자동 전달)
ANALYSIS_START = events['timestamp'].min()
ANALYSIS_END   = events['timestamp'].max()
ANALYSIS_DAYS  = max((ANALYSIS_END - ANALYSIS_START).days + 1, 1)

print(f"📊 Event Data Loaded:")
print(f"  Total Events: {len(events):,}")
print(f"  Unique Users: {events['user_id'].nunique():,}")
print(f"  Date Range: {ANALYSIS_START.date()} ~ {ANALYSIS_END.date()} ({ANALYSIS_DAYS}일)")
print(f"  Event Types: {events['event_name'].unique()}")
```

**Checkpoint**: "Data loaded. Do the event names match your funnel steps?"

### 2단계: 퍼널 구성 정의

```python
# Define funnel steps in order
funnel_steps = [
    {'step': 1, 'name': 'View Product', 'event': 'view_product'},
    {'step': 2, 'name': 'Add to Cart', 'event': 'add_to_cart'},
    {'step': 3, 'name': 'Begin Checkout', 'event': 'begin_checkout'},
    {'step': 4, 'name': 'Payment Info', 'event': 'enter_payment'},
    {'step': 5, 'name': 'Complete Purchase', 'event': 'purchase_complete'}
]

# Time window for funnel completion (in days)
TIME_WINDOW_DAYS = 7

print("🎯 Funnel Configuration:")
for step in funnel_steps:
    print(f"  Step {step['step']}: {step['name']} ({step['event']})")
print(f"\nTime Window: {TIME_WINDOW_DAYS} days")
```

### 3단계: 퍼널 데이터 구축

```python
def build_funnel_data(events, funnel_steps, time_window_days):
    """
    For each user, determine which funnel steps they reached
    """
    funnel_data = []
    
    # Get users who started the funnel (reached step 1)
    step1_event = funnel_steps[0]['event']
    users_started = events[events['event_name'] == step1_event]['user_id'].unique()
    
    print(f"Building funnel for {len(users_started):,} users...")
    
    for user_id in users_started:
        user_events = events[events['user_id'] == user_id].sort_values('timestamp')
        
        # Find first occurrence of step 1
        step1_events = user_events[user_events['event_name'] == step1_event]
        if len(step1_events) == 0:
            continue
            
        start_time = step1_events.iloc[0]['timestamp']
        end_time = start_time + timedelta(days=time_window_days)
        
        # Check each subsequent step
        user_funnel = {
            'user_id': user_id,
            'start_time': start_time,
            'step_1': True,
            'step_1_time': start_time
        }
        
        for i, step in enumerate(funnel_steps[1:], start=2):
            # Look for this step's event after previous step and within window
            step_events = user_events[
                (user_events['event_name'] == step['event']) &
                (user_events['timestamp'] >= start_time) &
                (user_events['timestamp'] <= end_time)
            ]
            
            if len(step_events) > 0:
                user_funnel[f'step_{i}'] = True
                user_funnel[f'step_{i}_time'] = step_events.iloc[0]['timestamp']
            else:
                user_funnel[f'step_{i}'] = False
                user_funnel[f'step_{i}_time'] = None
                # If they didn't reach this step, they didn't reach later steps
                for j in range(i+1, len(funnel_steps)+1):
                    user_funnel[f'step_{j}'] = False
                    user_funnel[f'step_{j}_time'] = None
                break
        
        funnel_data.append(user_funnel)
    
    return pd.DataFrame(funnel_data)

funnel_df = build_funnel_data(events, funnel_steps, TIME_WINDOW_DAYS)
print(f"✓ Funnel built for {len(funnel_df):,} users")
```

### 4단계: 퍼널 지표 계산

```python
def calculate_funnel_metrics(funnel_df, funnel_steps):
    """Calculate conversion rates and drop-offs"""
    
    metrics = []
    total_users = len(funnel_df)
    
    for i, step in enumerate(funnel_steps, start=1):
        users_reached = funnel_df[f'step_{i}'].sum()
        conversion_from_top = (users_reached / total_users) * 100
        
        if i > 1:
            users_prev_step = funnel_df[f'step_{i-1}'].sum()
            conversion_from_prev = (users_reached / users_prev_step) * 100 if users_prev_step > 0 else 0
            drop_off = users_prev_step - users_reached
            drop_off_rate = ((users_prev_step - users_reached) / users_prev_step) * 100 if users_prev_step > 0 else 0
        else:
            conversion_from_prev = 100.0
            drop_off = 0
            drop_off_rate = 0
        
        metrics.append({
            'step': i,
            'step_name': step['name'],
            'users_reached': int(users_reached),
            'conversion_from_top': conversion_from_top,
            'conversion_from_prev': conversion_from_prev,
            'drop_off': int(drop_off),
            'drop_off_rate': drop_off_rate
        })
    
    return pd.DataFrame(metrics)

funnel_metrics = calculate_funnel_metrics(funnel_df, funnel_steps)

print("\n📊 Funnel Conversion Metrics:\n")
print(funnel_metrics.to_string(index=False))
```

### 5단계: 퍼널 시각화

```python
def plot_funnel(metrics):
    """Create funnel visualization"""
    
    fig, (ax1, ax2) = plt.subplots(1, 2, figsize=(16, 6))
    
    # Funnel chart (absolute numbers)
    ax1.barh(metrics['step_name'], metrics['users_reached'], 
             color=plt.cm.Blues(np.linspace(0.4, 0.8, len(metrics))))
    
    # Add value labels
    for i, (name, users) in enumerate(zip(metrics['step_name'], metrics['users_reached'])):
        ax1.text(users, i, f' {int(users):,}', va='center')
    
    ax1.set_xlabel('Users')
    ax1.set_title('Funnel: Absolute Users per Step')
    ax1.invert_yaxis()
    
    # Conversion rate chart
    colors = ['green' if rate >= 80 else 'orange' if rate >= 60 else 'red' 
              for rate in metrics['conversion_from_prev']]
    
    ax2.barh(metrics['step_name'], metrics['conversion_from_prev'], color=colors)
    
    # Add percentage labels
    for i, (name, rate) in enumerate(zip(metrics['step_name'], metrics['conversion_from_prev'])):
        ax2.text(rate, i, f' {rate:.1f}%', va='center')
    
    ax2.set_xlabel('Conversion Rate (%)')
    ax2.set_title('Step-to-Step Conversion Rate')
    ax2.set_xlim(0, 105)
    ax2.invert_yaxis()
    
    plt.tight_layout()
    plt.savefig('funnel_analysis.png', dpi=300, bbox_inches='tight')
    plt.show()

plot_funnel(funnel_metrics)
```

### 6단계: 이탈 지점 분석

```python
def analyze_drop_offs(metrics):
    """Identify and prioritize drop-off points"""
    
    # Find biggest drop-off by absolute users
    biggest_drop = metrics.loc[metrics['drop_off'].idxmax()]
    
    # Find biggest drop-off by rate
    worst_conversion = metrics.loc[metrics['conversion_from_prev'].idxmin()]
    
    print("\n🔍 Drop-Off Analysis:")
    print(f"\n  Biggest Drop-Off (absolute):")
    print(f"    {biggest_drop['step_name']}")
    print(f"    Lost {biggest_drop['drop_off']:,} users ({biggest_drop['drop_off_rate']:.1f}%)")
    
    print(f"\n  Worst Conversion Rate:")
    print(f"    {worst_conversion['step_name']}")
    print(f"    Only {worst_conversion['conversion_from_prev']:.1f}% converted")
    
    # Categorize steps
    print(f"\n  Step Performance:")
    for _, row in metrics.iterrows():
        if row['step'] == 1:
            continue
        rate = row['conversion_from_prev']
        if rate >= 80:
            status = "✅ GOOD"
        elif rate >= 60:
            status = "⚠️  MODERATE"
        else:
            status = "🔴 POOR"
        print(f"    {status} {row['step_name']}: {rate:.1f}%")

analyze_drop_offs(funnel_metrics)
```

### 7단계: 전환 시간 분석

```python
def analyze_time_to_convert(funnel_df, funnel_steps):
    """Analyze how long users take at each step"""
    
    print("\n⏱️  Time to Convert Analysis:")
    
    for i in range(2, len(funnel_steps) + 1):
        # Calculate time between steps
        time_col = f'step_{i}_time'
        prev_time_col = f'step_{i-1}_time'
        
        converted = funnel_df[funnel_df[f'step_{i}'] == True].copy()
        
        if len(converted) == 0:
            continue
        
        converted['time_diff'] = (converted[time_col] - converted[prev_time_col]).dt.total_seconds() / 60
        
        print(f"\n  {funnel_steps[i-2]['name']} → {funnel_steps[i-1]['name']}:")
        print(f"    Median: {converted['time_diff'].median():.1f} minutes")
        print(f"    P25: {converted['time_diff'].quantile(0.25):.1f} min")
        print(f"    P75: {converted['time_diff'].quantile(0.75):.1f} min")
        print(f"    P95: {converted['time_diff'].quantile(0.95):.1f} min")

analyze_time_to_convert(funnel_df, funnel_steps)
```

### 8단계: 세그먼트 비교

```python
def compare_segments(events, funnel_df, segment_col='channel'):
    """Compare funnel performance across segments"""
    
    # Add segment info to funnel data
    user_segments = events[['user_id', segment_col]].drop_duplicates('user_id')
    funnel_with_segment = funnel_df.merge(user_segments, on='user_id', how='left')
    
    print(f"\n📊 Funnel by {segment_col.title()}:")
    
    segment_metrics = []
    for segment in funnel_with_segment[segment_col].unique():
        segment_data = funnel_with_segment[funnel_with_segment[segment_col] == segment]
        segment_funnel = calculate_funnel_metrics(segment_data, funnel_steps)
        
        # Overall conversion rate (top to bottom)
        overall_conversion = segment_funnel.iloc[-1]['conversion_from_top']
        
        segment_metrics.append({
            'segment': segment,
            'users': len(segment_data),
            'overall_conversion': overall_conversion
        })
        
        print(f"\n  {segment}:")
        print(f"    Users: {len(segment_data):,}")
        print(f"    End-to-End Conversion: {overall_conversion:.1f}%")
        
        # Show biggest drop-off for this segment
        worst = segment_funnel.loc[segment_funnel['conversion_from_prev'].idxmin()]
        print(f"    Worst Step: {worst['step_name']} ({worst['conversion_from_prev']:.1f}%)")
    
    # Compare segments
    segment_comparison = pd.DataFrame(segment_metrics).sort_values('overall_conversion', ascending=False)
    
    print(f"\n  Segment Ranking:")
    for _, row in segment_comparison.iterrows():
        print(f"    {row['segment']}: {row['overall_conversion']:.1f}%")

# Example: Compare by channel
if 'channel' in events.columns:
    compare_segments(events, funnel_df, 'channel')
```

### 9단계: context_packet 저장 (ab-test 연결용)

병목 구간을 A/B 테스트로 검증하려는 경우 실행하세요.
다음 스킬(ab-test-analysis)에서 기존 전환율·트래픽·분석 기간을 **자동 로드**합니다.

```python
import json, os

# 병목 구간 = conversion_from_prev가 가장 낮은 단계 (Step 1 제외)
bottleneck = funnel_metrics[funnel_metrics['step'] > 1].loc[
    funnel_metrics[funnel_metrics['step'] > 1]['conversion_from_prev'].idxmin()
]

packet_path = "context_packet.json"
packet = {}
if os.path.exists(packet_path):
    with open(packet_path) as f:
        packet = json.load(f)

packet["funnel_bottleneck"] = {
    "step_name":            bottleneck["step_name"],
    "baseline_rate":        round(bottleneck["conversion_from_prev"] / 100, 4),
    "total_users_at_step":  int(bottleneck["users_reached"]),   # 분석 기간 전체 합계
    "analysis_period_days": ANALYSIS_DAYS                       # 1단계에서 자동 계산된 값
}

with open(packet_path, "w", encoding="utf-8") as f:
    json.dump(packet, f, ensure_ascii=False, indent=2)

print(f"✅ context_packet 저장 완료")
print(f"   병목 단계     : {bottleneck['step_name']}")
print(f"   기존 전환율   : {bottleneck['conversion_from_prev']:.1f}%")
print(f"   단계 총 진입자: {int(bottleneck['users_reached']):,}명 / {ANALYSIS_DAYS}일")
print(f"   일평균 트래픽 : {int(bottleneck['users_reached']) // ANALYSIS_DAYS:,}명/일")
print(f"\n👉 다음 단계: ab-test-analysis 스킬 → Step 0 (사전 설계 모드)")
```

## 컨텍스트 검증

진행하기 전에 확인하세요:
- [ ] 퍼널 단계가 명확하게 정의되고 올바른 순서로 배열됨
- [ ] 이벤트 데이터에 모든 필요한 단계가 포함됨
- [ ] 시간 윈도우가 사용자 여정에 적합함
- [ ] 각 단계의 성공 기준이 명확함
- [ ] 퍼널을 통해 개인을 추적할 수 있는 사용자 ID 보유

## 출력 템플릿

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
퍼널 분석 보고서
E-commerce Purchase Funnel
Period: Dec 1-31, 2024
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

📊 FUNNEL OVERVIEW
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Total Users Entered: 50,000
Overall Conversion: 12.5% (6,250 purchases)

Step                    Users      Conv%    Drop-Off
──────────────────────────────────────────────────
1. View Product        50,000     100.0%         -
2. Add to Cart         35,000      70.0%    30.0%
3. Begin Checkout      21,000      60.0%    40.0%
4. Payment Info        15,750      75.0%    25.0%
5. Complete Purchase    6,250      39.7%    60.3%

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🔍 KEY FINDINGS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

🔴 CRITICAL DROP-OFF:
   Complete Purchase (Step 5)
   - Only 39.7% complete after entering payment
   - Losing 9,500 users at final step
   - Potential revenue impact: $285,000

⚠️  MODERATE DROP-OFF:
   Begin Checkout (Step 3)
   - 40% abandon cart before checkout
   - Losing 14,000 users

✅ GOOD PERFORMANCE:
   Add to Cart (Step 2): 70% conversion
   Payment Info (Step 4): 75% conversion

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
⏱️  TIME TO CONVERT
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

View → Add to Cart:     Median 2.3 min
Add to Cart → Checkout: Median 8.5 min
Checkout → Payment:     Median 3.1 min
Payment → Complete:     Median 1.2 min

Total Journey: Median 15.1 minutes

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📱 SEGMENT COMPARISON
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

By Device:
  Desktop:  15.2% conversion (30,000 users)
  Mobile:   10.1% conversion (20,000 users)
  
  Gap: Mobile 33% lower conversion
  Worst Mobile Step: Complete Purchase (28% vs 45% desktop)

By Channel:
  Organic:  14.3% conversion
  Paid:     11.8% conversion  
  Email:    16.7% conversion

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
💡 RECOMMENDATIONS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

PRIORITY 1 (High Impact):
1. Investigate payment completion drop-off
   - Review error messages at payment step
   - Check mobile payment UX
   - Consider guest checkout option
   - Potential gain: +3,000 conversions/month

PRIORITY 2 (Medium Impact):
2. Reduce cart abandonment
   - Add save cart feature
   - Send abandonment emails
   - Show trust signals earlier
   - Potential gain: +2,000 conversions/month

PRIORITY 3 (Mobile Optimization):
3. Improve mobile experience
   - Simplify mobile checkout flow
   - Optimize for smaller screens
   - Potential gain: +1,000 conversions/month

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📁 FILES GENERATED
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

✓ funnel_analysis.png (visualization)
✓ funnel_metrics.csv (detailed metrics)
✓ user_journeys.csv (individual user paths)
✓ segment_comparison.csv (breakdown by segment)

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🔗 다음 단계 권장
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

병목 구간 발견 시 → ab-test-analysis
  주요 병목: Complete Purchase (39.7%)
  context_packet.json에 병목 정보 저장 완료
  → ab-test Step 0에서 자동 로드하여
    필요 샘플 수 · 실험 기간 즉시 계산 가능
```

## 일반적인 시나리오

### Scenario 1: "Why is our signup funnel performing poorly?"
→ Build funnel from landing → signup → activation
→ Identify biggest drop-off step
→ Compare segments (source, device, etc.)
→ Analyze time-to-convert at each step
→ Provide specific recommendations

### Scenario 2: "Mobile conversion is lower than desktop"
→ Run funnel analysis separately for each device
→ Identify which step(s) mobile underperforms
→ Compare time-to-convert (mobile users slower?)
→ Highlight specific mobile UX issues

### Scenario 3: "Test if new checkout flow improved conversion"
→ Compare funnel before/after change
→ Calculate statistical significance of difference
→ Show which specific steps improved
→ Measure overall impact

### Scenario 4: "Optimize onboarding for different user types"
→ Segment by user type (free, trial, paid)
→ Build separate funnels for each
→ Identify where each segment drops off
→ Create targeted interventions

### Scenario 5: "Track funnel performance over time"
→ Calculate weekly/monthly funnel metrics
→ Show trend in conversion rates
→ Flag when performance degrades
→ Correlate with product changes

## 누락된 컨텍스트 처리

**User says "analyze our funnel" without defining steps:**
"I can help! First, what's the user journey you want to analyze? Example: Landing page → Signup → Onboarding → Activation. What are your steps?"

**User doesn't know time window:**
"Let me analyze the data to see typical completion times, then we can decide on an appropriate window. Most users complete within X days."

**Event data is messy:**
"I see multiple event names that might represent the same step. Let me map them:
- 'view_product', 'product_page' → Step 1?
- 'add_cart', 'added_to_cart' → Step 2?
Does this look right?"

**User wants to compare many segments:**
"I can analyze all segments, but let's prioritize. Which 2-3 segments matter most for decision-making?"

## 고급 옵션

기본 퍼널 분석 후 제안할 사항:

**Cohort-Based Funnels**:
"Want to see how funnel performance changes over time? I can show conversion rates by signup cohort."

**Micro-Conversion Analysis**:
"I can break down each major step into micro-steps to find exactly where users hesitate."

**Drop-Off Prediction**:
"Using behavior patterns, I can predict which users are likely to drop off and when."

**Recovery Analysis**:
"I can identify users who dropped off but later returned to complete the funnel."

**Funnel Optimization Calculator**:
"I can estimate revenue impact of improving conversion at each step by X%."

**A/B Test Power Analysis → ab-test-analysis 연결**:

병목 구간을 발견했다면 A/B 테스트로 개선을 검증하세요. 아래 조건 중 하나에 해당하면 **ab-test-analysis 스킬**로 이어가는 것을 권장합니다.

연결 조건:
- 특정 단계 전환율이 🔴 POOR 상태 (60% 미만)
- 이탈 규모가 크고 개선 아이디어(UI 변경, 카피 수정 등)가 준비됨
- 단계별 세그먼트 성과 차이가 10%p 이상

연결 방법: **9단계** 코드를 실행하면 context_packet.json에 병목 정보가 자동 저장됩니다.
ab-test-analysis Step 0에서 이 값을 자동 로드하여 샘플 수·기간을 즉시 계산합니다.
