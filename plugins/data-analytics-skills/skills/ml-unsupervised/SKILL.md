---
name: ml-unsupervised
description: |
  레이블(정답)이 없는 데이터에서 숨겨진 패턴·그룹·이상값을 발견하는 비지도학습 스킬.
  표 형식 데이터(CSV·JSON·Parquet·Excel 등)를 받아
  K-Means·DBSCAN·계층적 군집화, PCA·t-SNE 차원 축소, Isolation Forest 이상탐지를 수행하며,
  실행 결과가 내장된 Jupyter Notebook(ml-unsupervised.ipynb),
  군집/이상탐지 결과 테이블(ml-unsupervised_result.csv),
  한국어 해석 보고서(ml-unsupervised_report.md)를 제공합니다.

  다음 상황에서 반드시 이 스킬을 사용하세요:
  - "고객을 비슷한 유형끼리 묶어줘", "세그먼트 나눠줘" → K-Means / DBSCAN
  - "어떤 그룹이 있는지 모르겠어, 데이터가 스스로 말하게 해줘" → 군집분석
  - "변수가 너무 많아서 줄이고 싶어", "2D로 시각화해줘" → PCA / t-SNE
  - "이상한 데이터 포인트를 찾아줘", "비정상 거래 탐지해줘" → Isolation Forest
  - "지도학습 전에 데이터 구조를 먼저 파악하고 싶어"
  - 정답 레이블이 없는 CSV로 패턴 탐색을 시작할 때
---

# 비지도 머신러닝 스킬

정답 레이블 없이 데이터 자체의 구조를 탐색합니다. 출력물은 `ml-unsupervised.ipynb`(실행결과 내장) + `ml-unsupervised_result.csv`(군집·이상탐지 결과) + `ml-unsupervised_report.md`(한국어 해석 보고서)입니다.

## Phase
Phase 4 — 분석 수행 (범용 도구 레이어)

## Input
- 이전 스킬: programmatic-eda (또는 data-quality-audit)
- 받는 파일: `programmatic-eda_result.csv` 또는 이전 분석의 `*_result.csv`

## Output
- `ml-unsupervised.ipynb` — 비지도학습 코드 (실행결과, 차트 내장)
- `ml-unsupervised_result.csv` — 군집 레이블·이상탐지 결과 테이블
- `ml-unsupervised_report.md` — 발견된 패턴을 쉬운 말로 해석한 한국어 보고서

---

## Quick Start

비지도학습은 "정답이 없기 때문에" 결과 해석이 특히 중요합니다. 군집 수, 하이퍼파라미터 선택 이유, 차원 축소 해석 방식을 사용자가 이해할 수 있도록 설명하세요. 알고리즘을 실행하는 것보다 "왜 이 군집이 의미 있는가"를 전달하는 것이 목표입니다.

---

## Context Requirements

1. **데이터**: 레이블(정답 컬럼) 없는 표 형식 파일 (CSV·JSON·Parquet·Excel·TSV)
2. **분석 목적**: 군집화 / 차원 축소 / 이상탐지 중 해당 항목
3. **이전 EDA 결과** (선택): `eda_result.csv` 또는 `*_result.csv`
4. **수치형 컬럼**: 군집화·PCA 등에 사용할 수치형 변수 목록

---

## Context Gathering

Read 툴로 이전 결과물을 확인한 후, 아래 판단 기준으로 사용할 알고리즘을 선택하세요.

**알고리즘 선택 판단 기준:**
- 군집 수를 대략 알고 있음 → K-Means
- 군집 수 모름, 밀도 기반 군집, 노이즈 포함 → DBSCAN
- 군집 간 계층 구조가 궁금함 → 계층적 군집화
- 변수가 5개 이상이거나 시각화가 필요함 → PCA / t-SNE 먼저
- 이상값·사기 탐지가 목적 → Isolation Forest

분석 시작 전 선택한 알고리즘과 이유를 한 줄로 사용자에게 알려주세요.
예: "고객 세그먼트 목적이므로 K-Means(k=3~5 탐색)와 PCA 시각화를 진행합니다."

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
FEATURE_COLS = None   # None이면 수치형 전체; 지정 예: ["age","revenue","visits"]
N_CLUSTERS   = None   # None이면 자동 탐색 (Elbow Method); 확정 후 숫자 지정 (예: 4)
RANDOM_STATE = 42
DOMAIN_NOTES = []     # 비즈니스 규칙 메모

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
from sklearn.preprocessing import StandardScaler
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
check_schema_drift(df, "ml-unsupervised_baseline_schema.json")
df.head()

# 수치형 컬럼 자동 선택 (ML에 사용할 피처)
num_cols = df.select_dtypes(include=[np.number]).columns.tolist()
print(f"수치형 컬럼 {len(num_cols)}개: {num_cols}")

# 결측치 제거 + 정규화
X_raw = df[num_cols].dropna()
scaler = StandardScaler()
X = scaler.fit_transform(X_raw)
print(f"분석 대상: {X.shape[0]}행 × {X.shape[1]}열 (정규화 완료)")

# 결과 누적용 리스트
results = []
```

---

### 분석별 코드 패턴

### ① K-Means 군집화

언제: "고객 유형을 몇 가지로 나눠줘", 군집 수를 탐색할 때

```python
from sklearn.cluster import KMeans
from sklearn.metrics import silhouette_score

# 최적 k 탐색 (Elbow + Silhouette)
k_range = range(2, 9)
inertias, silhouettes = [], []
for k in k_range:
    km = KMeans(n_clusters=k, random_state=42, n_init=10)
    labels = km.fit_predict(X)
    inertias.append(km.inertia_)
    silhouettes.append(silhouette_score(X, labels))

fig, axes = plt.subplots(1, 2, figsize=(12, 4))
axes[0].plot(list(k_range), inertias, 'bo-')
axes[0].set_xlabel('군집 수 (k)')
axes[0].set_ylabel('Inertia (낮을수록 좋음)')
axes[0].set_title('Elbow 방법')
axes[1].plot(list(k_range), silhouettes, 'rs-')
axes[1].set_xlabel('군집 수 (k)')
axes[1].set_ylabel('Silhouette Score (높을수록 좋음)')
axes[1].set_title('Silhouette 분석')
plt.tight_layout()
plt.show()

best_k = list(k_range)[silhouettes.index(max(silhouettes))]
print(f"권장 군집 수: k={best_k} (Silhouette={max(silhouettes):.3f})")

# 최적 k로 최종 군집화
km_final = KMeans(n_clusters=best_k, random_state=42, n_init=10)
cluster_labels = km_final.fit_predict(X)
X_raw_copy = X_raw.copy()
X_raw_copy['cluster'] = cluster_labels

# 군집별 특성 요약
cluster_summary = X_raw_copy.groupby('cluster').agg(['mean', 'count']).round(2)
print("\n군집별 평균값:")
print(X_raw_copy.groupby('cluster')[num_cols].mean().round(2))

# 결과 저장
for c in range(best_k):
    size = (cluster_labels == c).sum()
    results.append({
        "분석종류": "K-Means 군집화",
        "군집/항목": f"군집{c}",
        "크기(샘플수)": size,
        "비율(%)": round(size / len(cluster_labels) * 100, 1),
        "실루엣점수": round(max(silhouettes), 3),
        "설명": f"군집{c}: {size}개 샘플 ({size/len(cluster_labels)*100:.1f}%)"
    })
```

---

### ② DBSCAN 군집화 (밀도 기반)

언제: 군집 수 모름, 불규칙한 형태의 군집, 노이즈 탐지 포함

```python
from sklearn.cluster import DBSCAN
from sklearn.neighbors import NearestNeighbors

# eps 자동 추정 (k-distance 그래프)
k = min(5, X.shape[1])
nbrs = NearestNeighbors(n_neighbors=k).fit(X)
distances, _ = nbrs.kneighbors(X)
distances = np.sort(distances[:, -1])

fig, ax = plt.subplots(figsize=(8, 4))
ax.plot(distances)
ax.set_xlabel('데이터 포인트 (정렬)')
ax.set_ylabel(f'{k}번째 이웃까지의 거리')
ax.set_title('k-distance 그래프 (꺾이는 지점이 권장 eps)')
plt.tight_layout()
plt.show()

# DBSCAN 실행 (eps는 위 그래프 꺾임점 기준으로 조정)
eps_val = float(np.percentile(distances, 90))
dbscan = DBSCAN(eps=eps_val, min_samples=5)
db_labels = dbscan.fit_predict(X)

n_clusters = len(set(db_labels)) - (1 if -1 in db_labels else 0)
n_noise = (db_labels == -1).sum()
print(f"발견된 군집 수: {n_clusters}")
print(f"노이즈(이상값) 포인트: {n_noise}개 ({n_noise/len(db_labels)*100:.1f}%)")

# 결과 저장
results.append({
    "분석종류": "DBSCAN 군집화",
    "군집/항목": f"전체",
    "크기(샘플수)": len(db_labels),
    "비율(%)": 100.0,
    "실루엣점수": round(silhouette_score(X, db_labels), 3) if n_clusters > 1 else None,
    "설명": f"군집 {n_clusters}개 발견, 노이즈 {n_noise}개"
})
for c in sorted(set(db_labels)):
    label_name = f"군집{c}" if c != -1 else "노이즈(-1)"
    size = (db_labels == c).sum()
    results.append({
        "분석종류": "DBSCAN 군집화",
        "군집/항목": label_name,
        "크기(샘플수)": size,
        "비율(%)": round(size / len(db_labels) * 100, 1),
        "실루엣점수": "",
        "설명": f"{label_name}: {size}개"
    })
```

---

### ③ PCA — 차원 축소 및 시각화

언제: 변수가 많아 전체 구조를 파악하기 어려울 때, 군집을 2D로 시각화할 때

```python
from sklearn.decomposition import PCA

# 분산 설명량 확인
pca_full = PCA()
pca_full.fit(X)
cumvar = np.cumsum(pca_full.explained_variance_ratio_)

fig, axes = plt.subplots(1, 2, figsize=(12, 4))
axes[0].bar(range(1, len(cumvar)+1), pca_full.explained_variance_ratio_)
axes[0].set_xlabel('주성분 번호')
axes[0].set_ylabel('설명 분산 비율')
axes[0].set_title('각 PC의 분산 설명량')
axes[1].plot(range(1, len(cumvar)+1), cumvar, 'bo-')
axes[1].axhline(0.8, color='red', linestyle='--', label='80% 기준선')
axes[1].set_xlabel('주성분 개수')
axes[1].set_ylabel('누적 분산 설명량')
axes[1].set_title('누적 분산 설명량')
axes[1].legend()
plt.tight_layout()
plt.show()

n_components_80 = int(np.argmax(cumvar >= 0.8)) + 1
print(f"분산 80% 설명에 필요한 주성분 수: {n_components_80}개")

# 2D PCA 시각화
pca2 = PCA(n_components=2)
X_pca = pca2.fit_transform(X)
print(f"PC1+PC2 설명 분산: {sum(pca2.explained_variance_ratio_)*100:.1f}%")

fig, ax = plt.subplots(figsize=(8, 6))
# K-Means 결과가 있으면 색상으로 구분, 없으면 단색
if 'cluster_labels' in dir():
    scatter = ax.scatter(X_pca[:, 0], X_pca[:, 1], c=cluster_labels, cmap='tab10', alpha=0.6)
    plt.colorbar(scatter, label='군집')
else:
    ax.scatter(X_pca[:, 0], X_pca[:, 1], alpha=0.5)
ax.set_xlabel(f'PC1 ({pca2.explained_variance_ratio_[0]*100:.1f}%)')
ax.set_ylabel(f'PC2 ({pca2.explained_variance_ratio_[1]*100:.1f}%)')
ax.set_title('PCA 2D 시각화')
plt.tight_layout()
plt.show()

# 변수 기여도 (loadings)
loadings = pd.DataFrame(pca2.components_.T,
                        columns=['PC1', 'PC2'],
                        index=num_cols)
print("\n각 변수의 주성분 기여도 (절댓값 클수록 영향력 큼):")
print(loadings.abs().sort_values('PC1', ascending=False).round(3))

results.append({
    "분석종류": "PCA 차원 축소",
    "군집/항목": "전체",
    "크기(샘플수)": X.shape[0],
    "비율(%)": 100.0,
    "실루엣점수": "",
    "설명": f"2D 설명분산={sum(pca2.explained_variance_ratio_)*100:.1f}%, 80%까지={n_components_80}개 PC"
})
```

---

### ④ t-SNE — 고차원 데이터 2D 시각화

언제: PCA로 군집 구분이 잘 안 될 때, 비선형 구조 시각화

```python
from sklearn.manifold import TSNE

# 샘플이 많으면 서브샘플링 (t-SNE는 느림)
max_samples = 2000
if X.shape[0] > max_samples:
    idx = np.random.choice(X.shape[0], max_samples, replace=False)
    X_sub = X[idx]
    print(f"샘플 수 {X.shape[0]} → {max_samples}로 서브샘플링 (속도 최적화)")
else:
    X_sub = X
    idx = np.arange(X.shape[0])

tsne = TSNE(n_components=2, perplexity=min(30, len(X_sub)//4), random_state=42, n_iter=1000)
X_tsne = tsne.fit_transform(X_sub)

fig, ax = plt.subplots(figsize=(8, 6))
if 'cluster_labels' in dir():
    sub_labels = cluster_labels[idx] if len(cluster_labels) > max_samples else cluster_labels
    scatter = ax.scatter(X_tsne[:, 0], X_tsne[:, 1], c=sub_labels, cmap='tab10', alpha=0.6)
    plt.colorbar(scatter, label='군집')
else:
    ax.scatter(X_tsne[:, 0], X_tsne[:, 1], alpha=0.5)
ax.set_title('t-SNE 2D 시각화')
ax.set_xlabel('t-SNE 1')
ax.set_ylabel('t-SNE 2')
plt.tight_layout()
plt.show()

results.append({
    "분석종류": "t-SNE 시각화",
    "군집/항목": "전체",
    "크기(샘플수)": len(X_sub),
    "비율(%)": round(len(X_sub)/X.shape[0]*100, 1),
    "실루엣점수": "",
    "설명": f"t-SNE 2D 완료 (perplexity={min(30, len(X_sub)//4)})"
})
```

---

### ⑤ Isolation Forest — 이상값 탐지

언제: "비정상 거래 찾아줘", "이상한 행 탐지해줘", 레이블 없는 이상탐지

```python
from sklearn.ensemble import IsolationForest

# contamination: 전체 중 이상값으로 볼 비율 (기본 5%)
contamination = 0.05
iso = IsolationForest(contamination=contamination, random_state=42, n_estimators=100)
anomaly_labels = iso.fit_predict(X)  # -1=이상값, 1=정상
anomaly_scores = iso.decision_function(X)  # 점수 낮을수록 이상

n_anomalies = (anomaly_labels == -1).sum()
print(f"이상값 탐지: {n_anomalies}개 ({n_anomalies/len(anomaly_labels)*100:.1f}%)")

# 원본 데이터에 결과 추가
X_raw_copy2 = X_raw.copy()
X_raw_copy2['anomaly_label'] = anomaly_labels
X_raw_copy2['anomaly_score'] = anomaly_scores.round(4)

# 이상값 상위 10개 출력
anomalies = X_raw_copy2[X_raw_copy2['anomaly_label'] == -1].sort_values('anomaly_score')
print("\n이상값 상위 10개 (anomaly_score 낮을수록 더 이상):")
print(anomalies.head(10))

# 시각화 (PCA 공간에서 이상값 표시)
if 'X_pca' in dir():
    fig, ax = plt.subplots(figsize=(8, 6))
    normal_mask = anomaly_labels == 1
    ax.scatter(X_pca[normal_mask, 0], X_pca[normal_mask, 1],
               c='steelblue', alpha=0.4, label='정상', s=20)
    ax.scatter(X_pca[~normal_mask, 0], X_pca[~normal_mask, 1],
               c='red', alpha=0.8, label='이상값', s=50, marker='x')
    ax.set_title(f'이상값 탐지 결과 (PCA 공간, {n_anomalies}개 이상)')
    ax.legend()
    plt.tight_layout()
    plt.show()

results.append({
    "분석종류": "Isolation Forest 이상탐지",
    "군집/항목": "이상값",
    "크기(샘플수)": n_anomalies,
    "비율(%)": round(n_anomalies / len(anomaly_labels) * 100, 1),
    "실루엣점수": "",
    "설명": f"이상값 {n_anomalies}개 탐지 (contamination={contamination})"
})
```

---

### 마지막 셀: ml-unsupervised_result.csv 저장

```python
results_df = pd.DataFrame(results)

col_order = ["분석종류", "군집/항목", "크기(샘플수)", "비율(%)", "실루엣점수", "설명"]
results_df = results_df[[c for c in col_order if c in results_df.columns]]

output_path = "ml-unsupervised_result.csv"
results_df.to_csv(output_path, index=False, encoding='utf-8-sig')

print(f"✅ ml-unsupervised_result.csv 저장 완료: {len(results_df)}개 분석 결과")
print(results_df.to_string(index=False))
```

---

### 노트북 실행 (결과 내장)

```bash
pip install scikit-learn pandas numpy matplotlib seaborn jupyter nbconvert --quiet
jupyter nbconvert --to notebook --execute \
  --ExecutePreprocessor.timeout=300 \
  --output ml-unsupervised.ipynb \
  ml-unsupervised.ipynb
```

---

---

## Context Validation

분석 시작 전 아래 항목을 확인하세요:
- [ ] 분석 파일 경로 및 형식 확인 (CSV·JSON·Parquet·Excel·TSV)
- [ ] 정답 레이블(Y 컬럼)이 없는 비지도학습 데이터인가
- [ ] 수치형 컬럼이 충분히 있는가 (군집화·PCA 최소 2개 이상)
- [ ] 결측치가 처리되었는가 (또는 처리 예정)
- [ ] 군집 수(K)를 사전에 알고 있는가 (K-Means 사용 시)

---

## Output Template


```markdown
# 비지도 머신러닝 분석 보고서

> **파일**: {파일명} | **분석일**: {날짜} | **사용한 기법**: {기법 종류}

## 1. 분석 목적
(무엇을 발견하려 했는지)

## 2. 발견된 패턴 / 군집 해석
(각 군집의 특성을 사람이 이해할 수 있는 언어로 설명)
예: "군집 0: 구매 빈도 높고 평균 주문 금액 낮음 → 다수 소액 구매자"

## 3. 이상값 현황 (이상탐지 수행 시)
(이상값이 몇 개 발견됐고 어떤 특성인지)

## 4. 시각화 요약
(PCA/t-SNE 그래프에서 관찰된 구조 설명)

## 5. 한계 및 주의사항
(비지도학습 특성상 정답이 없음, 해석의 주관성, 하이퍼파라미터 민감도)

## 6. 추천 다음 단계
(군집 레이블을 활용한 지도학습 추천, 추가 Feature Engineering 방향 등)
```

---

### 최종 출력물

| 파일 | 내용 |
|------|------|
| `ml-unsupervised.ipynb` | 비지도학습 코드 + 실행결과(차트, 군집 결과) 내장 |
| `ml-unsupervised_result.csv` | 군집·이상탐지 결과 요약표 (엑셀에서 바로 열 수 있음) |
| `ml-unsupervised_report.md` | 발견된 패턴을 쉬운 말로 해석한 한국어 보고서 |

**저장 경로 결정 우선순위:**
1. 사용자가 명시적으로 저장 위치를 지정한 경우 → 해당 경로 사용
2. 사용자가 폴더를 선택(마운트)한 경우 → 마운트된 폴더 안에 저장
3. 위 두 경우가 아니면 → `mnt/outputs/` 폴더에 저장

별도 PNG 파일은 생성하지 않습니다. 차트는 노트북 안에 포함됩니다.

---

## 비지도학습 용어 쉬운 말 설명

- **군집(Cluster)**: 비슷한 것들끼리 자동으로 묶인 그룹
- **K-Means**: "몇 개의 그룹으로 나눌지" 미리 정하고 가장 가까운 중심에 배정하는 방법
- **DBSCAN**: 밀도가 높은 지역을 군집으로 보고, 홀로 떨어진 것을 노이즈로 처리
- **Silhouette Score**: 군집이 얼마나 잘 분리됐는지 (-1~1, 높을수록 좋음)
- **PCA**: 여러 변수를 2~3개의 핵심 축으로 압축하는 차원 축소
- **t-SNE**: 고차원 데이터를 2D 지도로 그려주는 시각화 도구 (계산이 느림)
- **Isolation Forest**: 혼자 떨어진 포인트를 이상값으로 탐지하는 알고리즘
- **contamination**: "전체 중 몇 %가 이상값일 것 같다"는 사전 추정치
