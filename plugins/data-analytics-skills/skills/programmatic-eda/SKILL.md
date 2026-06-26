---
name: programmatic-eda
description: 모범 사례에 따른 체계적인 탐색적 데이터 분석. 데이터 구조를 이해하거나, 데이터 품질 문제(중복, 누락, 불일치, 이상치)를 식별하거나, 분포를 검토하거나, 상관관계를 감지하거나, 시각화를 생성할 때 사용하세요. 분석 전에 포괄적인 데이터 프로파일링 및 검증 검사를 제공합니다. | Systematic exploratory data analysis following best practices. Use when analyzing any dataset to understand structure, identify data quality issues (duplicates, missing values, inconsistencies, outliers), examine distributions, detect correlations, and generate visualizations. Provides comprehensive data profiling with sanity checks before analysis.
---

# Programmatic EDA

## Phase
Phase 2 — 데이터 이해

## Input
- 이전 스킬: analysis-path-guide (선택), schema-mapper (선택)
- 받는 파일: 원본 데이터 파일 (CSV / Excel / JSON / Parquet)
- `context_packet.json` (존재하면 자동 읽기)

## Output
- `programmatic-eda.ipynb` — 실행 결과 내장 노트북
- `programmatic-eda_result.csv` — 컬럼별 품질 요약 테이블
- `programmatic-eda_report.md` — 한국어 해석 리포트

---

## 2단계 실행 구조

| 단계 | 언제 | 무엇을 |
|------|------|--------|
| **1단계 (최초 1회)** | 데이터를 처음 받을 때 | Claude가 대화로 도메인 맥락 파악 → Config Block 초안 제안 |
| **2단계 (매 실행)** | 노트북 실행할 때마다 | Config Block 상단 값만 수정 → 나머지는 자동 |

---

## 셀 1: Config Block

```python
# =====================================================================
# CONFIG BLOCK — 이 셀만 수정하세요
# =====================================================================
DATA_PATH          = "데이터_파일_경로.csv"   # ← 매 실행마다 변경
TARGET_COL         = None                     # 예측 대상 컬럼 (없으면 None)
MISSING_THRESHOLD  = 5.0                      # 결측 비율 경고 기준 (%)
OUTLIER_THRESHOLD  = 1.5                      # IQR 배수 (이상치 탐지 민감도)
DUPLICATE_THRESHOLD = 1.0                     # 중복 비율 경고 기준 (%)
DOMAIN_NOTES       = []                       # 예: ["음수 불가 컬럼: price", "범위: age 0-120"]
# =====================================================================
```

---

## 셀 2: 라이브러리 로드 + 데이터 로드 + 드리프트 탐지

```python
import pandas as pd
import numpy as np
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
import matplotlib.font_manager as fm
import seaborn as sns
import os, json, warnings
from datetime import datetime
warnings.filterwarnings("ignore")

# 한글 폰트 설정
try:
    plt.rcParams["font.family"] = "AppleGothic"
except:
    plt.rcParams["font.family"] = "DejaVu Sans"
plt.rcParams["axes.unicode_minus"] = False

# ── 데이터 로드 ──────────────────────────────────────────────────────
def load_data(path):
    ext = os.path.splitext(path)[1].lower()
    try:
        if ext == ".csv":
            try:    return pd.read_csv(path, encoding="utf-8")
            except: return pd.read_csv(path, encoding="cp949")
        elif ext in (".xlsx", ".xls"):
            return pd.read_excel(path)
        elif ext == ".json":
            return pd.read_json(path)
        elif ext == ".parquet":
            return pd.read_parquet(path)
        else:
            raise ValueError(f"지원하지 않는 형식: {ext}")
    except Exception as e:
        print(f"❌ 데이터 로드 실패: {e}"); raise

# ── 스키마 드리프트 탐지 ──────────────────────────────────────────────
def check_schema_drift(df, baseline_path="programmatic-eda_baseline_schema.json"):
    current = {
        "columns":    list(df.columns),
        "dtypes":     {c: str(df[c].dtype) for c in df.columns},
        "categories": {
            c: sorted([str(v) for v in df[c].dropna().unique()])
            for c in df.select_dtypes(include=["object", "category"]).columns
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

# ── context_packet.json 읽기 (있으면) ────────────────────────────────
def load_eda_hints():
    hints = {}
    if os.path.exists("context_packet.json"):
        with open("context_packet.json", "r", encoding="utf-8") as f:
            pkt = json.load(f)
        hints["table_type"]          = pkt.get("table_type", "")
        hints["target_col"]          = pkt.get("target_col", TARGET_COL)
        hints["meaningful_missing"]  = pkt.get("meaningful_missing", {})
        hints["domain_notes"]        = pkt.get("domain_notes", DOMAIN_NOTES)
        print(f"📦 context_packet 로드됨: table_type={hints['table_type']}, "
              f"target={hints['target_col']}")
    else:
        hints["table_type"]         = ""
        hints["target_col"]         = TARGET_COL
        hints["meaningful_missing"] = {}
        hints["domain_notes"]       = DOMAIN_NOTES
    return hints

df    = load_data(DATA_PATH)
hints = load_eda_hints()
effective_target = hints["target_col"]

check_schema_drift(df)

if hints["domain_notes"]:
    print("\n📋 도메인 노트:")
    for note in hints["domain_notes"]:
        print(f"   • {note}")

print(f"\n✅ 데이터 로드 완료: {df.shape[0]:,}행 × {df.shape[1]}열")
```

---

## 셀 3: 기본 구조 확인

```python
print("=" * 60)
print("1단계: 데이터 구조 개요")
print("=" * 60)

print(f"\n📐 크기: {df.shape[0]:,}행 × {df.shape[1]}열")
print(f"\n🗂️  컬럼 목록 ({df.shape[1]}개):")
for col in df.columns:
    dtype   = str(df[col].dtype)
    n_null  = df[col].isna().sum()
    n_uniq  = df[col].nunique()
    sample  = df[col].dropna().iloc[0] if n_null < len(df) else "ALL NULL"
    print(f"   {col:<30} dtype={dtype:<12} null={n_null:>6}  unique={n_uniq:>6}  예시={sample}")

print("\n\n📊 수치형 변수 기초 통계:")
print(df.describe(include="number").T.to_string())

print("\n\n📝 범주형 변수 기초 통계:")
cat_cols = df.select_dtypes(include=["object", "category"]).columns.tolist()
if cat_cols:
    print(df[cat_cols].describe().T.to_string())
else:
    print("   범주형 변수 없음")

print("\n\n🕐 날짜형 변수:")
date_cols = df.select_dtypes(include=["datetime64"]).columns.tolist()
if date_cols:
    for dc in date_cols:
        print(f"   {dc}: {df[dc].min()} ~ {df[dc].max()}")
else:
    print("   datetime 타입 없음 (문자열 날짜 컬럼이 있으면 아래에서 변환 권장)")
```

---

## 셀 4: 결측값 분석

```python
print("=" * 60)
print("2단계: 결측값 분석")
print("=" * 60)

missing = pd.DataFrame({
    "컬럼":     df.columns,
    "결측수":   df.isna().sum().values,
    "결측율(%)": (df.isna().mean() * 100).round(2).values,
    "dtype":    df.dtypes.astype(str).values
}).sort_values("결측율(%)", ascending=False)

missing["상태"] = missing["결측율(%)"].apply(
    lambda x: "🔴 심각(>30%)" if x > 30
    else ("🟡 주의(>5%)" if x > MISSING_THRESHOLD
    else ("⚪ 없음" if x == 0 else "🟢 양호"))
)

# meaningful_missing 표시
mm = hints.get("meaningful_missing", {})
if mm:
    missing["의미있는결측"] = missing["컬럼"].map(
        lambda c: mm.get(c, {}).get("strategy", "") if c in mm else ""
    )
    print(f"\n📦 의미있는 결측값 컬럼: {list(mm.keys())}")

print(missing.to_string(index=False))

# 경고 발행
bad_cols = missing[missing["결측율(%)"] > MISSING_THRESHOLD]["컬럼"].tolist()
if bad_cols:
    print(f"\n⚠️  결측율 {MISSING_THRESHOLD}% 초과 컬럼: {bad_cols}")
else:
    print(f"\n✅ 결측율 {MISSING_THRESHOLD}% 초과 컬럼 없음")

# 결측 패턴 시각화
fig, ax = plt.subplots(figsize=(10, max(4, len(df.columns) * 0.3)))
cols_with_missing = missing[missing["결측수"] > 0]["컬럼"].tolist()
if cols_with_missing:
    rates = (df[cols_with_missing].isna().mean() * 100).sort_values(ascending=True)
    rates.plot(kind="barh", ax=ax, color="steelblue", alpha=0.7)
    ax.axvline(MISSING_THRESHOLD, color="orange", linestyle="--", label=f"기준 {MISSING_THRESHOLD}%")
    ax.axvline(30, color="red", linestyle="--", label="심각 30%")
    ax.set_xlabel("결측율 (%)"); ax.set_title("컬럼별 결측율")
    ax.legend(); plt.tight_layout()
    plt.savefig("eda_missing.png", dpi=100, bbox_inches="tight")
    print("📊 결측율 차트 저장됨 → eda_missing.png")
else:
    print("✅ 결측값 없는 완벽한 데이터셋!")
plt.close()
```

---

## 셀 5: 중복 탐지

```python
print("=" * 60)
print("3단계: 중복 탐지")
print("=" * 60)

n_total  = len(df)
n_dup    = df.duplicated().sum()
dup_rate = n_dup / n_total * 100

print(f"전체 행: {n_total:,}")
print(f"완전 중복: {n_dup:,} ({dup_rate:.2f}%)")

if dup_rate > DUPLICATE_THRESHOLD:
    print(f"⚠️  중복율 {dup_rate:.2f}% → 기준 {DUPLICATE_THRESHOLD}% 초과!")
    print("\n중복 행 샘플 (상위 5개):")
    dup_rows = df[df.duplicated(keep=False)].sort_values(df.columns.tolist())
    print(dup_rows.head(10).to_string())
else:
    print(f"✅ 중복율 {dup_rate:.2f}% — 기준({DUPLICATE_THRESHOLD}%) 이내")

# 준중복: 주요 컬럼 기준 중복 검사
num_cols = df.select_dtypes(include="number").columns.tolist()
cat_cols = df.select_dtypes(include=["object", "category"]).columns.tolist()
key_candidates = cat_cols[:3] + num_cols[:2]  # 간단한 휴리스틱

if len(key_candidates) >= 2:
    quasi_dup = df.duplicated(subset=key_candidates).sum()
    print(f"\n준중복 ({key_candidates} 기준): {quasi_dup:,}개 ({quasi_dup/n_total*100:.2f}%)")
```

---

## 셀 6: 수치형 변수 분포 + 이상치 탐지

```python
print("=" * 60)
print("4단계: 수치형 변수 분포 & 이상치")
print("=" * 60)

num_cols = df.select_dtypes(include="number").columns.tolist()
if not num_cols:
    print("수치형 변수 없음");
else:
    outlier_report = []
    n_cols = min(len(num_cols), 4)
    n_rows = (len(num_cols) + n_cols - 1) // n_cols

    fig, axes = plt.subplots(n_rows, n_cols,
                             figsize=(n_cols * 4, n_rows * 3),
                             squeeze=False)

    for i, col in enumerate(num_cols):
        ax  = axes[i // n_cols][i % n_cols]
        s   = df[col].dropna()

        # IQR 이상치
        Q1, Q3 = s.quantile(0.25), s.quantile(0.75)
        IQR    = Q3 - Q1
        lo     = Q1 - OUTLIER_THRESHOLD * IQR
        hi     = Q3 + OUTLIER_THRESHOLD * IQR
        n_out  = ((s < lo) | (s > hi)).sum()
        out_rt = n_out / len(s) * 100

        # 왜도
        skewness = s.skew()

        ax.hist(s, bins=30, color="steelblue", alpha=0.7, edgecolor="white")
        ax.axvline(lo, color="red",  linestyle="--", linewidth=1, label=f"IQR×{OUTLIER_THRESHOLD}")
        ax.axvline(hi, color="red",  linestyle="--", linewidth=1)
        ax.set_title(f"{col}\nskew={skewness:.2f}  이상치={out_rt:.1f}%",
                     fontsize=9)
        ax.legend(fontsize=7)

        outlier_report.append({
            "컬럼":    col,
            "평균":    round(s.mean(), 4),
            "중앙값":  round(s.median(), 4),
            "표준편차": round(s.std(), 4),
            "왜도":    round(skewness, 4),
            "이상치수": n_out,
            "이상치율(%)": round(out_rt, 2),
            "하한":    round(lo, 4),
            "상한":    round(hi, 4)
        })

    # 빈 서브플롯 숨기기
    for j in range(len(num_cols), n_rows * n_cols):
        axes[j // n_cols][j % n_cols].set_visible(False)

    plt.suptitle("수치형 변수 분포 (IQR 이상치 경계 표시)", y=1.01, fontsize=11)
    plt.tight_layout()
    plt.savefig("eda_distributions.png", dpi=100, bbox_inches="tight")
    print("📊 분포 차트 저장됨 → eda_distributions.png")
    plt.close()

    outlier_df = pd.DataFrame(outlier_report)
    print("\n수치형 변수 이상치 요약:")
    print(outlier_df.to_string(index=False))

    high_outlier = outlier_df[outlier_df["이상치율(%)"] > 5]["컬럼"].tolist()
    if high_outlier:
        print(f"\n⚠️  이상치율 5% 초과 컬럼: {high_outlier}")
    else:
        print("\n✅ 이상치율 5% 초과 컬럼 없음")
```

---

## 셀 7: 범주형 변수 분포

```python
print("=" * 60)
print("5단계: 범주형 변수 분포")
print("=" * 60)

cat_cols = df.select_dtypes(include=["object", "category"]).columns.tolist()
if not cat_cols:
    print("범주형 변수 없음")
else:
    n_cols = min(len(cat_cols), 3)
    n_rows = (len(cat_cols) + n_cols - 1) // n_cols
    fig, axes = plt.subplots(n_rows, n_cols,
                             figsize=(n_cols * 5, n_rows * 3.5),
                             squeeze=False)

    cat_report = []
    for i, col in enumerate(cat_cols):
        ax  = axes[i // n_cols][i % n_cols]
        vc  = df[col].value_counts()
        top = vc.head(10)

        top.plot(kind="barh", ax=ax, color="coral", alpha=0.8)
        ax.set_title(f"{col}\n(고유값={df[col].nunique()}, 상위10)", fontsize=9)
        ax.set_xlabel("빈도")
        ax.invert_yaxis()

        cat_report.append({
            "컬럼":    col,
            "고유값수": df[col].nunique(),
            "최빈값":  vc.index[0],
            "최빈율(%)": round(vc.iloc[0] / len(df) * 100, 2),
            "결측수":  df[col].isna().sum()
        })

    for j in range(len(cat_cols), n_rows * n_cols):
        axes[j // n_cols][j % n_cols].set_visible(False)

    plt.tight_layout()
    plt.savefig("eda_categoricals.png", dpi=100, bbox_inches="tight")
    print("📊 범주형 분포 차트 저장됨 → eda_categoricals.png")
    plt.close()

    print(pd.DataFrame(cat_report).to_string(index=False))

    # 고유값 매우 많은 컬럼 경고 (잠재적 ID 컬럼)
    high_card = [r["컬럼"] for r in cat_report
                 if r["고유값수"] > 0.5 * len(df) and r["고유값수"] > 50]
    if high_card:
        print(f"\n⚠️  고카디널리티 컬럼 (ID 가능성): {high_card}")
```

---

## 셀 8: 상관관계 분석

```python
print("=" * 60)
print("6단계: 상관관계 분석")
print("=" * 60)

num_cols = df.select_dtypes(include="number").columns.tolist()
if len(num_cols) < 2:
    print("수치형 변수가 2개 미만 — 상관관계 분석 생략")
else:
    corr = df[num_cols].corr()

    fig, ax = plt.subplots(figsize=(max(8, len(num_cols) * 0.8),
                                    max(6, len(num_cols) * 0.7)))
    mask = np.triu(np.ones_like(corr, dtype=bool))
    sns.heatmap(corr, mask=mask, annot=True, fmt=".2f",
                cmap="RdBu_r", center=0, vmin=-1, vmax=1,
                ax=ax, annot_kws={"size": 8})
    ax.set_title("수치형 변수 상관계수 히트맵 (하삼각)")
    plt.tight_layout()
    plt.savefig("eda_correlation.png", dpi=100, bbox_inches="tight")
    print("📊 상관관계 히트맵 저장됨 → eda_correlation.png")
    plt.close()

    # 강상관 쌍 추출
    high_corr_pairs = []
    for i in range(len(num_cols)):
        for j in range(i + 1, len(num_cols)):
            r = corr.iloc[i, j]
            if abs(r) >= 0.7:
                high_corr_pairs.append((num_cols[i], num_cols[j], round(r, 3)))

    if high_corr_pairs:
        print(f"\n🔗 강상관 쌍 (|r| ≥ 0.7):")
        for c1, c2, r in sorted(high_corr_pairs, key=lambda x: abs(x[2]), reverse=True):
            print(f"   {c1} ↔ {c2}: r = {r}")
    else:
        print("\n✅ |r| ≥ 0.7 강상관 쌍 없음")
```

---

## 셀 9: 타겟 변수 관계 분석

```python
print("=" * 60)
print("7단계: 타겟 변수 관계 분석")
print("=" * 60)

if effective_target is None or effective_target not in df.columns:
    print(f"ℹ️  TARGET_COL 미설정 — 타겟 관계 분석 생략")
else:
    target = effective_target
    print(f"🎯 타겟 변수: {target}")

    is_binary     = df[target].nunique() == 2
    is_continuous = df[target].dtype in ["float64", "float32", "int64", "int32"] \
                    and df[target].nunique() > 10

    num_features = [c for c in df.select_dtypes(include="number").columns
                    if c != target]
    cat_features = df.select_dtypes(include=["object", "category"]).columns.tolist()

    if is_binary or not is_continuous:
        # 분류 타겟: 클래스 불균형 확인
        vc = df[target].value_counts()
        print(f"\n클래스 분포:\n{vc.to_string()}")
        minority_rate = vc.iloc[-1] / len(df) * 100
        if minority_rate < 10:
            print(f"⚠️  심각한 클래스 불균형! 소수 클래스 비율 = {minority_rate:.1f}%")
        elif minority_rate < 20:
            print(f"⚠️  클래스 불균형 있음. 소수 클래스 비율 = {minority_rate:.1f}%")
        else:
            print(f"✅ 클래스 불균형 양호 ({minority_rate:.1f}%)")

    if num_features and is_continuous:
        # 연속 타겟: 피처별 산점도
        n_show = min(len(num_features), 6)
        fig, axes = plt.subplots(1, n_show, figsize=(n_show * 4, 4))
        if n_show == 1: axes = [axes]
        for i, feat in enumerate(num_features[:n_show]):
            axes[i].scatter(df[feat], df[target], alpha=0.3, s=5)
            axes[i].set_xlabel(feat); axes[i].set_ylabel(target)
            r = df[[feat, target]].corr().iloc[0, 1]
            axes[i].set_title(f"r={r:.2f}")
        plt.tight_layout()
        plt.savefig("eda_target_scatter.png", dpi=100, bbox_inches="tight")
        print("📊 타겟 산점도 저장됨 → eda_target_scatter.png")
        plt.close()

    if cat_features:
        # 범주형 피처 vs 타겟 박스플롯
        n_show = min(len(cat_features), 4)
        fig, axes = plt.subplots(1, n_show, figsize=(n_show * 4, 4))
        if n_show == 1: axes = [axes]
        for i, feat in enumerate(cat_features[:n_show]):
            top_cats = df[feat].value_counts().head(8).index
            subset = df[df[feat].isin(top_cats)]
            if is_continuous:
                subset.boxplot(column=target, by=feat, ax=axes[i])
            else:
                pd.crosstab(subset[feat], subset[target], normalize="index") \
                  .plot(kind="bar", stacked=True, ax=axes[i])
            axes[i].set_title(f"{feat} vs {target}", fontsize=9)
            axes[i].tick_params(axis="x", rotation=30)
        plt.tight_layout()
        plt.savefig("eda_target_cat.png", dpi=100, bbox_inches="tight")
        print("📊 타겟-범주형 차트 저장됨 → eda_target_cat.png")
        plt.close()
```

---

## 셀 10: 결과 저장 및 리포트 생성

```python
print("=" * 60)
print("8단계: 결과 저장 및 리포트 생성")
print("=" * 60)

# ── result.csv 생성 ──────────────────────────────────────────────────
result_rows = []
for col in df.columns:
    s          = df[col]
    n_missing  = s.isna().sum()
    n_unique   = s.nunique()
    dtype      = str(s.dtype)
    is_num     = s.dtype.kind in "bifc"

    row = {
        "컬럼":       col,
        "dtype":      dtype,
        "결측수":     n_missing,
        "결측율(%)":  round(n_missing / len(df) * 100, 2),
        "고유값수":   n_unique,
        "결측상태":   ("심각" if n_missing/len(df) > 0.3
                       else "주의" if n_missing/len(df) > MISSING_THRESHOLD/100
                       else "양호"),
    }
    if is_num:
        sv = s.dropna()
        Q1, Q3 = sv.quantile(0.25), sv.quantile(0.75)
        IQR    = Q3 - Q1
        lo, hi = Q1 - OUTLIER_THRESHOLD * IQR, Q3 + OUTLIER_THRESHOLD * IQR
        n_out  = ((sv < lo) | (sv > hi)).sum()
        row.update({
            "평균":      round(sv.mean(), 4),
            "중앙값":    round(sv.median(), 4),
            "표준편차":  round(sv.std(), 4),
            "왜도":      round(sv.skew(), 4),
            "이상치수":  n_out,
            "이상치율(%)": round(n_out / len(sv) * 100, 2) if len(sv) > 0 else 0,
        })
    result_rows.append(row)

result_df = pd.DataFrame(result_rows)
result_df.to_csv("programmatic-eda_result.csv", index=False, encoding="utf-8-sig")
print("✅ programmatic-eda_result.csv 저장됨")

# ── report.md 생성 ───────────────────────────────────────────────────
now = datetime.now().strftime("%Y-%m-%d %H:%M")
n_dup    = df.duplicated().sum()
bad_miss = result_df[result_df["결측율(%)"] > MISSING_THRESHOLD]["컬럼"].tolist()
num_cols = df.select_dtypes(include="number").columns.tolist()
cat_cols = df.select_dtypes(include=["object","category"]).columns.tolist()

corr_txt = ""
if len(num_cols) >= 2:
    corr = df[num_cols].corr()
    pairs = []
    for i in range(len(num_cols)):
        for j in range(i+1, len(num_cols)):
            r = corr.iloc[i, j]
            if abs(r) >= 0.7:
                pairs.append(f"{num_cols[i]} ↔ {num_cols[j]}: r={r:.3f}")
    corr_txt = "\n".join(pairs) if pairs else "강상관 쌍 없음 (|r| < 0.7)"

target_txt = ""
if effective_target and effective_target in df.columns:
    target_txt = f"- 타겟 변수: **{effective_target}** (dtype: {df[effective_target].dtype}, 고유값: {df[effective_target].nunique()}개)"

domain_txt = "\n".join(f"- {n}" for n in hints["domain_notes"]) if hints["domain_notes"] else "- (없음)"

report = f"""# Programmatic EDA 리포트
생성일시: {now}
데이터: {DATA_PATH}

---

## 1. 데이터 개요

| 항목 | 값 |
|------|----|
| 행 수 | {len(df):,} |
| 컬럼 수 | {df.shape[1]} |
| 수치형 컬럼 | {len(num_cols)}개 |
| 범주형 컬럼 | {len(cat_cols)}개 |
| 완전 중복 행 | {n_dup:,}개 ({n_dup/len(df)*100:.2f}%) |
{target_txt}

---

## 2. 결측값 요약

{"⚠️ 결측율 " + str(MISSING_THRESHOLD) + "% 초과 컬럼: " + str(bad_miss) if bad_miss else "✅ 모든 컬럼의 결측율이 기준 이내"}

상세 내역은 `programmatic-eda_result.csv` 참조.

---

## 3. 이상치 요약

IQR × {OUTLIER_THRESHOLD} 기준 적용.

"""

# 이상치 5% 초과 컬럼
if num_cols:
    high_out = result_df[result_df.get("이상치율(%)", pd.Series(dtype=float)) > 5]["컬럼"].tolist() \
               if "이상치율(%)" in result_df.columns else []
    if high_out:
        report += f"⚠️ 이상치율 5% 초과 컬럼: {high_out}\n\n"
    else:
        report += "✅ 이상치율 5% 초과 컬럼 없음\n\n"

report += f"""---

## 4. 상관관계 주요 발견

```
{corr_txt}
```

---

## 5. 도메인 노트

{domain_txt}

---

## 6. 권장 다음 단계

- 결측값 처리 → **data-preprocessing** 스킬 사용
- 비즈니스 규칙 검증 → **data-quality-audit** 스킬 사용
- 통계 검정 → **stats-basic** 또는 **stats-advanced** 스킬 사용
- 머신러닝 → **feature-engineering** → **ml-supervised** 스킬 사용

---
*생성: DA Skills Plugin — programmatic-eda*
"""

with open("programmatic-eda_report.md", "w", encoding="utf-8") as f:
    f.write(report)
print("✅ programmatic-eda_report.md 저장됨")
print("\n🎉 EDA 완료!")
print(f"   생성 파일: programmatic-eda_result.csv, programmatic-eda_report.md")
print(f"   차트:      eda_missing.png, eda_distributions.png, eda_categoricals.png, eda_correlation.png")
```

---

## 출력 템플릿

**두 가지 출력을 생성합니다:**

① `programmatic-eda_result.csv` — 컬럼별 결측율·이상치율·통계 요약 테이블
② `programmatic-eda_report.md` — 데이터 개요·결측·이상치·상관관계·권장 다음 단계 한국어 리포트
③ `programmatic-eda.ipynb` — 위 셀 전체를 포함한 실행 가능 노트북
④ 차트 PNG 파일 — `eda_missing.png`, `eda_distributions.png`, `eda_categoricals.png`, `eda_correlation.png`

---

## 다른 스킬과의 연결

| 방향 | 스킬 | 연결 방법 |
|------|------|-----------|
| 이전 | analysis-path-guide | `context_packet.json` 자동 읽기 |
| 이전 | schema-mapper | `schema-mapper_result.csv` 참고 |
| 다음 | data-quality-audit | `programmatic-eda_result.csv` 전달 |
| 다음 | data-preprocessing | 결측·이상치 처리 방향 전달 |
| 다음 | stats-basic | 분포·상관관계 기반 검정 설계 |
