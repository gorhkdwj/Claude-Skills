---
name: stats-basic
description: |
  표 형식 데이터(CSV·JSON·Parquet·Excel 등)를 받아 기초 통계 검정을 수행하는 스킬.
  EDA(탐색적 분석) 이후 첫 번째 가설 검정 단계로,
  단일표본 t-검정, 독립표본 t-검정, 일원 ANOVA, 카이제곱 검정, 상관분석(Pearson/Spearman),
  단순 선형 회귀를 수행합니다.
  분석 코드가 담긴 Jupyter Notebook(stats-basic.ipynb), 검정 결과 요약표(stats-basic_result.csv),
  한국어 해석 보고서(stats-basic_report.md)를 제공합니다.

  다음 상황에서 반드시 이 스킬을 사용하세요:
  - "우리 평균이 기준값(전국 평균 등)과 다른지 확인해줘" → 단일표본 t-검정
  - "두 그룹 차이가 있는지 검정해줘", "남녀 차이 비교해줘" → 독립표본 t-검정
  - "세 그룹 이상 평균 비교해줘", "지역별/연령대별 차이 있어?" → 일원 ANOVA
  - "두 범주형 변수 관련 있어?", "성별과 구매 여부 관계 있어?" → 카이제곱 검정
  - "두 변수가 관련 있어?", "상관관계 분석해줘", "관계 파악해줘" → 상관분석
  - "X가 1 증가하면 Y가 얼마나 변해?", "영향력을 수식으로 표현해줘" → 단순 선형 회귀
  - "EDA 다음에 뭐 해야 해?", "어떤 변수가 유의미해?" → 기초 검정 전체
  - "통계 검정해줘", "유의미한지 확인해줘", "p-value 구해줘" 등의 표현
  - programmatic-eda로 EDA를 마친 후 가설 검정이 필요할 때
  - 심화 분석(stats-advanced) 전 기초 검정이 필요할 때
---

# 기초 통계 검정 스킬

이 스킬은 **EDA → 기초 검정 → 심화 분석** 3단계 워크플로우의 **중간 단계**입니다. EDA에서 발견한 패턴을 통계적으로 검증하고, 필요하면 심화 분석으로 자연스럽게 이어갑니다.

출력물: `stats-basic.ipynb`(검정 과정 코드) + `stats-basic_result.csv`(검정 결과 요약표) + `stats-basic_report.md`(한국어 해석 보고서)

## Phase
Phase 4 — 분석 수행 (범용 도구 레이어)

## Input
- 이전 스킬: programmatic-eda (또는 data-quality-audit)
- 받는 파일: `eda_result.csv` 또는 이전 분석의 `*_result.csv`

## 전처리 관련 안내

통계 검정은 ML과 달리 전체 전처리(data-preprocessing)가 필수가 아닙니다.
검정 전에 필요한 처리는 아래 두 가지로 한정됩니다:

- **결측값이 있는 경우**: data-preprocessing의 결측값 처리 단계만 먼저 권장합니다.
  인코딩·스케일링은 통계 검정에 불필요하며, 오히려 해석을 왜곡할 수 있습니다.
- **분포가 심하게 비대칭인 경우 (왜도 > 1)**: t-검정·ANOVA는 정규성을 가정합니다.
  로그 변환(`np.log1p`)으로 정규성에 가깝게 만든 후 검정하면 더 신뢰할 수 있는 결과를 얻습니다.
  변환 전후 왜도를 비교해 변환 효과를 확인하세요.

```python
# 정규성 가정 확인 및 로그 변환 예시
from scipy import stats

for col in numeric_cols:
    skewness = df[col].skew()
    if abs(skewness) > 1:
        df[f'{col}_log'] = np.log1p(df[col])
        new_skew = df[f'{col}_log'].skew()
        print(f"  '{col}': 왜도 {skewness:.2f} → 로그 변환 후 {new_skew:.2f}")
        print(f"  ⚠️  t-검정/ANOVA 시 '{col}_log' 컬럼 사용을 권장합니다.")
```

## Output
- `stats-basic.ipynb` — 검정 과정 코드 (시각화 차트 포함, 실행 결과 내장)
- `stats-basic_result.csv` — 검정 결과 요약표 (통계량, p-value, 결론)
- `stats-basic_report.md` — 검정 결과를 쉬운 말로 해석한 한국어 보고서

---

## Quick Start

기초 검정의 핵심은 **"우연인가, 진짜 차이인가"**를 판단하는 것입니다. p-value 숫자만 나열하지 말고, "이 차이가 왜 중요한지", "실제로 어떤 의미인지"를 초보자도 이해할 수 있는 언어로 설명하세요.

---

## Context Requirements

1. **데이터**: 분석할 표 형식 파일 (CSV·JSON·Parquet·Excel·TSV)
2. **분석 목적**: 어떤 가설 또는 차이를 검정하려는지
3. **이전 EDA 결과** (선택): `eda_report.md` 또는 `eda_result.csv`
4. **변수 타입**: 수치형 컬럼 vs 범주형 컬럼 구분

---

## Context Gathering

사용자가 이미 EDA를 수행했다면, Read 툴로 이전 `eda_report.md`를 먼저 확인하세요. 코드 실행이 아닌 파일 직접 탐색으로 진행합니다.

**확인할 내용:**
- EDA에서 주목된 변수와 패턴
- 데이터 타입 (연속형 vs 범주형)
- 결측치나 이상치 처리 여부

맥락 확인 후, 어떤 검정을 수행할지 한 줄로 먼저 알려주세요.
예: "수치형 변수 2개 → 상관분석, 범주형 2개 → 카이제곱 검정을 수행합니다."

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

DATA_PATH    = "데이터_파일_경로.csv"  # ← 매 실행 시 이 줄만 변경

# 도메인 설정 (최초 1회 확정 후 고정)
GROUP_COL    = None    # 그룹 비교 컬럼 (예: "region", "gender")
VALUE_COL    = None    # 검정할 수치 컬럼 (예: "score", "revenue")
TEST_TYPE    = "auto"  # "auto" | "ttest" | "anova" | "chi2" | "correlation" | "regression"
ALPHA        = 0.05    # 유의수준
DOMAIN_NOTES = []      # 비즈니스 규칙 메모

# ════════════════════════════════════════════════════════════════
```

### 검정 선택 가이드

사용자가 명시하지 않았다면, 데이터 특성에 따라 아래 기준으로 검정을 선택하세요:

| 상황 | 적합한 검정 |
|------|------------|
| 수치형 변수 하나, 기준값과 비교 | 단일표본 t-검정 |
| 수치형 변수, 그룹 2개 비교 | 독립표본 t-검정 |
| 수치형 변수, 그룹 3개 이상 비교 | 일원 ANOVA |
| 범주형 변수 2개의 관계 | 카이제곱 검정 |
| 수치형 변수 2개의 관계 파악 | 상관분석 (Pearson/Spearman) |
| X → Y 영향력을 수식으로 표현 | 단순 선형 회귀 |

데이터에 해당하는 검정이 여러 개라면, 모두 수행하고 종합적으로 해석하세요.

---

### 셀 2: 라이브러리 로드 및 데이터 로드 + 드리프트 탐지

```python
import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
import matplotlib
import seaborn as sns
import json, os, warnings
from scipy import stats
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
check_schema_drift(df, "stats-basic_baseline_schema.json")
df.head()

# 결과 누적용 리스트 (마지막 셀에서 stats-basic_result.csv로 저장)
results = []
```

---

### 검정별 코드 패턴

### ① 단일표본 t-검정 (기준값과 비교)

언제: "우리 고객 평균 나이가 전국 평균(35세)과 다른가?", 한 그룹의 평균이 특정 기준값과 차이가 있는지 확인

```python
from scipy.stats import ttest_1samp, shapiro

value_col = '수치_컬럼'    # 예: '나이'
mu0 = 35                   # 비교 기준값 (예: 전국 평균)

data = df[value_col].dropna()

# 정규성 확인
_, p_norm = shapiro(data)
print(f"정규성 검정: p={p_norm:.4f} → {'정규분포 ✅' if p_norm > 0.05 else '비정규 ⚠️ (해석 참고)'}")

t_stat, p_val = ttest_1samp(data, popmean=mu0)
conclusion = f"기준값({mu0})과 유의미한 차이 있음" if p_val < 0.05 else f"기준값({mu0})과 유의미한 차이 없음"

print(f"\n단일표본 t-검정 결과")
print(f"표본 평균: {data.mean():.2f}, 기준값: {mu0}")
print(f"t-통계량: {t_stat:.4f}, p-value: {p_val:.4f}")
print(f"→ {conclusion}")

# 결과 저장
results.append({
    "검정종류": "단일표본 t-검정",
    "변수(그룹)": value_col,
    "변수(값)": f"기준값={mu0}",
    "그룹1": f"표본평균={data.mean():.2f} (n={len(data)})",
    "그룹2": f"기준값={mu0}",
    "통계량": round(t_stat, 4),
    "p_value": round(p_val, 4),
    "유의수준(0.05)": "유의함" if p_val < 0.05 else "유의하지않음",
    "결론": conclusion
})

# 시각화
fig, ax = plt.subplots(figsize=(8, 5))
ax.hist(data, bins=20, edgecolor='black', alpha=0.7)
ax.axvline(data.mean(), color='blue', linestyle='-', linewidth=2, label=f'표본 평균 ({data.mean():.1f})')
ax.axvline(mu0, color='red', linestyle='--', linewidth=2, label=f'기준값 ({mu0})')
ax.set_title(f'{value_col} 분포 vs 기준값')
ax.set_xlabel(value_col)
ax.legend()
plt.tight_layout()
plt.show()
```

---

### ② 독립표본 t-검정 (두 그룹 평균 비교)

언제: "남성과 여성의 평균 점수가 다른가?", 두 그룹 간 수치형 변수 비교

```python
from scipy.stats import ttest_ind, mannwhitneyu, levene, shapiro

group_col = '그룹_컬럼'    # 예: '성별'
value_col = '수치_컬럼'    # 예: '점수'

groups = df[group_col].unique()
g1 = df[df[group_col] == groups[0]][value_col].dropna()
g2 = df[df[group_col] == groups[1]][value_col].dropna()

# 1) 정규성 검정 (Shapiro-Wilk)
_, p_norm1 = shapiro(g1)
_, p_norm2 = shapiro(g2)
print(f"정규성 검정: {groups[0]} p={p_norm1:.4f}, {groups[1]} p={p_norm2:.4f}")
is_normal = (p_norm1 > 0.05) and (p_norm2 > 0.05)

# 2) 등분산 검정 (Levene)
_, p_levene = levene(g1, g2)
print(f"등분산 검정: p={p_levene:.4f} → {'등분산 ✅' if p_levene > 0.05 else '이분산 ⚠️'}")
equal_var = p_levene > 0.05

if is_normal:
    t_stat, p_val = ttest_ind(g1, g2, equal_var=equal_var)
    test_name = "독립표본 t-검정"
else:
    t_stat, p_val = mannwhitneyu(g1, g2, alternative='two-sided')
    test_name = "Mann-Whitney U 검정 (비모수 대체)"

conclusion = "유의미한 차이 있음" if p_val < 0.05 else "유의미한 차이 없음"
print(f"\n{test_name} 결과")
print(f"통계량: {t_stat:.4f}, p-value: {p_val:.4f}")
print(f"{groups[0]} 평균: {g1.mean():.2f}, {groups[1]} 평균: {g2.mean():.2f}")
print(f"→ {conclusion}")

# 결과 저장
results.append({
    "검정종류": test_name,
    "변수(그룹)": group_col,
    "변수(값)": value_col,
    "그룹1": f"{groups[0]} (평균={g1.mean():.2f})",
    "그룹2": f"{groups[1]} (평균={g2.mean():.2f})",
    "통계량": round(t_stat, 4),
    "p_value": round(p_val, 4),
    "유의수준(0.05)": "유의함" if p_val < 0.05 else "유의하지않음",
    "결론": conclusion
})

# 시각화
fig, axes = plt.subplots(1, 2, figsize=(12, 5))
df.boxplot(column=value_col, by=group_col, ax=axes[0])
axes[0].set_title(f'{group_col}별 {value_col} 분포')
axes[0].set_xlabel(group_col)

for g, label in zip([g1, g2], groups):
    axes[1].hist(g, alpha=0.6, label=str(label), bins=15, edgecolor='black')
axes[1].set_title('그룹별 분포 비교')
axes[1].legend()
plt.tight_layout()
plt.show()
```

---

### ③ 일원 ANOVA (세 그룹 이상 평균 비교)

언제: "지역(서울/부산/대구)별 매출이 다른가?", 3개 이상 그룹 비교

```python
from scipy.stats import f_oneway, kruskal
from statsmodels.stats.multicomp import pairwise_tukeyhsd

group_col = '그룹_컬럼'    # 예: '지역'
value_col = '수치_컬럼'    # 예: '매출'

groups_list = [df[df[group_col] == g][value_col].dropna() for g in df[group_col].unique()]
group_labels = df[group_col].unique()

# 정규성 간이 확인
all_normal = all(stats.shapiro(g).pvalue > 0.05 for g in groups_list if len(g) >= 3)

if all_normal:
    stat, p_val = f_oneway(*groups_list)
    test_name = "일원 ANOVA"
else:
    stat, p_val = kruskal(*groups_list)
    test_name = "Kruskal-Wallis 검정 (비모수 대체)"

print(f"{test_name} 결과")
print(f"통계량: {stat:.4f}, p-value: {p_val:.4f}")
for g, label in zip(groups_list, group_labels):
    print(f"  {label}: 평균={g.mean():.2f}, n={len(g)}")

conclusion_anova = "그룹 간 유의미한 차이 있음" if p_val < 0.05 else "그룹 간 유의미한 차이 없음"
if p_val < 0.05:
    print("→ 그룹 간 통계적으로 유의미한 차이가 있습니다 (p < 0.05)")
    print("→ 어느 그룹 간 차이인지 Tukey HSD 사후검정으로 확인합니다.\n")
    tukey = pairwise_tukeyhsd(
        df[value_col].dropna(),
        df.loc[df[value_col].notna(), group_col]
    )
    print(tukey)
    # 사후검정 결과도 results에 추가
    tukey_df = pd.DataFrame(data=tukey._results_table.data[1:], columns=tukey._results_table.data[0])
    for _, row in tukey_df.iterrows():
        results.append({
            "검정종류": "Tukey HSD 사후검정",
            "변수(그룹)": group_col,
            "변수(값)": value_col,
            "그룹1": str(row['group1']),
            "그룹2": str(row['group2']),
            "통계량": round(float(row['meandiff']), 4),
            "p_value": round(float(row['p-adj']), 4),
            "유의수준(0.05)": "유의함" if row['reject'] else "유의하지않음",
            "결론": f"평균차이={row['meandiff']:.2f}, {'유의미한 차이' if row['reject'] else '차이없음'}"
        })
else:
    print("→ 그룹 간 유의미한 차이가 없습니다 (p ≥ 0.05)")

# ANOVA 결과 저장
results.append({
    "검정종류": test_name,
    "변수(그룹)": group_col,
    "변수(값)": value_col,
    "그룹1": " / ".join([f"{l}(평균={g.mean():.1f})" for l, g in zip(group_labels, groups_list)]),
    "그룹2": "",
    "통계량": round(stat, 4),
    "p_value": round(p_val, 4),
    "유의수준(0.05)": "유의함" if p_val < 0.05 else "유의하지않음",
    "결론": conclusion_anova
})

# 시각화
fig, ax = plt.subplots(figsize=(10, 5))
df.boxplot(column=value_col, by=group_col, ax=ax)
ax.set_title(f'{group_col}별 {value_col} 비교')
ax.set_xlabel(group_col)
plt.tight_layout()
plt.show()
```

---

### ④ 카이제곱 검정 (범주형 변수 간 독립성)

언제: "성별과 구매 여부가 관련 있는가?", 두 범주형 변수의 관계

```python
row_col = '행_변수'    # 예: '성별'
col_col = '열_변수'    # 예: '구매여부'

ct = pd.crosstab(df[row_col], df[col_col])
print("교차표 (빈도):")
print(ct)
print("\n교차표 (비율 %):")
print((ct / ct.sum().sum() * 100).round(1))

# 기댓값 확인 (5 미만 셀이 많으면 검정이 부정확할 수 있음)
chi2, p_val, dof, expected = stats.chi2_contingency(ct)
low_cells = (expected < 5).sum()
print(f"\n기댓값 5 미만 셀 수: {low_cells}개")
if low_cells > 0:
    print("⚠️ 셀 수가 부족하면 결과가 부정확할 수 있습니다. 심화 분석의 Fisher's Exact Test를 고려하세요.")

conclusion_chi = f"{row_col}과 {col_col} 관련 있음" if p_val < 0.05 else f"{row_col}과 {col_col} 독립(관련없음)"
print(f"\n카이제곱 검정 결과")
print(f"카이제곱 통계량: {chi2:.4f}, 자유도: {dof}, p-value: {p_val:.4f}")
print(f"→ {conclusion_chi}")

# 결과 저장
results.append({
    "검정종류": "카이제곱 검정",
    "변수(그룹)": row_col,
    "변수(값)": col_col,
    "그룹1": f"기댓값5미만셀={low_cells}개",
    "그룹2": f"자유도={dof}",
    "통계량": round(chi2, 4),
    "p_value": round(p_val, 4),
    "유의수준(0.05)": "유의함" if p_val < 0.05 else "유의하지않음",
    "결론": conclusion_chi
})

# 시각화: 누적 막대 그래프
ct_pct = ct.div(ct.sum(axis=1), axis=0) * 100
ct_pct.plot(kind='bar', stacked=True, figsize=(8, 5), colormap='Set2')
plt.title(f'{row_col}별 {col_col} 비율')
plt.xlabel(row_col)
plt.ylabel('비율 (%)')
plt.xticks(rotation=0)
plt.legend(title=col_col, bbox_to_anchor=(1.05, 1))
plt.tight_layout()
plt.show()
```

---

### ⑤ 상관분석 (수치형 변수 간 관계)

언제: "공부 시간과 성적이 관련 있는가?", 두 수치형 변수의 선형 관계

```python
# 분석할 수치형 변수 목록 (전체 또는 선택)
numeric_cols = df.select_dtypes(include='number').columns.tolist()

# 전체 상관행렬 시각화
corr_matrix = df[numeric_cols].corr(method='pearson')

fig, axes = plt.subplots(1, 2, figsize=(14, 6))

# 히트맵
sns.heatmap(corr_matrix, annot=True, fmt='.2f', cmap='RdBu_r',
            center=0, vmin=-1, vmax=1, ax=axes[0], square=True)
axes[0].set_title('Pearson 상관계수 히트맵\n(빨강=양의 상관, 파랑=음의 상관)')

# 강한 상관관계 (|r| > 0.5) 요약
strong_pairs = []
for i in range(len(corr_matrix.columns)):
    for j in range(i+1, len(corr_matrix.columns)):
        r = corr_matrix.iloc[i, j]
        if abs(r) > 0.5:
            strong_pairs.append((corr_matrix.columns[i], corr_matrix.columns[j], r))

if strong_pairs:
    axes[1].axis('off')
    text = "강한 상관관계 (|r| > 0.5):\n\n"
    for v1, v2, r in sorted(strong_pairs, key=lambda x: abs(x[2]), reverse=True):
        direction = "양의" if r > 0 else "음의"
        text += f"• {v1} ↔ {v2}\n  r = {r:.3f} ({direction} 상관)\n\n"
    axes[1].text(0.05, 0.95, text, transform=axes[1].transAxes,
                 verticalalignment='top', fontsize=10, family='monospace')
    axes[1].set_title('주목할 변수 쌍')
else:
    axes[1].text(0.5, 0.5, '강한 상관관계(|r|>0.5)\n없음',
                 ha='center', va='center', transform=axes[1].transAxes)
    axes[1].axis('off')

plt.tight_layout()
plt.show()

# 특정 두 변수 간 산점도 (가장 강한 상관 쌍)
if strong_pairs:
    v1, v2, r = strong_pairs[0]
    fig, ax = plt.subplots(figsize=(7, 5))
    ax.scatter(df[v1], df[v2], alpha=0.5)
    # 추세선
    mask = df[[v1, v2]].dropna()
    z = np.polyfit(mask[v1], mask[v2], 1)
    p = np.poly1d(z)
    ax.plot(sorted(mask[v1]), p(sorted(mask[v1])), 'r--', label=f'추세선 (r={r:.3f})')
    ax.set_xlabel(v1)
    ax.set_ylabel(v2)
    ax.set_title(f'{v1} vs {v2} 산점도')
    ax.legend()
    plt.tight_layout()
    plt.show()

# Spearman 상관계수도 제공 (비선형/이상치 강인)
print("\nSpearman 상관계수 (순위 기반, 비선형 관계에 강함):")
spearman_corr = df[numeric_cols].corr(method='spearman')
print(spearman_corr.round(3))

# 상관분석 결과 저장 (변수 쌍별로)
for i in range(len(corr_matrix.columns)):
    for j in range(i+1, len(corr_matrix.columns)):
        v1 = corr_matrix.columns[i]
        v2 = corr_matrix.columns[j]
        r_p = corr_matrix.iloc[i, j]
        r_s = spearman_corr.iloc[i, j]
        _, pval_p = stats.pearsonr(df[v1].dropna(), df[v2].dropna())
        _, pval_s = stats.spearmanr(df[v1].dropna(), df[v2].dropna())
        strength = "강함(|r|>0.7)" if abs(r_p) > 0.7 else ("중간(|r|>0.5)" if abs(r_p) > 0.5 else "약함(|r|≤0.5)")
        results.append({
            "검정종류": "Pearson 상관분석",
            "변수(그룹)": v1,
            "변수(값)": v2,
            "그룹1": "",
            "그룹2": "",
            "통계량": round(r_p, 4),
            "p_value": round(pval_p, 4),
            "유의수준(0.05)": "유의함" if pval_p < 0.05 else "유의하지않음",
            "결론": f"r={r_p:.3f}({strength}), Spearman_r={r_s:.3f}"
        })
```

---

### ⑥ 단순 선형 회귀 (X → Y 영향력 수식화)

언제: 상관분석에서 관계가 확인된 두 변수를 "X가 1 증가할 때 Y가 얼마나 변하는가"로 수식화할 때

```python
import statsmodels.api as sm

x_col = 'X_컬럼'    # 예: '광고비'  (원인으로 볼 수 있는 변수)
y_col = 'Y_컬럼'    # 예: '매출'    (결과 변수)

data_reg = df[[x_col, y_col]].dropna()
X = sm.add_constant(data_reg[x_col])
y = data_reg[y_col]

model = sm.OLS(y, X).fit()

slope = model.params[x_col]
intercept = model.params['const']
r_squared = model.rsquared
p_val = model.pvalues[x_col]

print(f"단순 선형 회귀 결과")
print(f"회귀식: {y_col} = {slope:.3f} × {x_col} + {intercept:.3f}")
print(f"R²: {r_squared:.4f} → {x_col}이 {y_col} 변동의 {r_squared*100:.1f}%를 설명")
print(f"기울기 p-value: {p_val:.4f} → {'유의미한 영향 ✅' if p_val < 0.05 else '유의미하지 않음 ❌'}")
print(f"\n해석: {x_col}이 1 증가할 때 {y_col}은 평균 {slope:+.3f} 변화")

# 결과 저장
results.append({
    "검정종류": "단순 선형 회귀",
    "변수(그룹)": x_col,
    "변수(값)": y_col,
    "그룹1": f"기울기={slope:.3f}",
    "그룹2": f"절편={intercept:.3f}",
    "통계량": round(r_squared, 4),
    "p_value": round(p_val, 4),
    "유의수준(0.05)": "유의함" if p_val < 0.05 else "유의하지않음",
    "결론": f"R²={r_squared:.3f}, {x_col}+1→{y_col}{slope:+.3f}"
})

# 시각화: 산점도 + 회귀선
fig, axes = plt.subplots(1, 2, figsize=(14, 5))

axes[0].scatter(data_reg[x_col], data_reg[y_col], alpha=0.5)
x_line = np.linspace(data_reg[x_col].min(), data_reg[x_col].max(), 100)
axes[0].plot(x_line, slope * x_line + intercept, 'r-', linewidth=2,
             label=f'회귀선 (R²={r_squared:.3f})')
axes[0].set_xlabel(x_col)
axes[0].set_ylabel(y_col)
axes[0].set_title(f'단순 선형 회귀: {x_col} → {y_col}')
axes[0].legend()

# 잔차 플롯 (패턴 없어야 좋음)
residuals = model.resid
axes[1].scatter(model.fittedvalues, residuals, alpha=0.5)
axes[1].axhline(0, color='red', linestyle='--')
axes[1].set_xlabel('예측값')
axes[1].set_ylabel('잔차')
axes[1].set_title('잔차 플롯 (무작위 분포면 OK)')

plt.tight_layout()
plt.show()
```

---

### 마지막 셀: stats-basic_result.csv 저장

모든 검정이 끝난 후 마지막 코드 셀에 반드시 아래 코드를 추가해 stats-basic_result.csv를 저장하세요.

```python
# 검정 결과를 CSV로 저장
results_df = pd.DataFrame(results)

# 컬럼 순서 정리
col_order = ["검정종류", "변수(그룹)", "변수(값)", "그룹1", "그룹2",
             "통계량", "p_value", "유의수준(0.05)", "결론"]
results_df = results_df[[c for c in col_order if c in results_df.columns]]

output_path = "stats-basic_result.csv"  # 저장 경로는 아래 "저장 경로 결정 우선순위" 참고
results_df.to_csv(output_path, index=False, encoding='utf-8-sig')  # utf-8-sig: 엑셀에서 한글 깨짐 방지

print(f"✅ stats-basic_result.csv 저장 완료: {len(results_df)}개 검정 결과")
print(results_df.to_string(index=False))
```

**stats-basic_result.csv 구조 예시:**

| 검정종류 | 변수(그룹) | 변수(값) | 통계량 | p_value | 유의수준(0.05) | 결론 |
|---------|-----------|---------|--------|---------|--------------|------|
| 단일표본 t-검정 | 나이 | 기준값=35 | 2.14 | 0.034 | 유의함 | 기준값(35)과 유의미한 차이 있음 |
| 독립표본 t-검정 | 성별 | 수학점수 | -3.559 | 0.0006 | 유의함 | 유의미한 차이 있음 |
| 일원 ANOVA | 지역 | 매출 | 13.352 | 0.0000 | 유의함 | 그룹 간 유의미한 차이 있음 |
| 카이제곱 검정 | 연령대 | 구매여부 | 3.579 | 0.1671 | 유의하지않음 | 독립(관련없음) |
| Pearson 상관분석 | 광고비 | 매출 | 0.676 | 0.0000 | 유의함 | r=0.676(중간), Spearman_r=0.692 |
| 단순 선형 회귀 | 광고비 | 매출 | 0.458 | 0.0000 | 유의함 | R²=0.458, 광고비+1→매출+1.61 |

---

## Context Validation

분석 시작 전 아래 항목을 확인하세요:
- [ ] 분석 파일 경로 및 형식 확인 (CSV·JSON·Parquet·Excel·TSV)
- [ ] 검정 목적이 명확한가 (어떤 차이/관계를 확인하려는가)
- [ ] 이전 EDA 결과(`eda_report.md`)를 확인했는가 (없으면 CSV 직접 파악)
- [ ] 데이터 타입이 올바른가 (수치형 vs 범주형)
- [ ] 표본 크기가 충분한가 (t-검정 최소 30개, 카이제곱 기댓값 5 이상 권장)

---

## Output Template


모든 검정이 끝난 후 아래 구조로 `stats-basic_report.md`를 작성하세요.

```markdown
# 기초 통계 검정 보고서

> **파일**: {파일명} | **분석일**: {날짜} | **수행 검정**: {검정 종류 목록}

## 1. 분석 목적
(사용자가 알고 싶었던 것, EDA에서 발견한 패턴을 검증하려는 맥락)

## 2. 검정 결과 요약
(각 검정별로 — 수치 나열 말고 쉬운 말로 해석)
- **단일표본 t-검정**: ...
- **독립표본 t-검정**: ...
- **일원 ANOVA**: ...
- **카이제곱 검정**: ...
- **상관분석**: ...
- **단순 선형 회귀**: ...

## 3. 핵심 인사이트
(유의미한 결과를 종합해서 3가지 이내로 요약. "p<0.05였습니다"가 아니라 실제 의미 설명)

## 4. 한계 및 주의사항
(표본 크기, 정규성 위배 여부, 인과관계 혼동 주의 등)

## 5. 추천 다음 단계
(심화 분석(stats-advanced)으로 이어지는 방향 제안)
```

---

### 노트북 실행 (코드 확인용)

```bash
pip install scipy statsmodels jupyter nbconvert --quiet
jupyter nbconvert --to notebook --execute \
  --ExecutePreprocessor.timeout=180 \
  --output stats-basic.ipynb \
  stats-basic.ipynb
```

---

### 최종 출력물

| 파일 | 내용 |
|------|------|
| `stats-basic.ipynb` | 검정 과정 코드 (시각화 차트 포함, 실행 결과 내장) |
| `stats-basic_result.csv` | 검정 결과 요약표 (통계량, p-value, 결론 — 엑셀에서 바로 열 수 있음) |
| `stats-basic_report.md` | 검정 결과를 쉬운 말로 해석한 한국어 보고서 |

**저장 경로 결정 우선순위:**
1. 사용자가 명시적으로 저장 위치를 지정한 경우 → 해당 경로 사용
2. 사용자가 폴더를 선택(마운트)한 경우 → 마운트된 폴더 안에 저장
3. 위 두 경우가 아니면 → `mnt/outputs/` 폴더에 저장

별도 PNG 파일은 생성하지 않습니다. 차트는 노트북 안에 포함됩니다.
stats-basic_result.csv는 `encoding='utf-8-sig'`로 저장해 엑셀에서도 한글이 깨지지 않게 합니다.

---

## 용어 쉬운 말 설명

- **p-value**: 이 결과가 우연히 나올 확률. p < 0.05면 "우연이 아닌 진짜 차이"로 판단
- **단일표본 t-검정**: 한 그룹의 평균이 특정 기준값(예: 전국 평균)과 다른지 검정
- **독립표본 t-검정**: 서로 다른 두 그룹의 평균을 비교하는 검정
- **ANOVA**: 세 그룹 이상을 한 번에 비교하는 검정 (t-검정의 확장)
- **사후검정(Tukey HSD)**: ANOVA에서 "어느 그룹 간 차이인지" 추가로 확인하는 검정
- **카이제곱**: 두 범주형 변수가 서로 관련 있는지 확인하는 검정
- **Pearson 상관계수**: 두 수치형 변수의 선형 관계 강도 (-1 ~ +1)
- **Spearman 상관계수**: 순위 기반 상관계수 (이상치나 비선형 관계에 강함)
- **단순 선형 회귀**: X 하나로 Y를 예측하는 수식. 상관이 "관련 있나?"라면 회귀는 "얼마나 영향을 주나?"
- **R²(결정계수)**: 회귀식이 데이터를 얼마나 잘 설명하는지 (0~1, 높을수록 좋음)
- **비모수 검정**: 정규분포를 가정하지 않는 검정 (표본이 적거나 분포가 치우친 경우 사용)
- **등분산**: 두 그룹의 분산이 비슷한 상태 (t-검정 시 확인 필요)
