---
name: ml-supervised
description: |
  정답 레이블이 있는 데이터로 예측 모델을 만드는 지도학습 스킬.
  표 형식 데이터(CSV·JSON·Parquet·Excel 등)를 받아
  Random Forest·Gradient Boosting·XGBoost·SVM·KNN·Decision Tree로 분류/회귀를 수행하고,
  교차검증·하이퍼파라미터 튜닝까지 포함합니다.
  실행 결과가 내장된 Jupyter Notebook(ml-supervised.ipynb),
  모델 성능 비교표(ml-supervised_result.csv),
  한국어 해석 보고서(ml-supervised_report.md)를 제공합니다.

  다음 상황에서 반드시 이 스킬을 사용하세요:
  - "구매 여부, 이탈 여부, 불량 여부를 예측하고 싶어" → 분류 모델
  - "매출, 가격, 수량 같은 숫자를 예측하고 싶어" → 회귀 모델
  - "어떤 변수가 결과에 가장 큰 영향을 미치는지 알고 싶어" → 변수 중요도
  - "여러 머신러닝 모델 중 가장 좋은 것을 찾아줘" → 모델 비교
  - "정답 레이블(Y 컬럼)이 있는 CSV로 예측 모델 만들고 싶어"
  - csv-ml-unsupervised로 군집 레이블을 만든 후 지도학습으로 이어갈 때
---

# 지도 머신러닝 스킬

정답 레이블(Y)이 있는 데이터로 예측 모델을 학습합니다. 출력물은 `ml-supervised.ipynb`(실행결과 내장) + `ml-supervised_result.csv`(모델 성능 비교) + `ml-supervised_report.md`(한국어 해석 보고서)입니다.

## Phase
Phase 4 — 분석 수행 (범용 도구 레이어)

## Input
- 이전 스킬: ml-unsupervised (또는 programmatic-eda / stats-advanced)
- 받는 파일: `ml-unsupervised_result.csv` 또는 이전 분석의 `*_result.csv`

## Output
- `ml-supervised.ipynb` — 지도학습 코드 (실행결과, 차트 내장)
- `ml-supervised_result.csv` — 모델별 성능 비교표
- `ml-supervised_report.md` — 최적 모델과 변수 중요도를 쉬운 말로 해석한 한국어 보고서

---

## Quick Start

지도학습의 최종 목표는 "좋은 모델"이 아니라 "실제로 사용할 수 있는 인사이트"입니다. 정확도 수치만 나열하는 대신, 어떤 변수가 왜 중요한지, 이 모델을 신뢰할 수 있는지, 실전에서 어떻게 활용할지를 함께 설명하세요.

---

## Context Requirements

1. **데이터**: 예측 대상(Y 컬럼)이 있는 표 형식 파일 (CSV·JSON·Parquet·Excel·TSV)
2. **타겟 변수**: 예측할 Y 컬럼명 및 타입 (범주형 → 분류, 연속형 → 회귀)
3. **입력 변수**: 예측에 사용할 X 컬럼 목록 (또는 전체 사용)
4. **이전 분석 결과** (선택): `ml-unsupervised_result.csv` 또는 `*_result.csv`

---

## Context Gathering

```
Y 컬럼(종속변수)이 범주형(예/아니오, A/B/C)?  → 분류(Classification)
Y 컬럼이 연속형 숫자(매출, 가격, 점수)?        → 회귀(Regression)
```

분석 시작 전 문제 유형과 사용할 모델을 한 줄로 사용자에게 알려주세요.
예: "구매여부(0/1) 예측이므로 분류 문제입니다. Random Forest, XGBoost, LightGBM을 비교합니다."

---

## 2단계 실행 구조

| 단계 | 설명 | 빈도 |
|------|------|------|
| **Stage 1** 대화형 설정 | Claude와 대화로 아래 Config Block 값을 결정 | 처음 1회 |
| **Stage 2** 노트북 실행 | Config Block만 수정 후 전체 셀 실행 | 매 실행 |

> 같은 형태의 데이터를 반복 분석할 때 (예: 주간 신규 데이터) **DATA_PATH 한 줄만 바꾸면** 나머지 설정이 그대로 유지됩니다.
> 스키마가 바뀌면 드리프트 탐지 셀이 경고를 출력합니다.

---

## Workflow

### 셀 1: Config Block

```python
# ╔══════════════════════════════════════════════════════════════╗
# ║        CONFIG BLOCK — 반복 실행 시 이 셀만 수정                  ║
# ║  처음 실행: Claude와 대화로 아래 값을 결정하세요                    ║
# ║  이후 실행: DATA_PATH만 바꾸고 나머지는 그대로 두세요                ║
# ╚══════════════════════════════════════════════════════════════╝

DATA_PATH    = "데이터_파일_경로.csv"  # ← 매 실행 시 이 줄만 변경

# 도메인 설정 (최초 1회 확정 후 고정)
TARGET_COL   = "target"   # 예측 대상 컬럼명
FEATURE_COLS = None        # None이면 타깃 제외 전체; 지정 예: ["age","revenue","is_active"]
TEST_SIZE    = 0.2         # 검증셋 비율
RANDOM_STATE = 42          # 재현성 시드
DOMAIN_NOTES = []          # 비즈니스 규칙 메모 (예: "age=0은 오류")

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
from sklearn.model_selection import train_test_split, cross_val_score, StratifiedKFold, KFold
from sklearn.preprocessing import StandardScaler, LabelEncoder
from sklearn.metrics import (
    classification_report, confusion_matrix, roc_auc_score, roc_curve,
    mean_squared_error, mean_absolute_error, r2_score
)
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
    """스키마·카테고리 변화를 탐지해 Config Block 재검토 여부를 알립니다."""
    current = {
        "columns":    list(df.columns),
        "dtypes":     {c: str(df[c].dtype) for c in df.columns},
        "categories": {
            c: sorted([str(v) for v in df[c].dropna().unique()])
            for c in df.select_dtypes(include=["object","category"]).columns
            if df[c].nunique() <= 30
        }
    }
    if not os.path.exists(baseline_path):
        with open(baseline_path, "w", encoding="utf-8") as f:
            json.dump(current, f, ensure_ascii=False, indent=2)
        print(f"✅ 기준 스키마 저장됨 (첫 실행) → {baseline_path}")
        return
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

# 데이터 로드
df = load_data(DATA_PATH)
print(f"데이터 크기: {df.shape[0]:,}행 × {df.shape[1]}열")
if DOMAIN_NOTES:
    print("📋 도메인 노트:")
    for note in DOMAIN_NOTES: print(f"   • {note}")

# 드리프트 탐지
check_schema_drift(df, "ml-supervised_baseline_schema.json")
df.head()

# 피처·타깃 설정 (Config Block 값 사용)
target_col   = TARGET_COL
feature_cols = FEATURE_COLS if FEATURE_COLS else [c for c in df.columns if c != target_col]

# 전처리
data = df[feature_cols + [target_col]].dropna()
X = pd.get_dummies(data[feature_cols])  # 범주형 자동 인코딩
y = data[target_col]

# 문제 유형 자동 판별
is_classification = (y.nunique() <= 20) or (y.dtype == object)
problem_type = "분류(Classification)" if is_classification else "회귀(Regression)"
print(f"\n문제 유형: {problem_type}")
print(f"Y 컬럼: {target_col}, 고유값 수: {y.nunique()}")
print(f"피처 수: {X.shape[1]}개")

# 분류면 레이블 인코딩
if is_classification and y.dtype == object:
    le = LabelEncoder()
    y = le.fit_transform(y)

# 학습/검증 분리
X_train, X_test, y_train, y_test = train_test_split(
    X, y, test_size=0.2, random_state=42,
    stratify=y if is_classification else None
)
scaler = StandardScaler()
X_train_s = scaler.fit_transform(X_train)
X_test_s  = scaler.transform(X_test)

print(f"학습셋: {X_train.shape[0]}행 | 검증셋: {X_test.shape[0]}행")

# 결과 누적용 리스트
results = []
```

---

### 모델 비교 (핵심)

### ① 여러 모델 한 번에 비교

```python
from sklearn.ensemble import RandomForestClassifier, GradientBoostingClassifier
from sklearn.ensemble import RandomForestRegressor, GradientBoostingRegressor
from sklearn.svm import SVC, SVR
from sklearn.neighbors import KNeighborsClassifier, KNeighborsRegressor
from sklearn.tree import DecisionTreeClassifier, DecisionTreeRegressor
from sklearn.linear_model import LogisticRegression, Ridge

if is_classification:
    models = {
        "Random Forest": RandomForestClassifier(n_estimators=100, random_state=42),
        "Gradient Boosting": GradientBoostingClassifier(n_estimators=100, random_state=42),
        "SVM": SVC(probability=True, random_state=42),
        "KNN": KNeighborsClassifier(n_neighbors=5),
        "Decision Tree": DecisionTreeClassifier(max_depth=5, random_state=42),
        "Logistic Regression": LogisticRegression(max_iter=1000, random_state=42),
    }
    cv = StratifiedKFold(n_splits=5, shuffle=True, random_state=42)
    scoring = 'roc_auc' if len(np.unique(y)) == 2 else 'accuracy'
else:
    models = {
        "Random Forest": RandomForestRegressor(n_estimators=100, random_state=42),
        "Gradient Boosting": GradientBoostingRegressor(n_estimators=100, random_state=42),
        "SVR": SVR(),
        "KNN": KNeighborsRegressor(n_neighbors=5),
        "Decision Tree": DecisionTreeRegressor(max_depth=5, random_state=42),
        "Ridge Regression": Ridge(),
    }
    cv = KFold(n_splits=5, shuffle=True, random_state=42)
    scoring = 'r2'

print(f"교차검증 지표: {scoring}\n")
model_scores = {}
for name, model in models.items():
    scores = cross_val_score(model, X_train_s, y_train, cv=cv, scoring=scoring)
    model_scores[name] = scores
    print(f"{name:25s}: {scores.mean():.4f} ± {scores.std():.4f}")
    results.append({
        "모델명": name,
        "CV평균점수": round(scores.mean(), 4),
        "CV표준편차": round(scores.std(), 4),
        "평가지표": scoring,
        "문제유형": problem_type
    })

# 시각화: 모델 성능 비교
fig, ax = plt.subplots(figsize=(10, 5))
names = list(model_scores.keys())
means = [model_scores[n].mean() for n in names]
stds  = [model_scores[n].std()  for n in names]
bars = ax.barh(names, means, xerr=stds, capsize=4)
ax.set_xlabel(f'{scoring} 점수')
ax.set_title('모델 성능 비교 (5-Fold 교차검증)')
ax.axvline(max(means), color='red', linestyle='--', alpha=0.5, label='최고 성능')
ax.legend()
plt.tight_layout()
plt.show()

best_model_name = max(model_scores, key=lambda n: model_scores[n].mean())
print(f"\n최고 성능 모델: {best_model_name} ({scoring}={model_scores[best_model_name].mean():.4f})")
```

---

### ② 최적 모델 상세 평가

```python
# 최고 성능 모델로 최종 학습
best_model = models[best_model_name]
best_model.fit(X_train_s, y_train)
y_pred = best_model.predict(X_test_s)

if is_classification:
    print(f"=== {best_model_name} 분류 성능 (검증셋) ===")
    print(classification_report(y_test, y_pred))

    # AUC (이진 분류만)
    if len(np.unique(y)) == 2 and hasattr(best_model, 'predict_proba'):
        y_prob = best_model.predict_proba(X_test_s)[:, 1]
        auc = roc_auc_score(y_test, y_prob)
        print(f"AUC-ROC: {auc:.4f}")

        fpr, tpr, _ = roc_curve(y_test, y_prob)
        fig, axes = plt.subplots(1, 2, figsize=(12, 5))
        axes[0].plot(fpr, tpr, label=f'AUC = {auc:.3f}')
        axes[0].plot([0,1],[0,1],'--', color='gray')
        axes[0].set_xlabel('위양성률 (FPR)')
        axes[0].set_ylabel('진양성률 (TPR)')
        axes[0].set_title('ROC 곡선')
        axes[0].legend()
        sns.heatmap(confusion_matrix(y_test, y_pred), annot=True, fmt='d',
                    cmap='Blues', ax=axes[1])
        axes[1].set_title('혼동 행렬')
        axes[1].set_xlabel('예측값')
        axes[1].set_ylabel('실제값')
        plt.tight_layout()
        plt.show()
        results.append({
            "모델명": f"{best_model_name} (최종)",
            "CV평균점수": round(auc, 4),
            "CV표준편차": "",
            "평가지표": "AUC-ROC (검증셋)",
            "문제유형": problem_type
        })
else:
    rmse = np.sqrt(mean_squared_error(y_test, y_pred))
    mae  = mean_absolute_error(y_test, y_pred)
    r2   = r2_score(y_test, y_pred)
    print(f"=== {best_model_name} 회귀 성능 (검증셋) ===")
    print(f"R²:   {r2:.4f} (전체 분산의 {r2*100:.1f}% 설명)")
    print(f"RMSE: {rmse:.4f}")
    print(f"MAE:  {mae:.4f}")

    fig, ax = plt.subplots(figsize=(7, 6))
    ax.scatter(y_test, y_pred, alpha=0.5)
    ax.plot([y_test.min(), y_test.max()], [y_test.min(), y_test.max()],
            'r--', label='완벽한 예측')
    ax.set_xlabel('실제값')
    ax.set_ylabel('예측값')
    ax.set_title(f'실제값 vs 예측값 (R²={r2:.3f})')
    ax.legend()
    plt.tight_layout()
    plt.show()
    results.append({
        "모델명": f"{best_model_name} (최종)",
        "CV평균점수": round(r2, 4),
        "CV표준편차": round(rmse, 4),
        "평가지표": "R² / RMSE (검증셋)",
        "문제유형": problem_type
    })
```

---

### ③ 변수 중요도

```python
# Feature Importance (트리 기반 모델)
if hasattr(best_model, 'feature_importances_'):
    importance_df = pd.DataFrame({
        '변수': X_train.columns,
        '중요도': best_model.feature_importances_
    }).sort_values('중요도', ascending=False)

    print(f"\n상위 10개 중요 변수:")
    print(importance_df.head(10).to_string(index=False))

    fig, ax = plt.subplots(figsize=(10, 6))
    top_n = min(15, len(importance_df))
    top_df = importance_df.head(top_n).sort_values('중요도')
    ax.barh(top_df['변수'], top_df['중요도'])
    ax.set_xlabel('변수 중요도')
    ax.set_title(f'변수 중요도 Top {top_n} ({best_model_name})')
    plt.tight_layout()
    plt.show()

    # 결과 저장 (상위 5개)
    for _, row in importance_df.head(5).iterrows():
        results.append({
            "모델명": f"{best_model_name} 변수중요도",
            "CV평균점수": round(row['중요도'], 4),
            "CV표준편차": "",
            "평가지표": f"변수: {row['변수']}",
            "문제유형": problem_type
        })
```

---

### ④ XGBoost / LightGBM (선택 — 고성능 앙상블)

언제: 기본 모델로 충분하지 않거나 성능을 최대화해야 할 때 추가

```python
try:
    import xgboost as xgb
    import lightgbm as lgb

    if is_classification:
        xgb_model = xgb.XGBClassifier(n_estimators=200, learning_rate=0.05,
                                        max_depth=6, random_state=42,
                                        eval_metric='logloss', verbosity=0)
        lgb_model = lgb.LGBMClassifier(n_estimators=200, learning_rate=0.05,
                                        random_state=42, verbose=-1)
    else:
        xgb_model = xgb.XGBRegressor(n_estimators=200, learning_rate=0.05,
                                       max_depth=6, random_state=42, verbosity=0)
        lgb_model = lgb.LGBMRegressor(n_estimators=200, learning_rate=0.05,
                                       random_state=42, verbose=-1)

    for name, model in [("XGBoost", xgb_model), ("LightGBM", lgb_model)]:
        scores = cross_val_score(model, X_train_s, y_train, cv=cv, scoring=scoring)
        print(f"{name:25s}: {scores.mean():.4f} ± {scores.std():.4f}")
        results.append({
            "모델명": name,
            "CV평균점수": round(scores.mean(), 4),
            "CV표준편차": round(scores.std(), 4),
            "평가지표": scoring,
            "문제유형": problem_type
        })
except ImportError:
    print("XGBoost/LightGBM 미설치. `pip install xgboost lightgbm`으로 설치 가능")
```

---

### 마지막 셀: ml-supervised_result.csv 저장

```python
results_df = pd.DataFrame(results)

col_order = ["모델명", "CV평균점수", "CV표준편차", "평가지표", "문제유형"]
results_df = results_df[[c for c in col_order if c in results_df.columns]]

output_path = "ml-supervised_result.csv"
results_df.to_csv(output_path, index=False, encoding='utf-8-sig')

print(f"✅ ml-supervised_result.csv 저장 완료: {len(results_df)}개 모델/지표")
print(results_df.to_string(index=False))
```

---

### 노트북 실행 (결과 내장)

```bash
pip install scikit-learn pandas numpy matplotlib seaborn xgboost lightgbm jupyter nbconvert --quiet
jupyter nbconvert --to notebook --execute \
  --ExecutePreprocessor.timeout=300 \
  --output ml-supervised.ipynb \
  ml-supervised.ipynb
```

---

---

## Context Validation

분석 시작 전 아래 항목을 확인하세요:
- [ ] 분석 파일 경로 및 형식 확인 (CSV·JSON·Parquet·Excel·TSV)
- [ ] Y 컬럼(타겟)이 명확하게 지정되었는가
- [ ] 문제 유형이 확인되었는가 (분류 vs 회귀)
- [ ] 결측치가 처리되었는가 (또는 처리 예정)
- [ ] 분류 모델 시 클래스 불균형이 없는가 (불균형 시 class_weight 설정 필요)

---

## Output Template


```markdown
# 지도 머신러닝 분석 보고서

> **파일**: {파일명} | **분석일**: {날짜} | **문제유형**: {분류/회귀} | **최적모델**: {모델명}

## 1. 분석 목적
(무엇을 예측하려 했는지, 왜 이 Y 컬럼을 선택했는지)

## 2. 모델 성능 요약
| 모델 | CV 점수 | 검증셋 점수 |
|------|---------|------------|
| ... | ... | ... |

## 3. 최적 모델 해석
(왜 이 모델이 가장 좋은 성능을 냈는지)

## 4. 핵심 변수 (중요도 상위 5개)
(어떤 변수가 예측에 가장 큰 영향을 미치는지, 비즈니스 의미는 무엇인지)

## 5. 예측 성능의 한계
(어떤 상황에서 틀리는지, 과적합 가능성, 데이터 편향 등)

## 6. 실전 활용 방안
(이 모델로 무엇을 할 수 있는지 구체적 제안)
```

---

### 최종 출력물

| 파일 | 내용 |
|------|------|
| `ml-supervised.ipynb` | 지도학습 코드 + 실행결과(차트, 성능 비교) 내장 |
| `ml-supervised_result.csv` | 모델별 성능 비교표 (엑셀에서 바로 열 수 있음) |
| `ml-supervised_report.md` | 최적 모델과 핵심 변수를 쉬운 말로 해석한 한국어 보고서 |

**저장 경로 결정 우선순위:**
1. 사용자가 명시적으로 저장 위치를 지정한 경우 → 해당 경로 사용
2. 사용자가 폴더를 선택(마운트)한 경우 → 마운트된 폴더 안에 저장
3. 위 두 경우가 아니면 → `mnt/outputs/` 폴더에 저장

별도 PNG 파일은 생성하지 않습니다. 차트는 노트북 안에 포함됩니다.
