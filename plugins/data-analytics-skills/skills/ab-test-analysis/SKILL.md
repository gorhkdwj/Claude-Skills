---
name: ab-test-analysis
description: A/B 테스트에 대한 엄격한 통계 분석을 수행합니다. 실험 결과를 분석하거나, 통계적 유의성을 계산하거나, 표본 비율 불일치(Sample Ratio Mismatch)를 확인하거나, 출시 전 테스트 설계를 검증할 때 사용합니다. | Rigorous A/B test statistical analysis. Use when analyzing experiment results, calculating statistical significance, checking for sample ratio mismatch, or validating test design before launch.
---

# A/B 테스트 분석

## Phase
Phase 4 — 분석 수행 (비즈니스 분석 레이어)

## Input
- 이전 스킬: programmatic-eda + data-quality-audit + semantic-model-builder + analysis-assumptions-log
- 받는 파일: `programmatic-eda_result.csv` + `data-quality-audit_result.csv` + `semantic-model-builder_report.md` + `analysis-assumptions-log_report.md`
- **[선택] funnel-analysis 연결 시**: `context_packet.json`에 병목 구간 정보 자동 포함 (baseline_rate, daily_users_at_step)

## Output
- `ab-test-analysis.ipynb`
- `ab-test-analysis_result.csv`
- `ab-test-analysis_report.md`

## 데이터 로딩

파일 확장자에 따라 적절한 pandas 로더를 사용하세요: `.csv` → `pd.read_csv()`, `.json` → `pd.read_json()`, `.parquet` → `pd.read_parquet()`, `.xlsx/.xls` → `pd.read_excel()`, `.tsv` → `pd.read_csv(sep='\t')`.

## 빠른 시작

통계적 엄격성을 유지하면서 실험 결과를 분석하세요. 유의성 검정, 통계적 검정력(Power) 분석, 표본 비율 확인, 변경사항 배포를 위한 실행 가능한 권장사항을 포함합니다.

## 컨텍스트 요구사항

테스트를 분석하기 전에 다음이 필요합니다:

1. **테스트 설계**: 무엇을 테스트했는가 (변형, 가설, 지표)
2. **테스트 데이터**: 각 변형의 결과
3. **랜덤화 단위**: 사용자, 세션, 페이지 뷰 등
4. **주요 지표**: 의사결정을 위한 성공 지표
5. **보호 지표(선택사항)**: 악화되면 안 되는 지표들
6. **테스트 기간**: 테스트 시작/종료 시간

## 컨텍스트 수집

### 테스트 설계를 위해:
"Tell me about the experiment:

**What did you test?**
- Control (baseline): Current experience
- Treatment (variant): What changed?
- Example: 'Control: Blue button' vs 'Treatment: Green button'

**What's your hypothesis?**
- Example: 'Green button will increase conversions by 10%'

**Randomization level:**
- User-level (recommended): Each user always sees same variant
- Session-level: User might see different variants across sessions
- Page-view level: Randomize every page load

Which did you use?"

### 테스트 데이터를 위해:
"I need the results data. Provide:

**Option 1 - Summary Stats:**
```
Control:  Users: 10,000 | Conversions: 1,200 (12.0%)
Treatment: Users: 10,000 | Conversions: 1,350 (13.5%)
```

**Option 2 - User-Level Data:**
```
user_id | variant | converted | revenue | ...
123     | control | TRUE      | 50.00   | ...
456     | treatment | FALSE   | 0       | ...
```

**Option 3 - Daily Aggregates:**
```
date       | variant   | users | conversions
2024-12-01 | control   | 500   | 60
2024-12-01 | treatment | 500   | 68
```

Which format works for you?"

### 지표를 위해:
"What metrics are you tracking?

**Primary Metric** (decision metric):
- Conversion rate, revenue per user, time on site, etc.
- This determines success/failure

**Secondary Metrics** (nice to know):
- Supporting metrics that provide context

**Guardrail Metrics** (must not degrade):
- Page load time, error rate, support tickets
- Treatment must not worsen these

What's your primary metric?"

### 테스트 파라미터를 위해:
"To calculate statistical significance, I need:

**Minimum Detectable Effect (MDE):**
- What % improvement would make it worth rolling out?
- Industry standard: 2-5% for conversion rates

**Significance Level (α):**
- Standard: 0.05 (5% false positive rate)
- Use default unless you have specific requirements

**Power (1-β):**
- Standard: 0.80 (80% chance to detect real effect)
- Use default unless you have specific requirements

Should we use standard parameters (5% significance, 80% power, 2% MDE)?"

### 표본 비율을 위해:
"How were users split between variants?

**Target Allocation:**
- 50/50 (most common)
- 90/10 (if testing risky change)
- 33/33/34 (three variants)

**Actual Allocation:**
- I'll check if actual split matches target
- Sample Ratio Mismatch (SRM) indicates technical issues"

## 실행 모드

| 모드 | 설명 | 실행 단계 |
|------|------|-----------|
| **사전 설계 (Pre-Test Design)** | 아직 실험 미시작 — 필요 샘플 수·기간 계산 | Step 0만 실행 |
| **사후 분석 (Post-Test Analysis)** | 실험 결과 데이터 보유 — 통계 검정 및 권고 | Step 1~8 실행 |

funnel-analysis에서 병목 구간을 발견한 경우 → **사전 설계 모드**로 시작

---

## 워크플로우

### Step 0: 사전 설계 모드 — 샘플 수·기간 계산 [선택]

실험을 시작하기 전에 필요 샘플 수와 기간을 계산합니다.
funnel-analysis 9단계를 실행했다면 context_packet.json에서 **핵심 값이 자동 로드**됩니다.

**Stage 1 — 설계 파라미터 수집**

AI가 아래 순서로 질문합니다:

1. "funnel-analysis 결과가 있나요? 있다면 context_packet.json에서 병목 구간 정보를 자동 로드합니다."
2. (자동 로드 불가 시) "현재 해당 단계 전환율이 얼마인가요? (baseline conversion rate)"
3. "최소 얼마나 개선되면 의미 있다고 보나요? (MDE) — 잘 모르겠다면 아래 가이드라인을 참고하세요."
4. "통계 파라미터는 기본값 사용하시겠습니까? (α=0.05, 검정력=80%)"

**MDE 설정 가이드라인** (잘 모를 때 참고):

| 현재 전환율 | 현실적인 MDE 범위 | 이유 |
|-------------|------------------|------|
| 1 ~ 5% | 0.5 ~ 1%p | 전환율이 낮아 큰 개선 기대 어려움 |
| 5 ~ 15% | 1 ~ 2%p | 일반적인 SaaS·이커머스 기준 |
| 15 ~ 40% | 2 ~ 5%p | 전환율이 높을수록 절대값 개선 여지 있음 |
| 40% 이상 | 3 ~ 8%p | 온보딩·활성화 단계 등 |

> MDE를 너무 작게 잡으면 실험 기간이 수개월로 늘어납니다.
> "이 정도 개선이면 출시할 가치가 있다"는 비즈니스 판단 기준으로 설정하세요.

```python
import numpy as np
import json, os
import math
from scipy import stats

# ── Stage 1: context_packet에서 자동 로드 ────────────────────────
packet_path = "context_packet.json"
packet = {}
if os.path.exists(packet_path):
    with open(packet_path) as f:
        packet = json.load(f)

fb = packet.get("funnel_bottleneck", {})

if fb:
    print(f"📥 funnel-analysis에서 자동 로드:")
    print(f"   병목 단계     : {fb['step_name']}")
    print(f"   기존 전환율   : {fb['baseline_rate']:.1%}")
    print(f"   분석 기간     : {fb['analysis_period_days']}일")
    print(f"   일평균 트래픽 : {fb['total_users_at_step'] // fb['analysis_period_days']:,}명/일")
else:
    print("⚠️  context_packet 없음 — 아래 값을 직접 입력하세요")

# ── Stage 1 설정값 ────────────────────────────────────────────────
# funnel 연결 시 자동 채워짐, 비연결 시 직접 입력
BASELINE_RATE    = fb.get("baseline_rate", 0.12)
_total_users     = fb.get("total_users_at_step", 0)
_analysis_days   = fb.get("analysis_period_days", 30)
DAILY_TRAFFIC    = int(_total_users / _analysis_days) if _total_users > 0 else 1000
MDE              = 0.02        # ← 유일하게 직접 입력 필요 (위 가이드라인 참고)
ALPHA            = 0.05        # 유의수준 (기본값 권장)
POWER            = 0.80        # 검정력 (기본값 권장)
ALLOCATION_RATIO = 0.5         # 대조군 비율 (기본 50/50)
# ─────────────────────────────────────────────────────────────────

def calculate_sample_size(baseline_rate, mde, alpha=0.05, power=0.80):
    """두 비율 비교를 위한 필요 샘플 수 계산 (Cohen's h, two-tailed)"""
    target_rate = baseline_rate + mde
    h = 2 * (np.arcsin(np.sqrt(target_rate)) - np.arcsin(np.sqrt(baseline_rate)))
    z_alpha = stats.norm.ppf(1 - alpha / 2)
    z_beta  = stats.norm.ppf(power)
    n = int(np.ceil(((z_alpha + z_beta) / h) ** 2))
    return n, target_rate, abs(h)

n_per_group, target_rate, effect_h = calculate_sample_size(
    BASELINE_RATE, MDE, ALPHA, POWER
)
n_total = n_per_group * 2

# 실험 기간 계산
daily_per_group = max(DAILY_TRAFFIC * ALLOCATION_RATIO, 1)
days_raw        = math.ceil(n_per_group / daily_per_group)

# ⚠️ 요일 편향 제거: 7일 배수로 올림 (주간 트래픽 패턴 균등화)
days_needed  = math.ceil(days_raw / 7) * 7
weeks_needed = days_needed // 7

print("\n" + "=" * 55)
print("📋 A/B 테스트 사전 설계 결과")
print("=" * 55)

print(f"\n[ 입력 파라미터 ]")
print(f"  기존 전환율    : {BASELINE_RATE:.1%}")
print(f"  목표 전환율    : {target_rate:.1%}  (+{MDE:.1%}p)")
print(f"  일평균 트래픽  : {DAILY_TRAFFIC:,}명/일")
print(f"  유의수준 (α)   : {ALPHA}")
print(f"  검정력 (1-β)   : {POWER:.0%}")

print(f"\n[ 계산 결과 ]")
print(f"  필요 샘플 수   : 그룹당 {n_per_group:,}명  (총 {n_total:,}명)")
print(f"  효과 크기 (h)  : {effect_h:.3f}")
print(f"  실험 기간      : 최소 {days_needed}일  ({weeks_needed}주)")
if days_needed > days_raw:
    print(f"  ※ 통계 계산값 {days_raw}일 → 7일 배수로 올림 (요일 편향 방지)")

print(f"\n[ 가설 정의 ]")
print(f"  H0 : 처리군 전환율 = {BASELINE_RATE:.1%}  (변화 없음)")
print(f"  H1 : 처리군 전환율 ≥ {target_rate:.1%}  (MDE 이상 개선)")

print(f"\n[ 체크리스트 ]")
print(f"  ☐ 랜덤 배정 방식   : 사용자 ID 기반 (User-level) 권장")
print(f"  ☐ 주요 지표        : [측정할 전환 이벤트 명시 필요]")
print(f"  ☐ 보호 지표        : [악화되면 안 되는 지표 정의 필요]")
print(f"  ☐ 실험 중간 확인   : 금지 (peeking) — 유의성 인플레이션 위험")
print(f"  ☐ 최소 실행 기간   : {days_needed}일 달성 전 중단 금지")
print("=" * 55)
print("\n✅ 설계 완료 → 실험 시작 후 결과 수집 시 Step 1~8 실행")
```

**Checkpoint**: "실험 기간이 현실적인가요? 기간을 줄이려면 MDE를 높이거나(더 큰 효과만 탐지) 트래픽을 늘리는 방안을 검토하세요."

---

### Step 1: Load and Validate Test Data

```python
import pandas as pd
import numpy as np
from scipy import stats
import matplotlib.pyplot as plt
import seaborn as sns
from datetime import datetime

# Load test data
test_data = pd.read_csv('ab_test_results.csv')

print(f"📊 Test Data Loaded:")
print(f"  Total Users: {len(test_data):,}")
print(f"  Control: {(test_data['variant'] == 'control').sum():,}")
print(f"  Treatment: {(test_data['variant'] == 'treatment').sum():,}")
print(f"  Primary Metric: conversion_rate")
```

**Checkpoint**: "Data loaded. Sample sizes look reasonable?"

### Step 2: Sample Ratio Mismatch (SRM) Check

```python
def check_sample_ratio_mismatch(test_data, expected_ratio=0.5):
    """
    Check if actual variant split matches expected
    SRM indicates technical issues with randomization
    """
    
    control_count = (test_data['variant'] == 'control').sum()
    treatment_count = (test_data['variant'] == 'treatment').sum()
    total = len(test_data)
    
    # Expected counts
    expected_control = total * expected_ratio
    expected_treatment = total * (1 - expected_ratio)
    
    # Chi-square test
    chi2_stat = (
        (control_count - expected_control)**2 / expected_control +
        (treatment_count - expected_treatment)**2 / expected_treatment
    )
    
    # Critical value for 1 degree of freedom at α=0.001 (very strict)
    critical_value = 10.828  # chi2.ppf(0.999, df=1)
    
    p_value = 1 - stats.chi2.cdf(chi2_stat, df=1)
    
    srm_detected = chi2_stat > critical_value
    
    results = {
        'control_count': control_count,
        'treatment_count': treatment_count,
        'control_pct': control_count / total * 100,
        'treatment_pct': treatment_count / total * 100,
        'expected_ratio': f"{expected_ratio*100:.0f}/{(1-expected_ratio)*100:.0f}",
        'chi2_stat': chi2_stat,
        'p_value': p_value,
        'srm_detected': srm_detected
    }
    
    return results

srm = check_sample_ratio_mismatch(test_data, expected_ratio=0.5)

print(f"\n🔍 Sample Ratio Mismatch Check:")
print(f"  Expected: {srm['expected_ratio']}")
print(f"  Actual: {srm['control_pct']:.1f}% / {srm['treatment_pct']:.1f}%")
print(f"  Chi-square: {srm['chi2_stat']:.2f}")
print(f"  P-value: {srm['p_value']:.4f}")

if srm['srm_detected']:
    print(f"  ⚠️  SRM DETECTED - Investigate randomization issue!")
else:
    print(f"  ✅ No SRM - Randomization looks good")
```

### Step 3: Calculate Metrics by Variant

```python
def calculate_variant_metrics(test_data, metric_col='converted'):
    """Calculate key metrics for each variant"""
    
    variants = {}
    
    for variant_name in ['control', 'treatment']:
        variant_data = test_data[test_data['variant'] == variant_name]
        
        n = len(variant_data)
        successes = variant_data[metric_col].sum()
        success_rate = successes / n
        
        # Standard error for proportion
        se = np.sqrt(success_rate * (1 - success_rate) / n)
        
        # 95% confidence interval
        ci_lower = success_rate - 1.96 * se
        ci_upper = success_rate + 1.96 * se
        
        variants[variant_name] = {
            'n': n,
            'successes': successes,
            'rate': success_rate,
            'se': se,
            'ci_lower': ci_lower,
            'ci_upper': ci_upper
        }
    
    return variants

metrics = calculate_variant_metrics(test_data, 'converted')

print(f"\n📊 Variant Performance:")
for variant_name, stats in metrics.items():
    print(f"\n  {variant_name.upper()}:")
    print(f"    Sample Size: {stats['n']:,}")
    print(f"    Conversions: {stats['successes']:,}")
    print(f"    Rate: {stats['rate']:.3%}")
    print(f"    95% CI: [{stats['ci_lower']:.3%}, {stats['ci_upper']:.3%}]")
```

### Step 4: Statistical Significance Test

```python
def test_statistical_significance(control, treatment):
    """
    Two-proportion z-test for statistical significance
    """
    
    # Pool the proportions
    pooled_p = (control['successes'] + treatment['successes']) / (control['n'] + treatment['n'])
    pooled_se = np.sqrt(pooled_p * (1 - pooled_p) * (1/control['n'] + 1/treatment['n']))
    
    # Calculate z-score
    diff = treatment['rate'] - control['rate']
    z_score = diff / pooled_se
    
    # Two-tailed p-value
    p_value = 2 * (1 - stats.norm.cdf(abs(z_score)))
    
    # Effect size (relative uplift)
    relative_uplift = (treatment['rate'] - control['rate']) / control['rate']
    
    # Absolute uplift
    absolute_uplift = treatment['rate'] - control['rate']
    
    # Confidence interval for the difference
    se_diff = np.sqrt(
        control['rate'] * (1 - control['rate']) / control['n'] +
        treatment['rate'] * (1 - treatment['rate']) / treatment['n']
    )
    ci_lower = diff - 1.96 * se_diff
    ci_upper = diff + 1.96 * se_diff
    
    results = {
        'absolute_uplift': absolute_uplift,
        'relative_uplift': relative_uplift,
        'z_score': z_score,
        'p_value': p_value,
        'significant': p_value < 0.05,
        'ci_lower': ci_lower,
        'ci_upper': ci_upper
    }
    
    return results

sig_test = test_statistical_significance(metrics['control'], metrics['treatment'])

print(f"\n📈 Statistical Significance Test:")
print(f"  Absolute Uplift: {sig_test['absolute_uplift']:.3%}")
print(f"  Relative Uplift: {sig_test['relative_uplift']:+.1%}")
print(f"  95% CI: [{sig_test['ci_lower']:.3%}, {sig_test['ci_upper']:.3%}]")
print(f"  Z-score: {sig_test['z_score']:.2f}")
print(f"  P-value: {sig_test['p_value']:.4f}")

if sig_test['significant']:
    print(f"  ✅ STATISTICALLY SIGNIFICANT (p < 0.05)")
    if sig_test['relative_uplift'] > 0:
        print(f"  📈 Treatment WINS")
    else:
        print(f"  📉 Treatment LOSES")
else:
    print(f"  ❌ NOT SIGNIFICANT - No clear winner")
```

### Step 5: Power Analysis

```python
def calculate_achieved_power(control, treatment, alpha=0.05):
    """
    Calculate the statistical power achieved in the test
    """
    
    # Effect size (Cohen's h for proportions)
    p1 = control['rate']
    p2 = treatment['rate']
    
    effect_size = 2 * (np.arcsin(np.sqrt(p2)) - np.arcsin(np.sqrt(p1)))
    
    # Critical z-value for two-tailed test
    z_crit = stats.norm.ppf(1 - alpha/2)
    
    # Standard error under alternative hypothesis
    n = control['n']  # assuming equal sample sizes
    se_alt = np.sqrt(p1*(1-p1)/n + p2*(1-p2)/n)
    
    # Non-centrality parameter
    ncp = (p2 - p1) / se_alt
    
    # Power calculation
    power = 1 - stats.norm.cdf(z_crit - abs(ncp)) + stats.norm.cdf(-z_crit - abs(ncp))
    
    return {
        'effect_size': effect_size,
        'power': power,
        'sample_size_per_variant': n
    }

power_analysis = calculate_achieved_power(metrics['control'], metrics['treatment'])

print(f"\n⚡ Power Analysis:")
print(f"  Effect Size (Cohen's h): {power_analysis['effect_size']:.3f}")
print(f"  Achieved Power: {power_analysis['power']:.1%}")
print(f"  Sample Size per Variant: {power_analysis['sample_size_per_variant']:,}")

if power_analysis['power'] < 0.80:
    print(f"  ⚠️  UNDERPOWERED - Results less reliable")
else:
    print(f"  ✅ Well-powered test")
```

### Step 6: Guardrail Metrics Check

```python
def check_guardrail_metrics(test_data, guardrail_metrics=['page_load_time', 'error_rate']):
    """
    Ensure treatment doesn't degrade important guardrail metrics
    """
    
    print(f"\n🛡️  Guardrail Metrics Check:")
    
    guardrail_results = []
    
    for metric in guardrail_metrics:
        if metric not in test_data.columns:
            continue
        
        control_data = test_data[test_data['variant'] == 'control'][metric]
        treatment_data = test_data[test_data['variant'] == 'treatment'][metric]
        
        # T-test for continuous metrics
        t_stat, p_value = stats.ttest_ind(treatment_data, control_data)
        
        control_mean = control_data.mean()
        treatment_mean = treatment_data.mean()
        change = ((treatment_mean - control_mean) / control_mean) * 100
        
        # Check if treatment is worse (degraded)
        degraded = (change > 0 and 'time' in metric.lower()) or \
                   (change > 0 and 'error' in metric.lower()) or \
                   (change < 0 and 'score' in metric.lower())
        
        print(f"\n  {metric}:")
        print(f"    Control: {control_mean:.2f}")
        print(f"    Treatment: {treatment_mean:.2f}")
        print(f"    Change: {change:+.1f}%")
        
        if degraded and p_value < 0.05:
            print(f"    ⚠️  DEGRADED significantly (p={p_value:.4f})")
        elif degraded:
            print(f"    ⚠️  Degraded but not significant")
        else:
            print(f"    ✅ No degradation")
        
        guardrail_results.append({
            'metric': metric,
            'control_mean': control_mean,
            'treatment_mean': treatment_mean,
            'change_pct': change,
            'p_value': p_value,
            'degraded': degraded and p_value < 0.05
        })
    
    return guardrail_results

guardrails = check_guardrail_metrics(test_data, ['page_load_time', 'bounce_rate'])
```

### Step 7: Visualize Results

```python
def plot_ab_test_results(metrics, sig_test):
    """Create comprehensive visualization of test results"""
    
    fig, (ax1, ax2) = plt.subplots(1, 2, figsize=(14, 6))
    
    # Plot 1: Conversion rates with confidence intervals
    variants = ['Control', 'Treatment']
    rates = [metrics['control']['rate'], metrics['treatment']['rate']]
    ci_lower = [metrics['control']['ci_lower'], metrics['treatment']['ci_lower']]
    ci_upper = [metrics['control']['ci_upper'], metrics['treatment']['ci_upper']]
    
    x = np.arange(len(variants))
    colors = ['#3498db', '#2ecc71' if sig_test['relative_uplift'] > 0 else '#e74c3c']
    
    bars = ax1.bar(x, rates, color=colors, alpha=0.7, width=0.6)
    ax1.errorbar(x, rates, 
                 yerr=[np.array(rates) - np.array(ci_lower), 
                       np.array(ci_upper) - np.array(rates)],
                 fmt='none', color='black', capsize=5, capthick=2)
    
    # Add value labels
    for i, (variant, rate) in enumerate(zip(variants, rates)):
        ax1.text(i, rate + 0.01, f'{rate:.2%}', ha='center', fontweight='bold')
    
    ax1.set_ylabel('Conversion Rate')
    ax1.set_title('Conversion Rate by Variant\n(with 95% Confidence Intervals)')
    ax1.set_xticks(x)
    ax1.set_xticklabels(variants)
    ax1.set_ylim(0, max(rates) * 1.2)
    
    # Plot 2: Effect size visualization
    uplift = sig_test['relative_uplift']
    ci_lower_pct = (sig_test['ci_lower'] / metrics['control']['rate'])
    ci_upper_pct = (sig_test['ci_upper'] / metrics['control']['rate'])
    
    ax2.barh(['Effect'], [uplift * 100], color='green' if uplift > 0 else 'red', alpha=0.7)
    ax2.errorbar([uplift * 100], ['Effect'],
                 xerr=[[uplift * 100 - ci_lower_pct * 100], [ci_upper_pct * 100 - uplift * 100]],
                 fmt='none', color='black', capsize=5, capthick=2)
    
    # Add significance indicator
    sig_text = "✅ Significant" if sig_test['significant'] else "❌ Not Significant"
    ax2.text(uplift * 100, 0, f"  {uplift*100:+.1f}%\n  {sig_text}",
             va='center', fontweight='bold')
    
    ax2.axvline(0, color='black', linestyle='--', alpha=0.5)
    ax2.set_xlabel('Relative Uplift (%)')
    ax2.set_title(f'Treatment Effect\n(p-value: {sig_test["p_value"]:.4f})')
    
    plt.tight_layout()
    plt.savefig('ab_test_results.png', dpi=300, bbox_inches='tight')
    plt.show()

plot_ab_test_results(metrics, sig_test)
```

### Step 8: Generate Decision Recommendation

```python
def generate_recommendation(sig_test, guardrails, power_analysis, srm):
    """
    Provide clear recommendation based on all checks
    """
    
    print(f"\n{'='*60}")
    print("🎯 RECOMMENDATION")
    print('='*60)
    
    # Check for blockers
    blockers = []
    
    if srm['srm_detected']:
        blockers.append("Sample Ratio Mismatch detected - randomization issue")
    
    if power_analysis['power'] < 0.70:
        blockers.append(f"Underpowered ({power_analysis['power']:.0%}) - results unreliable")
    
    degraded_guardrails = [g for g in guardrails if g['degraded']]
    if degraded_guardrails:
        blockers.append(f"Guardrail metrics degraded: {[g['metric'] for g in degraded_guardrails]}")
    
    # Make recommendation
    if blockers:
        print(f"\n❌ DO NOT SHIP - Critical Issues Found:\n")
        for blocker in blockers:
            print(f"  • {blocker}")
        recommendation = "DO_NOT_SHIP"
    
    elif sig_test['significant'] and sig_test['relative_uplift'] > 0:
        print(f"\n✅ RECOMMEND SHIPPING")
        print(f"\n  Treatment shows {sig_test['relative_uplift']:+.1%} improvement")
        print(f"  Statistically significant (p={sig_test['p_value']:.4f})")
        print(f"  No guardrail issues detected")
        
        # Estimate impact
        if 'control' in metrics:
            baseline_rate = metrics['control']['rate']
            sample_size = metrics['control']['n']
            print(f"\n  Expected Impact:")
            print(f"    If applied to {sample_size:,} users monthly:")
            print(f"    Additional conversions: {sample_size * sig_test['absolute_uplift']:+,.0f}/month")
        
        recommendation = "SHIP"
    
    elif sig_test['significant'] and sig_test['relative_uplift'] < 0:
        print(f"\n❌ DO NOT SHIP")
        print(f"\n  Treatment shows {sig_test['relative_uplift']:.1%} degradation")
        print(f"  Statistically significant negative impact")
        recommendation = "DO_NOT_SHIP"
    
    else:
        print(f"\n⚠️  NO CLEAR WINNER")
        print(f"\n  Treatment shows {sig_test['relative_uplift']:+.1%} change")
        print(f"  But NOT statistically significant (p={sig_test['p_value']:.4f})")
        print(f"\n  Options:")
        print(f"    1. Ship if change is low-risk and directionally positive")
        print(f"    2. Run longer to gather more data")
        print(f"    3. Redesign with larger expected effect")
        recommendation = "INCONCLUSIVE"
    
    return recommendation

recommendation = generate_recommendation(sig_test, guardrails, power_analysis, srm)
```

## 컨텍스트 검증

진행하기 전에 확인하세요:
- [ ] 테스트가 통계적 검정력에 도달할 때까지 충분히 실행됨
- [ ] 랜덤화가 제대로 구현됨
- [ ] SRM (표본 비율 불일치) 감지 안 됨
- [ ] 주요 지표가 명확하게 정의됨
- [ ] 검정력 계산을 위한 기본 데이터 보유
- [ ] 필요한 최소 탐지 가능 효과 이해

## 출력 템플릿

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
A/B 테스트 분석 보고서
Test: Green Button vs Blue Button
Period: Dec 1-15, 2024
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

✅ RECOMMENDATION: SHIP TREATMENT

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📊 RESULTS SUMMARY
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Primary Metric: Conversion Rate

Control:
  Sample: 10,000 users
  Conversions: 1,200
  Rate: 12.0% (95% CI: 11.3% - 12.7%)

Treatment:
  Sample: 10,000 users
  Conversions: 1,350
  Rate: 13.5% (95% CI: 12.8% - 14.2%)

Effect:
  Absolute: +1.5 percentage points
  Relative: +12.5%
  95% CI: [+0.4%, +2.6%]

Statistical Significance:
  Z-score: 2.65
  P-value: 0.0080
  Result: ✅ SIGNIFICANT (p < 0.05)

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
✅ VALIDATION CHECKS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Sample Ratio: ✅ PASS
  Expected: 50/50
  Actual: 50.0% / 50.0%
  No randomization issues detected

Statistical Power: ✅ PASS
  Achieved: 85%
  Effect Size: 0.042 (Cohen's h)

Guardrail Metrics: ✅ PASS
  Page Load Time: No degradation
  Bounce Rate: -2.1% (improved)
  Error Rate: No change

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
💰 EXPECTED IMPACT
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Monthly Volume: 300,000 users

Additional Conversions: +3,750/month
Revenue Impact: +$187,500/month
  (assuming $50 avg order value)

Confidence: High
Risk: Low

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📋 NEXT STEPS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

1. ✅ Ship treatment to 100% of users
2. Monitor for 1 week post-launch
3. Track conversion rate stays elevated
4. Iterate: Test other button colors?

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📁 FILES GENERATED
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

✓ ab_test_results.png (visualization)
✓ statistical_analysis.csv (detailed metrics)
✓ power_analysis.txt (power calculations)
✓ guardrail_check.csv (all guardrail metrics)
```

## 일반적인 시나리오

### Scenario 1: "Should we ship this new feature?"
→ Run full significance test
→ Check guardrail metrics
→ Calculate expected business impact
→ Provide clear ship/don't ship recommendation
→ Quantify confidence level

### Scenario 2: "Test is inconclusive after 2 weeks"
→ Calculate achieved power
→ Determine if more time would help
→ Estimate time needed to reach significance
→ Recommend: run longer, redesign, or make business decision

### Scenario 3: "Validate test design before launching"
→ **Step 0 실행** (사전 설계 모드)
→ funnel-analysis context_packet에서 baseline_rate·daily_traffic·period 자동 로드
→ MDE 입력 → 필요 샘플 수·실험 기간(7일 배수) 계산
→ 가설(H0/H1) 자동 정의, 체크리스트 출력
→ 설계 완료 후 실험 시작 → 결과 수집 후 Step 1~8 실행

### Scenario 4: "Multiple variants to compare"
→ Use ANOVA or pairwise comparisons
→ Apply Bonferroni correction for multiple testing
→ Identify best performing variant
→ Check if any significantly better than control

### Scenario 5: "Test shows improvement but stakeholders skeptical"
→ Show statistical rigor (significance, power, CI)
→ Rule out SRM and other technical issues
→ Demonstrate guardrails not degraded
→ Provide expected business impact
→ Build confidence with data

## 누락된 컨텍스트 처리

**User shares results without test design:**
"To properly analyze, I need to know:
- What was tested (control vs treatment)
- How users were randomized
- What metric we're measuring
- Expected/desired effect size

Can you share the test plan?"

**User doesn't know if sample size is enough:**
"Let me calculate the required sample size based on:
- Baseline conversion rate
- Desired uplift to detect
- Acceptable error rates

Then compare to what you have."

**User concerned about p-value close to 0.05:**
"P-value of 0.049 is technically significant, but borderline. Let's:
- Check confidence interval (does it cross zero?)
- Review statistical power
- Consider practical significance
- Possibly run longer for more confidence"

**User wants to peek at results mid-test:**
"Peeking increases false positive rate. If we must:
- Apply alpha spending function
- Use sequential testing methods
- Or just note results are preliminary"

## 고급 옵션

After basic analysis, offer:

**Bayesian Analysis**:
"Want probability that treatment is better? Bayesian approach gives you 'P(treatment > control)'"

**Sequential Testing**:
"Planning to check results multiple times? I can adjust for peeking using sequential testing methods"

**Heterogeneous Treatment Effects**:
"Want to see if treatment works better for certain user segments? I can analyze by subgroup"

**Long-term Impact Estimation**:
"I can estimate sustained lift accounting for novelty effect and regression to mean"

**Multi-Armed Bandit**:
"For continuous optimization, consider switching to bandit algorithm instead of fixed A/B test"

**Sample Size Calculator**:
"Planning your next test? I can calculate required sample size for desired power and effect"
