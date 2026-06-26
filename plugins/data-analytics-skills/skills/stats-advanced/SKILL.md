---
name: stats-advanced
description: |
  stats-basic(기초 검정)으로 부족할 때 사용하는 심화 통계 분석 스킬.
  표 형식 데이터(CSV·JSON·Parquet·Excel 등)를 받아
  대응표본 t-test, 이원 ANOVA, 로지스틱 회귀, 다중 선형 회귀, 편상관분석,
  Fisher's Exact Test, 다중비교 보정(Bonferroni/FDR)을 수행하며,
  실행 결과가 내장된 Jupyter Notebook(stats-advanced.ipynb), 검정 결과 요약표(stats-advanced_result.csv),
  한국어 해석 보고서(stats-advanced_report.md)를 제공합니다.

  다음 상황에서 반드시 이 스킬을 사용하세요:
  - "전후 비교해줘", "처리 전/후 차이가 있는지 검정해줘" → 대응표본 t-test
  - "두 개 이상의 요인이 동시에 영향을 주는지 보고 싶어" → 이원 ANOVA
  - "구매 여부, 이탈 여부 등 Yes/No 결과를 예측하고 싶어" → 로지스틱 회귀
  - "여러 변수가 동시에 결과에 미치는 영향 분석해줘" → 다중 선형 회귀
  - "다른 변수의 영향을 제거하고 두 변수 관계만 보고 싶어" → 편상관분석
  - "샘플 수가 너무 적어서 카이제곱이 부정확할 것 같아" → Fisher's Exact Test
  - "여러 검정을 동시에 해서 오류가 걱정돼" → 다중비교 보정
  - "기초 통계 검정 결과에서 더 깊이 파고들고 싶어"
  - stats-basic 결과를 보고 추가 심화 분석이 필요할 때
---

# 심화 통계 분석 스킬

이 스킬은 stats-basic(기초)의 **상위 단계**로, 더 정밀하고 복잡한 통계 분석을 담당합니다. 출력물은 `stats-advanced.ipynb`(실행결과 내장) + `stats-advanced_result.csv`(검정 결과 요약표) + `stats-advanced_report.md`(한국어 해석 보고서)입니다.

## Phase
Phase 4 — 분석 수행 (범용 도구 레이어)

## Input
- 이전 스킬: stats-basic
- 받는 파일: `stats-basic_result.csv` + `stats-basic_report.md`

## Output
- `stats-advanced.ipynb` — 심화 통계 코드 (실행결과, 차트 내장)
- `stats-advanced_result.csv` — 검정 결과 요약표 (통계량, p-value, 결론)
- `stats-advanced_report.md` — 검정 결과를 쉬운 말로 해석한 한국어 보고서

---

## Quick Start

심화 검정은 기초 검정보다 강력하지만, 그만큼 **가정(assumption)을 더 엄격하게 지켜야** 합니다. 분석 결과와 함께 "이 검정을 쓰기 위해 어떤 조건을 확인했고, 조건이 충족됐는지"를 항상 설명하세요. 초보자가 "왜 이 방법을 썼는지"를 이해할 수 있어야 합니다.

## 회귀 분석 전 필수 체크

다중 선형 회귀 또는 로지스틱 회귀를 수행하기 전, 아래 두 가지를 반드시 확인하세요.

**① 다중공선성 (Multicollinearity) 확인**
독립변수들 간 상관관계가 높으면 회귀 계수가 불안정해져 해석이 어렵습니다.

```python
# VIF(분산팽창인수)로 다중공선성 확인
from statsmodels.stats.outliers_influence import variance_inflation_factor

X = df[feature_cols]
vif_data = pd.DataFrame({
    'feature': X.columns,
    'VIF': [variance_inflation_factor(X.values, i) for i in range(X.shape[1])]
}).sort_values('VIF', ascending=False)

print(vif_data)
# VIF > 10: 해당 변수 제거 또는 결합 권장
# VIF 5~10: 주의 필요
# VIF < 5: 문제 없음
```

> 💡 VIF > 10인 변수가 있다면: feature-engineering 스킬의 **피처 선택 단계**만
> 선택적으로 참고해 상관 높은 변수를 제거하세요.
> feature-engineering 전체(파생변수 생성 등)를 실행하면 불필요한 변수가 늘어나
> 다중공선성이 오히려 악화될 수 있습니다.

**② 정규성 가정 확인**
선형 회귀는 잔차(residual)의 정규성을 가정합니다. 회귀 수행 후 잔차 플롯으로 확인하세요.

```python
# 잔차 정규성 확인 (회귀 수행 후)
from scipy.stats import shapiro
_, p_val = shapiro(residuals)
print(f"Shapiro-Wilk p-value: {p_val:.4f}")
# p > 0.05: 정규성 가정 충족
# p <= 0.05: 정규성 위반 → 로그 변환 또는 비모수 방법 고려
```

---

## Context Requirements

1. **데이터**: 분석할 표 형식 파일 (CSV·JSON·Parquet·Excel·TSV)
2. **이전 기초 검정 결과**: `stats-basic_result.csv` 및 `stats-basic_report.md` (필수)
3. **심화 분석 목적**: 기초 검정에서 확인한 결과 중 더 깊이 파고들 항목
4. **분석 유형**: 전후 비교 / 다요인 분석 / 예측 / 다중비교 보정 중 해당 항목

---

## Context Gathering

Read 툴을 사용해 기존 결과물을 순서대로 확인하세요. Python 코드 실행이 아닌 파일 직접 탐색으로 진행합니다.

**탐색 순서:**
1. 사용자가 언급한 CSV 파일과 같은 경로의 `csv-stats-basic_report.md`
2. 이전 대화에서 생성된 `csv-stats-basic_report.md` 경로
3. 위 두 경우 없으면 CSV를 직접 읽어 데이터 특성 파악

**찾은 report.md에서 추출할 정보:**
- 기초 검정(csv-stats-basic)에서 어떤 결과가 나왔는가
- 어떤 변수들이 유의미하게 나왔는가
- 어떤 한계나 후속 분석이 제안됐는가

맥락을 확인한 뒤, 선택한 검정과 이유를 사용자에게 한 줄로 먼저 알려주세요.
예: "기초 검정에서 전후 데이터임이 확인되어 대응표본 t-test를 수행합니다."

---

## 2단계 실행 구조

| 단계 | 설명 | 빈도 |
|------|------|------|
| **Stage 1** 대화형 설정 | Claude와 대화로 Config Block 값 결정 | 처음 1회 |
| **Stage 2** 노트북 실행 | DATA_PATH만 수정 후 전체 셀 실행 | 매 실행 |

---

## Workflow

### 셀 1: Config Block

```python
# ╔══════════════════════════════════════════════════════════════╗
# ║        CONFIG BLOCK — 반복 실행 시 이 셀만 수정                  ║
# ╚══════════════════════════════════════════════════════════════╝

DATA_PATH        = "데이터_파일_경로.csv"  # ← 매 실행 시 이 줄만 변경

# 도메인 설정 (최초 1회 확정 후 고정)
DEPENDENT_VAR    = None   # 종속변수 컬럼명 (예: "score", "is_churned")
INDEPENDENT_VARS = []     # 독립변수 리스트 (예: ["age","tenure","plan"])
TEST_TYPE        = "auto" # "auto"|"paired_ttest"|"two_way_anova"|"logistic"|"multiple_reg"|"partial_corr"|"fisher"|"bonferroni"
ALPHA            = 0.05
DOMAIN_NOTES     = []     # 비즈니스 규칙 메모

# ════════════════════════════════════════════════════════════════
```

### 셀 2: 라이브러리 로드 및 데이터 로드 + 드리프트 탐지

```python
import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
import matplotlib
import seaborn as sns
import json, os, warnings
from scipy import stats
import statsmodels.api as sm
import statsmodels.formula.api as smf
from statsmodels.stats.multicomp import multipletests
warnings.filterwarnings('ignore')
matplotlib.rcParams['font.family'] = 'DejaVu Sans'
matplotlib.rcParams['axes.unicode_minus'] = False
%matplotlib inline

def load_data(path):
    ext = path.rsplit('.', 1)[-1].lower()
    try:
        loaders = {
            'csv':     lambda: pd.read_csv(path, encoding='utf-8'),
            'tsv':     lambda: pd.read_csv(path, sep='\t', encoding='utf-8'),
            'json':    lambda: pd.read_json(path),
            'parquet': lambda: pd.read_parquet(path),
            'xlsx':    lambda: pd.read_excel(path),
            'xls':     lambda: pd.read_excel(path),
        }
        if ext not in loaders:
            raise ValueError(f"지원하지 않는 형식: .{ext}")
        return loaders[ext]()
    except UnicodeDecodeError:
        return pd.read_csv(path, encoding='cp949')

def check_schema_drift(df, baseline_path):
    current = {
        "columns": list(df.columns),
        "dtypes":  {c: str(df[c].dtype) for c in df.columns},
        "categories": {
            c: sorted([str(v) for v in df[c].dropna().unique()])
            for c in df.select_dtypes(include=["object","category"]).columns
            if df[c].nunique() <= 30
        }
    }
    if not os.path.exists(baseline_path):
        with open(baseline_path, "w", encoding="utf-8") as f:
            json.dump(current, f, ensure_ascii=False, indent=2)
        print(f"✅ 기준 스키마 저장됨 (첫 실행) → {baseline_path}"); return
    with open(baseline_path, "r", encoding="utf-8") as f:
        baseline = json.load(f)
    drifts = []
    new_cols     = set(current["columns"]) - set(baseline["columns"])
    removed_cols = set(baseline["columns"]) - set(current["columns"])
    type_changes = {c: (baseline["dtypes"].get(c), current["dtypes"][c])
                    for c in current["columns"]
                    if c in baseline["dtypes"] and baseline["dtypes"][c] != current["dtypes"][c]}
    for col in current["categories"]:
        if col in baseline.get("categories", {}):
            added   = set(current["categories"][col]) - set(baseline["categories"][col])
            removed = set(baseline["categories"][col]) - set(current["categories"][col])
            if added:   drifts.append(f"'{col}' 신규 카테고리: {added}")
            if removed: drifts.append(f"'{col}' 삭제된 카테고리: {removed}")
    if new_cols:     drifts.append(f"신규 컬럼: {new_cols}")
    if removed_cols: drifts.append(f"삭제된 컬럼: {removed_cols}")
    if type_changes: drifts.append(f"타입 변경: {type_changes}")
    if drifts:
        print("⚠️  스키마 드리프트 감지! Config Block 설정을 재검토하세요:")
        for d in drifts: print(f"   • {d}")
    else:
        print("✅ 스키마 변화 없음 — Config Block 설정 그대로 사용 가능")

df = load_data(DATA_PATH)
print(f"데이터 크기: {df.shape[0]:,}행 × {df.shape[1]}열")
if DOMAIN_NOTES:
    print("📋 도메인 노트:")
    for note in DOMAIN_NOTES: print(f"   • {note}")
check_schema_drift(df, "stats-advanced_baseline_schema.json")
df.head()

# 결과 누적용 리스트 (마지막 셀에서 stats-advanced_result.csv로 저장)
results = []
```

---

### ① 대응표본 t-test (전후 비교)

언제: "교육 전/후 점수 차이", "치료 전/후 수치 변화", 같은 대상이 두 번 측정된 경우

```python
from scipy.stats import ttest_rel, wilcoxon

before_col = '사전_컬럼'
after_col  = '사후_컬럼'

diff = df[after_col] - df[before_col]

# 차이값 정규성 먼저 확인
stat, p_norm = stats.shapiro(diff.dropna())
print(f"차이값 정규성 검정: p={p_norm:.4f} → {'정규분포 ✅' if p_norm > 0.05 else '비정규 ⚠️'}")

if p_norm > 0.05:
    t_stat, p_val = ttest_rel(df[before_col].dropna(), df[after_col].dropna())
    test_name = "대응표본 t-test"
else:
    t_stat, p_val = wilcoxon(df[before_col].dropna(), df[after_col].dropna())
    test_name = "Wilcoxon 부호순위 검정 (비모수)"

print(f"\n{test_name} 결과")
print(f"통계량: {t_stat:.4f}, p-value: {p_val:.4f}")
print(f"사전 평균: {df[before_col].mean():.2f} → 사후 평균: {df[after_col].mean():.2f}")
print(f"평균 변화량: {diff.mean():.2f}")
conclusion = "전후 차이 유의미함" if p_val < 0.05 else "전후 유의미한 차이 없음"
if p_val < 0.05:
    print("→ 전후 차이가 통계적으로 유의미합니다 (p < 0.05)")
else:
    print("→ 전후 유의미한 차이가 없습니다 (p ≥ 0.05)")

# 결과 저장
results.append({
    "검정종류": test_name,
    "변수(그룹)": before_col,
    "변수(값)": after_col,
    "그룹1": f"사전평균={df[before_col].mean():.2f}",
    "그룹2": f"사후평균={df[after_col].mean():.2f}",
    "통계량": round(t_stat, 4),
    "p_value": round(p_val, 4),
    "유의수준(0.05)": "유의함" if p_val < 0.05 else "유의하지않음",
    "결론": conclusion
})

# 시각화: 전후 분포 비교
fig, axes = plt.subplots(1, 2, figsize=(12, 5))
axes[0].boxplot([df[before_col].dropna(), df[after_col].dropna()],
                labels=['사전', '사후'])
axes[0].set_title('사전-사후 분포 비교')
axes[1].hist(diff.dropna(), bins=15, edgecolor='black')
axes[1].axvline(0, color='red', linestyle='--', label='변화 없음')
axes[1].set_title('변화량 분포')
axes[1].legend()
plt.tight_layout()
plt.show()
```

---

### ② 이원 ANOVA (두 요인이 동시에 영향을 줄 때)

언제: "성별과 지역 두 요인이 모두 매출에 영향을 주는가?", "요인 간 상호작용이 있는가?"

```python
import statsmodels.formula.api as smf
from statsmodels.stats.anova import anova_lm

factor1 = '요인1_컬럼'   # 예: '성별'
factor2 = '요인2_컬럼'   # 예: '지역'
value   = '결과_컬럼'    # 예: '매출'

# 이원 ANOVA (상호작용 포함)
formula = f"{value} ~ C({factor1}) + C({factor2}) + C({factor1}):C({factor2})"
model = smf.ols(formula, data=df).fit()
anova_table = anova_lm(model, typ=2)
print(anova_table)

# 결과 해석 및 저장
for idx in anova_table.index[:-1]:
    p = anova_table.loc[idx, 'PR(>F)']
    f_val = anova_table.loc[idx, 'F']
    label = "유의미 ✅" if p < 0.05 else "유의미하지 않음"
    print(f"  {idx}: p={p:.4f} → {label}")
    results.append({
        "검정종류": "이원 ANOVA",
        "변수(그룹)": str(idx),
        "변수(값)": value,
        "그룹1": factor1,
        "그룹2": factor2,
        "통계량": round(float(f_val), 4),
        "p_value": round(float(p), 4),
        "유의수준(0.05)": "유의함" if p < 0.05 else "유의하지않음",
        "결론": f"{idx} 효과 {'유의미' if p < 0.05 else '유의미하지않음'}"
    })

# 시각화: 상호작용 플롯
fig, ax = plt.subplots(figsize=(10, 5))
for group, grp_df in df.groupby(factor1):
    means = grp_df.groupby(factor2)[value].mean()
    ax.plot(means.index, means.values, marker='o', label=str(group))
ax.set_xlabel(factor2)
ax.set_ylabel(f'{value} 평균')
ax.set_title(f'{factor1} × {factor2} 상호작용 플롯')
ax.legend(title=factor1)
plt.tight_layout()
plt.show()
```

---

### ③ 로지스틱 회귀 (Yes/No 결과 예측)

언제: "구매 여부 예측", "이탈 여부 분류", 종속변수가 0/1인 경우

```python
from sklearn.linear_model import LogisticRegression
from sklearn.metrics import classification_report, confusion_matrix, roc_auc_score, roc_curve
from sklearn.model_selection import train_test_split
from sklearn.preprocessing import StandardScaler

target_col = '결과_컬럼'   # 0 또는 1
feature_cols = ['변수1', '변수2', '변수3']  # 예측에 사용할 컬럼들

# 결측치 제거
data = df[feature_cols + [target_col]].dropna()
X = data[feature_cols]
y = data[target_col]

# 학습/검증 분리
X_train, X_test, y_train, y_test = train_test_split(X, y, test_size=0.2, random_state=42)
scaler = StandardScaler()
X_train_s = scaler.fit_transform(X_train)
X_test_s  = scaler.transform(X_test)

# 모델 학습
model = LogisticRegression(random_state=42)
model.fit(X_train_s, y_train)

# 성능 평가
y_pred = model.predict(X_test_s)
y_prob = model.predict_proba(X_test_s)[:, 1]
print("=== 분류 성능 리포트 ===")
print(classification_report(y_test, y_pred))
print(f"AUC-ROC: {roc_auc_score(y_test, y_prob):.4f}")

# 혼동 행렬
fig, axes = plt.subplots(1, 2, figsize=(12, 5))
sns.heatmap(confusion_matrix(y_test, y_pred), annot=True, fmt='d',
            cmap='Blues', ax=axes[0])
axes[0].set_title('혼동 행렬 (Confusion Matrix)')
axes[0].set_xlabel('예측값')
axes[0].set_ylabel('실제값')

# ROC 곡선
fpr, tpr, _ = roc_curve(y_test, y_prob)
axes[1].plot(fpr, tpr, label=f'AUC = {roc_auc_score(y_test, y_prob):.3f}')
axes[1].plot([0,1],[0,1],'--', color='gray')
axes[1].set_xlabel('위양성률 (FPR)')
axes[1].set_ylabel('진양성률 (TPR)')
axes[1].set_title('ROC 곡선')
axes[1].legend()
plt.tight_layout()
plt.show()

# 결과 저장
auc_score = roc_auc_score(y_test, y_prob)
results.append({
    "검정종류": "로지스틱 회귀",
    "변수(그룹)": ", ".join(feature_cols),
    "변수(값)": target_col,
    "그룹1": f"학습샘플={len(X_train)}",
    "그룹2": f"검증샘플={len(X_test)}",
    "통계량": round(auc_score, 4),
    "p_value": "",
    "유의수준(0.05)": "AUC≥0.7 권장",
    "결론": f"AUC={auc_score:.3f} ({'양호' if auc_score >= 0.7 else '개선필요'})"
})

# 변수 중요도 (계수)
coef_df = pd.DataFrame({'변수': feature_cols, '계수': model.coef_[0]})
coef_df['절댓값'] = coef_df['계수'].abs()
coef_df = coef_df.sort_values('절댓값', ascending=True)
fig, ax = plt.subplots(figsize=(8, 5))
ax.barh(coef_df['변수'], coef_df['계수'])
ax.axvline(0, color='black', linewidth=0.8)
ax.set_title('로지스틱 회귀 계수 (영향력)')
plt.tight_layout()
plt.show()
```

---

### ④ 다중 선형 회귀 (여러 변수가 동시에 미치는 영향)

언제: "학습시간, 수면, 과외가 동시에 성적에 미치는 영향", 독립변수가 2개 이상인 경우

```python
y_col = '종속변수'
x_cols = ['독립변수1', '독립변수2', '독립변수3']

data = df[x_cols + [y_col]].dropna()
X = sm.add_constant(data[x_cols])
y = data[y_col]
model = sm.OLS(y, X).fit()
print(model.summary())

# 핵심 수치 요약
print(f"\nR²: {model.rsquared:.4f} → 전체 변동의 {model.rsquared*100:.1f}%를 설명")
print(f"수정 R²: {model.rsquared_adj:.4f} (변수 수 보정)")
print("\n각 변수의 영향 (다른 변수 고정 시):")
for col in x_cols:
    coef = model.params[col]
    pval = model.pvalues[col]
    sig  = "✅ 유의미" if pval < 0.05 else "❌ 유의미하지 않음"
    print(f"  {col}: +1 증가 시 {y_col} {coef:+.3f} 변화 (p={pval:.4f}, {sig})")

# 결과 저장 (변수별)
for col in x_cols:
    results.append({
        "검정종류": "다중 선형 회귀",
        "변수(그룹)": col,
        "변수(값)": y_col,
        "그룹1": f"계수={model.params[col]:.3f}",
        "그룹2": f"R²={model.rsquared:.3f}",
        "통계량": round(model.params[col], 4),
        "p_value": round(model.pvalues[col], 4),
        "유의수준(0.05)": "유의함" if model.pvalues[col] < 0.05 else "유의하지않음",
        "결론": f"{col}+1→{y_col}{model.params[col]:+.3f} (R²={model.rsquared:.3f})"
    })

# 잔차 진단 플롯
fig, axes = plt.subplots(1, 2, figsize=(12, 5))
fitted = model.fittedvalues
resid  = model.resid
axes[0].scatter(fitted, resid, alpha=0.5)
axes[0].axhline(0, color='red', linestyle='--')
axes[0].set_xlabel('예측값')
axes[0].set_ylabel('잔차')
axes[0].set_title('잔차 플롯 (패턴 없어야 좋음)')
stats.probplot(resid, plot=axes[1])
axes[1].set_title('Q-Q 플롯 (직선에 가까울수록 정규분포)')
plt.tight_layout()
plt.show()
```

---

### ⑤ 편상관분석 (제3 변수 통제 후 순수 관계)

언제: "나이의 영향을 제거하고 학습시간과 성적의 관계만 보고 싶어"

```python
from pingouin import partial_corr

x_var      = '관심_변수1'
y_var      = '관심_변수2'
covar_vars = ['통제_변수1', '통제_변수2']

result = partial_corr(data=df, x=x_var, y=y_var, covar=covar_vars)
print(result)
r   = result['r'].values[0]
p   = result['p-val'].values[0]
print(f"\n편상관계수: {r:.4f}")
print(f"p-value: {p:.4f} → {'유의미 ✅' if p < 0.05 else '유의미하지 않음 ❌'}")
print(f"해석: {covar_vars}의 영향을 제거했을 때 {x_var}와 {y_var}의 관계는 {'존재' if p < 0.05 else '없음'}")

# 결과 저장
results.append({
    "검정종류": "편상관분석",
    "변수(그룹)": x_var,
    "변수(값)": y_var,
    "그룹1": f"통제변수={covar_vars}",
    "그룹2": "",
    "통계량": round(float(r), 4),
    "p_value": round(float(p), 4),
    "유의수준(0.05)": "유의함" if p < 0.05 else "유의하지않음",
    "결론": f"편상관계수={r:.3f}, 관계 {'존재' if p < 0.05 else '없음'}"
})
```

---

### ⑥ Fisher's Exact Test (소표본 카이제곱 대체)

언제: 셀 기댓값이 5 미만인 셀이 있을 때 카이제곱 대신 사용

```python
from scipy.stats import fisher_exact

row_col = '행_변수'
col_col = '열_변수'
ct = pd.crosstab(df[row_col], df[col_col])
print("교차표:")
print(ct)

# 기댓값 확인
chi2, _, _, expected = stats.chi2_contingency(ct)
low_expected = (expected < 5).sum()
print(f"\n기댓값 5 미만 셀: {low_expected}개 {'→ Fisher 사용 권장' if low_expected > 0 else '→ 카이제곱도 가능'}")

# 2×2 표일 때만 Fisher 직접 계산
if ct.shape == (2, 2):
    odds, p_val = fisher_exact(ct)
    print(f"\nFisher's Exact Test: p-value={p_val:.4f}, Odds Ratio={odds:.4f}")
    print(f"→ {'두 변수는 관련 있음 ✅' if p_val < 0.05 else '두 변수는 독립 ❌'}")
    results.append({
        "검정종류": "Fisher's Exact Test",
        "변수(그룹)": row_col,
        "변수(값)": col_col,
        "그룹1": f"기댓값5미만셀={low_expected}개",
        "그룹2": f"OR={odds:.3f}",
        "통계량": round(float(odds), 4),
        "p_value": round(float(p_val), 4),
        "유의수준(0.05)": "유의함" if p_val < 0.05 else "유의하지않음",
        "결론": f"OR={odds:.3f}, {'관련있음' if p_val < 0.05 else '독립'}"
    })
else:
    print("2×2 표가 아니므로 카이제곱+Yates 보정 사용")
    chi2, p_val, _, _ = stats.chi2_contingency(ct, correction=True)
    print(f"카이제곱(보정): {chi2:.4f}, p-value: {p_val:.4f}")
    results.append({
        "검정종류": "카이제곱(Yates 보정)",
        "변수(그룹)": row_col,
        "변수(값)": col_col,
        "그룹1": f"기댓값5미만셀={low_expected}개",
        "그룹2": "",
        "통계량": round(float(chi2), 4),
        "p_value": round(float(p_val), 4),
        "유의수준(0.05)": "유의함" if p_val < 0.05 else "유의하지않음",
        "결론": f"{'관련있음' if p_val < 0.05 else '독립'}"
    })
```

---

### ⑦ 다중비교 보정 (여러 검정 동시 수행 시 오류 제어)

언제: "10개 변수를 모두 검정했더니 p<0.05가 3개 나왔는데 믿을 수 있나?"

```python
from statsmodels.stats.multicomp import multipletests

# 여러 p-value를 한 번에 보정
p_values = [0.03, 0.04, 0.001, 0.08, 0.02]  # 각 검정의 p-value 목록
labels   = ['변수A', '변수B', '변수C', '변수D', '변수E']

# Bonferroni 보정 (가장 보수적)
reject_b, p_adj_b, _, _ = multipletests(p_values, method='bonferroni')
# FDR Benjamini-Hochberg 보정 (덜 보수적, 탐색적 연구에 적합)
reject_f, p_adj_f, _, _ = multipletests(p_values, method='fdr_bh')

result_df = pd.DataFrame({
    '변수': labels,
    '원래 p-value': p_values,
    'Bonferroni 보정': p_adj_b.round(4),
    'Bonferroni 유의': reject_b,
    'FDR 보정': p_adj_f.round(4),
    'FDR 유의': reject_f
})
print(result_df.to_string(index=False))
print("\n※ 보정 전 유의했던 것이 보정 후 사라지면 우연일 가능성이 높습니다.")

# 결과 저장
for _, row in result_df.iterrows():
    results.append({
        "검정종류": "다중비교 보정",
        "변수(그룹)": row['변수'],
        "변수(값)": "",
        "그룹1": f"원래p={row['원래 p-value']}",
        "그룹2": f"Bonferroni={row['Bonferroni 보정']}",
        "통계량": row['FDR 보정'],
        "p_value": row['원래 p-value'],
        "유의수준(0.05)": "유의함(FDR)" if row['FDR 유의'] else "유의하지않음",
        "결론": f"Bonferroni={'유의' if row['Bonferroni 유의'] else '비유의'}, FDR={'유의' if row['FDR 유의'] else '비유의'}"
    })
```

---

### 마지막 셀: stats-advanced_result.csv 저장

모든 검정이 끝난 후 마지막 코드 셀에 반드시 아래 코드를 추가해 stats-advanced_result.csv를 저장하세요.

```python
results_df = pd.DataFrame(results)

col_order = ["검정종류", "변수(그룹)", "변수(값)", "그룹1", "그룹2",
             "통계량", "p_value", "유의수준(0.05)", "결론"]
results_df = results_df[[c for c in col_order if c in results_df.columns]]

output_path = "stats-advanced_result.csv"
results_df.to_csv(output_path, index=False, encoding='utf-8-sig')

print(f"✅ stats-advanced_result.csv 저장 완료: {len(results_df)}개 검정 결과")
print(results_df.to_string(index=False))
```

---

### 노트북 실행 (결과 내장)

```bash
pip install scipy statsmodels scikit-learn pingouin jupyter nbconvert --quiet
jupyter nbconvert --to notebook --execute \
  --ExecutePreprocessor.timeout=180 \
  --output stats-advanced.ipynb \
  stats-advanced.ipynb
```

---

---

## Context Validation

분석 시작 전 아래 항목을 확인하세요:
- [ ] `stats-basic_result.csv` 및 `stats-basic_report.md` 확인 완료
- [ ] 기초 검정에서 심화 분석이 필요한 결과를 명확히 파악했는가
- [ ] 전후 비교 데이터인지 / 이원 요인인지 / 소표본 카이제곱인지 유형 확인
- [ ] 다중 검정 수행 시 Bonferroni/FDR 보정 적용 예정 확인
- [ ] 표본 크기가 심화 검정에 충분한가 (로지스틱 회귀 최소 이벤트 10개 이상 권장)

---

## Output Template


```markdown
# 심화 통계 분석 보고서

> **파일**: {파일명} | **분석일**: {날짜} | **사용한 검정**: {검정 종류}

## 1. 분석 목적
(사용자가 알고 싶었던 것, 기초 검정과 어떻게 다른지)

## 2. 검정 선택 이유
(왜 심화 검정이 필요했는지 — 초보자도 이해할 수 있게)

## 3. 주요 인사이트
(검정 결과를 쉬운 말로 해석. 수치만 나열하지 말고 실제 의미 설명)

## 4. 기초 검정과의 비교 (해당 시)
(csv-stats-basic 결과가 있으면, 기초 vs 심화 결과 비교)

## 5. 한계 및 주의사항
(가정 충족 여부, 표본 크기, 인과관계 주의 등)

## 6. 추천 다음 단계
(머신러닝 모델로 이어지는 방향 제안 등)
```

---

### 최종 출력물

| 파일 | 내용 |
|------|------|
| `stats-advanced.ipynb` | 심화 통계 코드 + 실행결과(차트, 검정 결과) 내장 |
| `stats-advanced_result.csv` | 검정 결과 요약표 (통계량, p-value, 결론 — 엑셀에서 바로 열 수 있음) |
| `stats-advanced_report.md` | 검정 결과를 쉬운 말로 해석한 한국어 보고서 |

**저장 경로 결정 우선순위:**
1. 사용자가 명시적으로 저장 위치를 지정한 경우 → 해당 경로 사용
2. 사용자가 폴더를 선택(마운트)한 경우 → 마운트된 폴더 안에 저장
3. 위 두 경우가 아니면 → `mnt/outputs/` 폴더에 저장

별도 PNG 파일은 생성하지 않습니다. 차트는 노트북 안에 포함됩니다.

---

## 심화 용어 쉬운 말 설명

- **대응표본**: 같은 사람/대상을 두 번 측정한 것 (독립표본과 달리 "짝이 있음")
- **이원 ANOVA**: 두 개의 그룹 변수가 동시에 결과에 미치는 영향 분석
- **상호작용 효과**: A의 효과가 B의 수준에 따라 달라지는 현상
- **로지스틱 회귀**: 결과가 Yes/No일 때 쓰는 회귀 (확률을 예측)
- **AUC-ROC**: 분류 모델의 성능 지표. 0.5=랜덤, 1.0=완벽 (0.7 이상이면 쓸만함)
- **혼동 행렬**: 모델이 맞힌 것과 틀린 것을 표로 정리한 것
- **편상관**: 다른 변수들의 영향을 제거한 "순수한" 두 변수 관계
- **다중비교 보정**: 검정을 많이 할수록 우연히 유의미해질 확률이 올라가므로 기준을 엄격하게 조정
- **Bonferroni**: 가장 엄격한 보정 (오류 최소화, 하지만 진짜도 놓칠 수 있음)
- **FDR**: 탐색적 연구에 적합한 보정 (Bonferroni보다 덜 엄격)
