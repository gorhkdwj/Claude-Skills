---
name: feature-engineering
description: |
  ML 성능 향상을 위한 파생 변수 생성·변환·선택 스킬.
  data-preprocessing 이후, ml-supervised/ml-unsupervised 이전 단계로 사용합니다.
  통계적 패턴으로 피처 후보를 제안하고, 사용자가 도메인 지식으로 의미를 검증합니다.

  다음 상황에서 반드시 이 스킬을 사용하세요:
  - "ML 모델 성능을 높이고 싶어"
  - "파생 변수를 어떻게 만들어야 할지 모르겠어"
  - "날짜 컬럼에서 요일, 월, 계절 같은 정보를 뽑고 싶어"
  - "두 컬럼을 조합해서 새 변수를 만들고 싶어"
  - "불필요한 변수를 제거하고 중요한 것만 남기고 싶어" (피처 선택)
  - "컬럼이 너무 많아서 차원을 줄이고 싶어" (PCA, 상관관계 기반 제거)
---

# 피처 엔지니어링 스킬

ML 모델 입력에 최적화된 피처(변수) 집합을 만듭니다.
출력물은 `feature-engineering.ipynb`(실행결과 내장) + `feature-engineering_result.csv`(피처 완성 데이터) + `feature-engineering_report.md`(생성/선택 내역 및 근거 보고서)입니다.

## Phase
Phase 3.7 — 피처 엔지니어링 (data-preprocessing 이후, ml-supervised / ml-unsupervised 이전)

## Input
- 이전 스킬: data-preprocessing
- 받는 파일: `data-preprocessing_result.csv` (전처리 완료 데이터)
- 선택: `context_packet.json` (analysis-path-guide / context-packager 생성)

## Output
- `feature-engineering.ipynb` — 피처 엔지니어링 전 과정 코드 (실행결과 내장)
- `feature-engineering_result.csv` — 피처 엔지니어링 완료 데이터셋
- `feature-engineering_report.md` — 생성 피처 목록, 선택 근거, 중요도 순위
- `feature-engineering_baseline_schema.json` — 드리프트 탐지 기준 스키마 (자동 생성)

---

## 빠른 시작

피처 엔지니어링은 **"데이터에서 숨겨진 패턴을 꺼내는 작업"**입니다.
통계가 패턴을 찾고, 사용자(도메인 전문가)가 의미를 부여합니다.
AI가 모든 수치형 조합과 날짜 파생 피처를 자동 제안하지만,
**"이 피처가 실제로 비즈니스 의미가 있는가?"는 사용자만 판단할 수 있습니다.**

---

## 2단계 실행 구조

| 단계 | 설명 | 빈도 |
|------|------|------|
| **Stage 1** 대화형 설정 | Claude와 대화로 아래 Config Block 값을 결정 | 처음 1회 |
| **Stage 2** 노트북 실행 | Config Block만 수정 후 전체 셀 실행 | 매 실행 |

> 같은 형태의 데이터를 반복 분석할 때 **DATA_PATH 한 줄만 바꾸면** 나머지 설정이 그대로 유지됩니다.
> 스키마가 바뀌면 드리프트 탐지 셀이 경고를 출력합니다.

> ⚠️ **feature-engineering 주의**: `BINNING_COLS`와 `MANUAL_INTERACTIONS`는 비즈니스 도메인 지식이 필요합니다.
> 분석 목적이 바뀌면 DATA_PATH뿐 아니라 이 두 값도 재검토하세요.

---

## Stage 1 — 대화형 설정 가이드

노트북 생성 전 Claude와 아래 순서로 설정값을 확정합니다.

### context_packet.json 자동 확인

`context_packet.json`이 있으면 TARGET_COL과 분석 목적을 자동으로 읽어옵니다.
없으면 아래 질문으로 직접 확인합니다.

### 확인 질문 순서

**질문 1 — 타깃 컬럼:**
"예측하거나 분석하려는 결과 컬럼이 무엇인가요?
예: 'is_churn'(이탈 여부), 'sales_amount'(매출액), 없음(비지도 학습)"

**질문 2 — 분석 목적:**
"다음 중 어떤 분석인가요?
① 분류 (예/아니오, A/B/C 같은 범주 예측)
② 회귀 (숫자 예측)
③ 군집화 (그룹 나누기, 타깃 없음)"

**질문 3 — 구간화 후보 (BINNING_COLS):**
진단 코드를 실행한 뒤 아래 결과를 바탕으로 제안합니다:
```python
# 구간화 후보 자동 탐지 (값 범위 넓은 수치형 컬럼)
for col in df.select_dtypes(include='number').columns:
    if col == TARGET_COL: continue
    vrange = df[col].max() - df[col].min()
    if vrange > 10 and df[col].nunique() > 10:
        print(f"  후보: '{col}' | 범위 {df[col].min():.1f}~{df[col].max():.1f} | 유니크 {df[col].nunique()}개")
```
"위 컬럼 중 구간으로 나누는 게 의미 있는 것이 있나요?
예: 'age' → [0,18,35,60,100] / 'income' → 5 (등간격 5구간)
없으면 빈 딕셔너리({})로 두세요."

**질문 4 — 상호작용 피처 (MANUAL_INTERACTIONS):**
진단 코드를 실행한 뒤 상관관계 기반으로 제안합니다:
```python
# 타깃과 상관이 높은 컬럼 Top 6 표시
if TARGET_COL:
    corrs = df.select_dtypes(include='number').corr()[TARGET_COL].abs().drop(TARGET_COL, errors='ignore')
    print(f"타깃과 상관 높은 컬럼 Top 6: {corrs.nlargest(6).index.tolist()}")
```
"이 중 두 컬럼의 조합(곱)이 비즈니스적으로 의미 있는 쌍이 있나요?
예: ('recency', 'frequency'), ('age', 'income')
없으면 빈 리스트([])로 두세요."

---

## Workflow

### 셀 1: Config Block

```python
# ╔══════════════════════════════════════════════════════════════╗
# ║        CONFIG BLOCK — 반복 실행 시 이 셀만 수정                  ║
# ║  처음 실행: Claude와 대화로 아래 값을 결정하세요 (Stage 1)          ║
# ║  이후 실행: DATA_PATH만 바꾸고 나머지는 그대로 두세요                ║
# ║  ⚠️  분석 목적이 바뀌면 BINNING_COLS·MANUAL_INTERACTIONS 재검토  ║
# ╚══════════════════════════════════════════════════════════════╝

DATA_PATH = "data-preprocessing_result.csv"  # ← 매 실행 시 이 줄만 변경

# 도메인 설정 (최초 1회 확정 후 고정)
TARGET_COL       = None    # 예: 'is_churn', 'sales_amount', None(비지도)
ANALYSIS_PURPOSE = "분류"   # "분류" / "회귀" / "군집화"

# 구간화 설정 — int: 등간격 n구간 / list: 직접 경계값 지정
BINNING_COLS = {}
# 예: {'age': [0, 18, 35, 60, 100], 'income': 5}

# 상호작용 피처 — 비즈니스 의미가 있는 컬럼 쌍
MANUAL_INTERACTIONS = []
# 예: [('recency', 'frequency'), ('age', 'income')]

DOMAIN_NOTES = []  # 비즈니스 규칙 메모

# ════════════════════════════════════════════════════════════════
```

---

### 셀 2: 라이브러리 로드 + context_packet 연동 + 데이터 로드 + 드리프트 탐지

```python
import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
import matplotlib
import seaborn as sns
from scipy import stats
import json, os, warnings
warnings.filterwarnings('ignore')
matplotlib.rcParams['font.family'] = 'DejaVu Sans'
matplotlib.rcParams['axes.unicode_minus'] = False
%matplotlib inline

# ── context_packet.json 연동 ──────────────────────────────────
def load_config_from_packet(packet_path="context_packet.json"):
    """context_packet.json에서 TARGET_COL·분석목적을 읽어 Config Block 초기값을 보완합니다."""
    if not os.path.exists(packet_path):
        return {}
    with open(packet_path, "r", encoding="utf-8") as f:
        packet = json.load(f)
    loaded = {}
    if packet.get("target_col") and TARGET_COL is None:
        loaded["target_col"] = packet["target_col"]
        print(f"📦 context_packet → TARGET_COL='{packet['target_col']}' 자동 로드")
    if packet.get("analysis_purpose"):
        loaded["analysis_purpose"] = packet["analysis_purpose"]
        print(f"📦 context_packet → 분석목적='{packet['analysis_purpose']}' 확인")
    return loaded

packet_config = load_config_from_packet()
_target = packet_config.get("target_col", TARGET_COL)

# ── 데이터 로드 ───────────────────────────────────────────────
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

# ── 드리프트 탐지 ─────────────────────────────────────────────
def check_schema_drift(df, baseline_path):
    """컬럼 구조·타입·카테고리·날짜 컬럼 변화를 탐지합니다.

    날짜 컬럼이 추가/삭제되면 생성 피처 목록이 크게 달라지므로
    별도 경고 조건으로 처리합니다.
    """
    date_cols = []
    for col in df.columns:
        if df[col].dtype == 'object':
            try:
                pd.to_datetime(df[col].dropna().iloc[:10])
                date_cols.append(col)
            except Exception:
                pass
        elif any(kw in col.lower() for kw in ['date', 'time', '_dt', '_at']):
            date_cols.append(col)

    current = {
        "columns":    list(df.columns),
        "dtypes":     {c: str(df[c].dtype) for c in df.columns},
        "date_cols":  date_cols,
        "categories": {
            c: sorted([str(v) for v in df[c].dropna().unique()])
            for c in df.select_dtypes(include=["object", "category"]).columns
            if df[c].nunique() <= 30
        }
    }

    if not os.path.exists(baseline_path):
        with open(baseline_path, "w", encoding="utf-8") as f:
            json.dump(current, f, ensure_ascii=False, indent=2)
        print(f"✅ 기준 스키마 저장됨 (첫 실행) → {baseline_path}")
        if date_cols:
            print(f"   탐지된 날짜 컬럼: {date_cols}")
        return date_cols

    with open(baseline_path, "r", encoding="utf-8") as f:
        baseline = json.load(f)

    drifts = []
    new_cols     = set(current["columns"]) - set(baseline["columns"])
    removed_cols = set(baseline["columns"]) - set(current["columns"])
    type_changes = {
        c: (baseline["dtypes"].get(c), current["dtypes"][c])
        for c in current["columns"]
        if c in baseline["dtypes"] and baseline["dtypes"][c] != current["dtypes"][c]
    }

    # 날짜 컬럼 변화 감지 (feature-engineering 전용)
    prev_dates = set(baseline.get("date_cols", []))
    curr_dates = set(current["date_cols"])
    if curr_dates - prev_dates:
        drifts.append(
            f"⚠️  [날짜 컬럼 추가] {curr_dates - prev_dates} "
            f"— 날짜 파생 피처가 새로 생성됩니다. BINNING_COLS·MANUAL_INTERACTIONS 재검토 권장"
        )
    if prev_dates - curr_dates:
        drifts.append(
            f"⚠️  [날짜 컬럼 삭제] {prev_dates - curr_dates} "
            f"— 관련 파생 피처가 생성되지 않습니다."
        )

    for col in current["categories"]:
        if col in baseline.get("categories", {}):
            added   = set(current["categories"][col]) - set(baseline["categories"][col])
            removed = set(baseline["categories"][col]) - set(current["categories"][col])
            if added:   drifts.append(f"'{col}' 신규 카테고리: {added}")
            if removed: drifts.append(f"'{col}' 삭제된 카테고리: {removed}")

    if new_cols:
        drifts.append(f"신규 컬럼: {new_cols} — BINNING_COLS·MANUAL_INTERACTIONS 재검토 권장")
    if removed_cols:
        drifts.append(f"삭제된 컬럼: {removed_cols}")
    if type_changes:
        drifts.append(f"타입 변경: {type_changes}")

    if drifts:
        print("⚠️  스키마 드리프트 감지! Config Block 설정을 재검토하세요:")
        for d in drifts:
            print(f"   • {d}")
    else:
        print("✅ 스키마 변화 없음 — Config Block 설정 그대로 사용 가능")

    return current["date_cols"]

# ── 실행 ─────────────────────────────────────────────────────
df = load_data(DATA_PATH)
print(f"데이터 크기: {df.shape[0]:,}행 × {df.shape[1]}열")

if DOMAIN_NOTES:
    print("📋 도메인 노트:")
    for note in DOMAIN_NOTES:
        print(f"   • {note}")

detected_date_cols = check_schema_drift(df, "feature-engineering_baseline_schema.json")

TARGET_COL_FINAL = _target
df_feat = df.copy()

print(f"\n분석 목적: {ANALYSIS_PURPOSE}")
print(f"타깃 컬럼: {TARGET_COL_FINAL if TARGET_COL_FINAL else '없음 (비지도 학습)'}")
print(f"탐지된 날짜 컬럼: {detected_date_cols if detected_date_cols else '없음'}")
df.head()
```

---

### 셀 3: 피처 현황 파악

```python
print("=== 피처 현황 ===")
print(f"전체 컬럼 수: {df.shape[1]}")
print(f"\n컬럼 타입 현황:")
print(df.dtypes.value_counts())
print(f"\n컬럼 목록:")
for col in df.columns:
    sample = df[col].dropna().iloc[0] if len(df[col].dropna()) > 0 else 'N/A'
    print(f"  {col}: {df[col].dtype} | 유니크: {df[col].nunique()} | 예시: {sample}")
```

---

### 셀 4: 날짜/시간 피처 추출

```python
date_features_created = []

for col in detected_date_cols:
    try:
        dt = pd.to_datetime(df_feat[col])
        df_feat[f'{col}_year']       = dt.dt.year
        df_feat[f'{col}_month']      = dt.dt.month
        df_feat[f'{col}_day']        = dt.dt.day
        df_feat[f'{col}_weekday']    = dt.dt.weekday
        df_feat[f'{col}_quarter']    = dt.dt.quarter
        df_feat[f'{col}_is_weekend'] = (dt.dt.weekday >= 5).astype(int)
        df_feat[f'{col}_days_ago']   = (dt.max() - dt).dt.days
        if dt.dt.hour.nunique() > 1:
            df_feat[f'{col}_hour']             = dt.dt.hour
            df_feat[f'{col}_is_business_hour'] = (
                (dt.dt.hour >= 9) & (dt.dt.hour < 18)
            ).astype(int)
        new_cols = [c for c in df_feat.columns if c.startswith(f'{col}_')]
        date_features_created.extend(new_cols)
        print(f"  '{col}' → {len(new_cols)}개 피처 생성: {new_cols}")
    except Exception as e:
        print(f"  '{col}' 날짜 처리 실패: {e}")

if not detected_date_cols:
    print("탐지된 날짜 컬럼 없음 — 날짜 파생 피처 생략")
```

---

### 셀 5: 수치형 파생 피처 생성

```python
numeric_cols = [
    col for col in df.columns
    if df[col].dtype in ['int64', 'float64']
    and col != TARGET_COL_FINAL
    and col not in detected_date_cols
]

derived_features = []

# 5-1. 비율 피처
ratio_candidates = []
for i, col1 in enumerate(numeric_cols):
    for col2 in numeric_cols[i+1:]:
        if (df[col2] == 0).mean() > 0.1:
            continue
        ratio_name = f'{col1}_per_{col2}'
        df_feat[ratio_name] = df[col1] / (df[col2] + 1e-8)
        if TARGET_COL_FINAL and TARGET_COL_FINAL in df.columns:
            corr = abs(df_feat[ratio_name].corr(df[TARGET_COL_FINAL]))
            if corr > 0.05:
                ratio_candidates.append({'feature': ratio_name, 'corr_with_target': round(corr, 4)})
                derived_features.append(ratio_name)
            else:
                df_feat.drop(columns=[ratio_name], inplace=True)
        else:
            derived_features.append(ratio_name)

if ratio_candidates:
    print("비율 피처 (타깃 상관 > 0.05):")
    for r in sorted(ratio_candidates, key=lambda x: -x['corr_with_target'])[:10]:
        print(f"  {r['feature']}: corr={r['corr_with_target']}")

# 5-2. 로그 변환
log_features = []
for col in numeric_cols:
    skewness = df[col].skew()
    if skewness > 1 and df[col].min() >= 0:
        df_feat[f'{col}_log'] = np.log1p(df[col])
        log_features.append(f'{col}_log')
        derived_features.append(f'{col}_log')
if log_features:
    print(f"\n로그 변환 피처 ({len(log_features)}개): {log_features}")

# 5-3. 구간화 (Config Block의 BINNING_COLS 사용)
for col, bins in BINNING_COLS.items():
    if col in df_feat.columns:
        df_feat[f'{col}_bin'] = pd.cut(df_feat[col], bins=bins, labels=False)
        derived_features.append(f'{col}_bin')
        print(f"구간화: '{col}' → '{col}_bin' ({bins})")
    else:
        print(f"⚠️  BINNING_COLS: '{col}' 컬럼을 찾을 수 없습니다. Config Block을 확인하세요.")

print(f"\n파생 피처 소계: {len(derived_features)}개")
```

---

### 셀 6: 상호작용 피처 (Config Block의 MANUAL_INTERACTIONS 사용)

```python
interaction_features = []

# 6-1. 사용자 지정 상호작용
for col1, col2 in MANUAL_INTERACTIONS:
    if col1 in df_feat.columns and col2 in df_feat.columns:
        feat_name = f'{col1}_x_{col2}'
        df_feat[feat_name] = df_feat[col1] * df_feat[col2]
        interaction_features.append(feat_name)
        print(f"  {col1} × {col2} → '{feat_name}'")
    else:
        missing = [c for c in [col1, col2] if c not in df_feat.columns]
        print(f"⚠️  MANUAL_INTERACTIONS: {missing} 컬럼을 찾을 수 없습니다. Config Block을 확인하세요.")

# 6-2. 자동 상호작용 탐색 (타깃이 있고 컬럼 수 ≤ 20인 경우)
if TARGET_COL_FINAL and len(numeric_cols) <= 20:
    auto_interactions = []
    for i, col1 in enumerate(numeric_cols[:10]):
        for col2 in numeric_cols[i+1:11]:
            feat_name = f'{col1}_x_{col2}'
            if feat_name in df_feat.columns:
                continue  # MANUAL_INTERACTIONS 중복 방지
            temp = df_feat[col1] * df_feat[col2]
            corr = abs(temp.corr(df[TARGET_COL_FINAL]))
            base = max(
                abs(df[col1].corr(df[TARGET_COL_FINAL])),
                abs(df[col2].corr(df[TARGET_COL_FINAL]))
            )
            if corr > base * 1.1:
                df_feat[feat_name] = temp
                interaction_features.append(feat_name)
                auto_interactions.append({'feature': feat_name, 'corr': round(corr, 4)})
    if auto_interactions:
        print(f"\n자동 탐지 상호작용 피처 (단독 대비 +10% 이상):")
        for f in sorted(auto_interactions, key=lambda x: -x['corr'])[:10]:
            print(f"  {f['feature']}: corr={f['corr']}")

print(f"\n상호작용 피처 총 {len(interaction_features)}개 생성")
if not MANUAL_INTERACTIONS:
    print("💡 도메인 지식이 있다면 MANUAL_INTERACTIONS에 컬럼 쌍을 추가해 더 의미 있는 피처를 만들 수 있습니다.")
```

---

### 셀 7: 피처 선택

```python
from sklearn.ensemble import RandomForestClassifier, RandomForestRegressor
from sklearn.feature_selection import VarianceThreshold

feature_selection_log = []

# 7-1. 분산=0 컬럼 제거
num_df = df_feat.select_dtypes(include='number')
selector = VarianceThreshold(threshold=0.0)
selector.fit(num_df)
zero_var_cols = [col for col, ok in zip(num_df.columns, selector.get_support()) if not ok]
if zero_var_cols:
    df_feat.drop(columns=zero_var_cols, inplace=True)
    feature_selection_log.append(f"분산=0 컬럼 제거: {zero_var_cols}")

# 7-2. 높은 상관관계 컬럼 제거
numeric_feat_cols = df_feat.select_dtypes(include='number').columns.tolist()
if TARGET_COL_FINAL and TARGET_COL_FINAL in numeric_feat_cols:
    numeric_feat_cols.remove(TARGET_COL_FINAL)

corr_matrix = df_feat[numeric_feat_cols].corr().abs()
upper = corr_matrix.where(np.triu(np.ones(corr_matrix.shape), k=1).astype(bool))
high_corr_cols = [col for col in upper.columns if any(upper[col] > 0.95)]
if high_corr_cols:
    df_feat.drop(columns=high_corr_cols, inplace=True)
    feature_selection_log.append(f"높은 상관관계(>0.95) 컬럼 제거: {high_corr_cols}")

# 7-3. 랜덤 포레스트 피처 중요도 (타깃이 있는 경우)
if TARGET_COL_FINAL and TARGET_COL_FINAL in df_feat.columns:
    X = df_feat.drop(columns=[TARGET_COL_FINAL]).select_dtypes(include='number')
    y = df_feat[TARGET_COL_FINAL]
    is_clf = (ANALYSIS_PURPOSE == "분류") or (y.nunique() <= 20 and y.dtype in ['int64', 'object'])

    rf = (RandomForestClassifier(n_estimators=100, random_state=42, n_jobs=-1)
          if is_clf else
          RandomForestRegressor(n_estimators=100, random_state=42, n_jobs=-1))
    rf.fit(X, y)

    importance_df = pd.DataFrame({
        'feature': X.columns,
        'importance': rf.feature_importances_
    }).sort_values('importance', ascending=False)

    print("=== 랜덤 포레스트 피처 중요도 Top 20 ===")
    print(importance_df.head(20).to_string(index=False))

    fig, ax = plt.subplots(figsize=(10, 8))
    top_df = importance_df.head(min(20, len(importance_df))).sort_values('importance')
    ax.barh(top_df['feature'], top_df['importance'])
    ax.set_title(f'피처 중요도 Top {len(top_df)}')
    plt.tight_layout()
    plt.show()

    cumsum = importance_df['importance'].cumsum()
    n_keep = (cumsum <= 0.99).sum() + 1
    keep_features = importance_df.head(n_keep)['feature'].tolist()
    removed_low = [f for f in X.columns if f not in keep_features]
    if removed_low:
        feature_selection_log.append(f"낮은 중요도 피처 제거 (누적 99% 기준): {len(removed_low)}개")

print("\n=== 피처 선택 결과 ===")
for log in feature_selection_log:
    print(f"  • {log}")
final_count = df_feat.shape[1] - (1 if TARGET_COL_FINAL in df_feat.columns else 0)
print(f"\n최종 피처 수: {df.shape[1]} → {final_count} (+{final_count - df.shape[1]})")
```

---

### 셀 8: 최종 저장

```python
output_path = "feature-engineering_result.csv"
df_feat.to_csv(output_path, index=False, encoding='utf-8-sig')

all_derived = date_features_created + derived_features + interaction_features
print(f"✅ 피처 엔지니어링 완료: {output_path}")
print(f"   원본 피처: {df.shape[1]}개 → 최종: {df_feat.shape[1]}개 (+{df_feat.shape[1] - df.shape[1]})")
print(f"\n생성된 파생 피처 (최대 20개 표시):")
for feat in all_derived[:20]:
    print(f"  • {feat}")
if len(all_derived) > 20:
    print(f"  ... 외 {len(all_derived) - 20}개")
```

---

### 노트북 실행 (결과 내장)

```bash
pip install scikit-learn pandas numpy matplotlib seaborn scipy jupyter nbconvert --quiet
jupyter nbconvert --to notebook --execute \
  --ExecutePreprocessor.timeout=300 \
  --output feature-engineering.ipynb \
  feature-engineering.ipynb
```

---

## 컨텍스트 검증

- [ ] 날짜 피처가 비즈니스적으로 의미 있는가? (요일이 실제로 중요한 패턴인지)
- [ ] 비율 피처의 분모가 0이 되는 경우를 적절히 처리했는가?
- [ ] MANUAL_INTERACTIONS가 도메인 논리에 맞는가?
- [ ] 로그 변환 컬럼의 왜도가 개선되었는가?
- [ ] 피처 선택 후 중요한 변수가 제거되지 않았는가?
- [ ] 타깃 컬럼이 피처로 잘못 포함되지 않았는가? (데이터 누수)
- [ ] 테스트 데이터에도 동일한 변환을 적용할 수 있는가?
- [ ] 드리프트 탐지 경고가 있다면 BINNING_COLS·MANUAL_INTERACTIONS를 재검토했는가?

---

## 출력 템플릿

### `feature-engineering_report.md` 구조

```markdown
# 피처 엔지니어링 보고서

## 처리 개요
- 입력 피처: {n}개 / 출력 피처: {n}개 (생성 +{n}, 제거 -{n})
- 분석 목적: {분류/회귀/군집화} | 타깃 컬럼: {col}

## 생성된 피처
### 날짜/시간 파생 피처
| 원본 컬럼 | 생성 피처 | 설명 |

### 수치형 파생 피처
| 피처명 | 생성 방법 | 타깃 상관관계 |

### 상호작용 피처
| 피처명 | 조합 | 근거 |

## 제거된 피처
| 피처명 | 제거 이유 |

## 피처 중요도 순위 (Top 20)
(랜덤 포레스트 기반)

## 사용자 도메인 검증 결과
(AI 제안 중 수정/제거된 항목)

## 다음 단계
- 권장: ml-supervised 또는 ml-unsupervised 진행
```

---

### 최종 출력물

| 파일 | 내용 |
|------|------|
| `feature-engineering.ipynb` | 피처 엔지니어링 전 과정 코드 + 실행결과 내장 |
| `feature-engineering_result.csv` | 피처 엔지니어링 완료 데이터셋 |
| `feature-engineering_report.md` | 생성·선택 내역, 중요도 순위 한국어 보고서 |
| `feature-engineering_baseline_schema.json` | 드리프트 탐지 기준 스키마 (자동 생성) |

**저장 경로 결정 우선순위:**
1. 사용자가 명시적으로 저장 위치를 지정한 경우 → 해당 경로 사용
2. 사용자가 폴더를 선택(마운트)한 경우 → 마운트된 폴더 안에 저장
3. 위 두 경우가 아니면 → `mnt/outputs/` 폴더에 저장

별도 PNG 파일은 생성하지 않습니다. 차트는 노트북 안에 포함됩니다.
