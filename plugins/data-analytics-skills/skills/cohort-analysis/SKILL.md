---
name: cohort-analysis
description: 유지율 및 행동 추적이 포함된 시간 기반 코호트 분석을 수행합니다. 사용자 유지율을 시간에 따라 분석하거나, 코호트 성능을 비교하거나, 라이프사이클 패턴을 식별하거나, 코호트별 기능 채택을 측정할 때 사용합니다. | Time-based cohort analysis with retention and behavior tracking. Use when analyzing user retention over time, comparing cohort performance, identifying lifecycle patterns, or measuring feature adoption by cohort.
---

# 코호트 분석

## Phase
Phase 4 — 분석 수행 (비즈니스 분석 레이어)

## Input
- 이전 스킬: programmatic-eda (권장)
- 받는 파일: 사용자 이벤트 로그 (CSV / Excel / JSON / Parquet)
  - 필수 컬럼: 사용자 ID, 코호트 기준일 (가입일 등), 활동일
- `context_packet.json` (존재하면 자동 읽기)

## Output
- `cohort-analysis.ipynb` — 실행 결과 내장 노트북
- `cohort-analysis_result.csv` — 코호트 × 기간 유지율 매트릭스
- `cohort-analysis_report.md` — 한국어 코호트 분석 리포트

---

## 2단계 실행 구조

| 단계 | 언제 | 무엇을 |
|------|------|--------|
| **1단계 (최초 1회)** | 데이터를 처음 받을 때 | Claude가 대화로 USER_COL, COHORT_COL, ACTIVITY_COL 파악 → Config Block 초안 제안 |
| **2단계 (매 실행)** | 노트북 실행할 때마다 | Config Block 상단 값만 수정 → 나머지 자동 실행 |

---

## 셀 1: Config Block

```python
# =====================================================================
# CONFIG BLOCK — 이 셀만 수정하세요
# =====================================================================
DATA_PATH     = "데이터_파일_경로.csv"   # ← 매 실행마다 변경

USER_COL      = "user_id"               # 사용자 식별 컬럼
COHORT_COL    = "signup_date"           # 코호트 기준일 컬럼 (가입일, 첫 구매일 등)
ACTIVITY_COL  = "activity_date"         # 활동일 컬럼 (로그인일, 구매일 등)

# 코호트 단위: "D"(일별), "W"(주별), "M"(월별, 기본), "Q"(분기별)
COHORT_UNIT   = "M"

# 추적 기간 수 (코호트 기준일로부터)
PERIODS       = 12

# 코호트별 최소 사용자 수 (이하면 분석 제외)
MIN_COHORT_SIZE = 10

# 값 컬럼 (없으면 None → 사용자 수 기반 유지율)
# 예: "revenue" → 금액 기반 유지율
VALUE_COL     = None

DOMAIN_NOTES  = []    # 예: ["구독 취소 후 재가입 포함", "테스트 계정 제외됨"]
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
import seaborn as sns
import os, json, warnings
from datetime import datetime
warnings.filterwarnings("ignore")

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
def check_schema_drift(df, baseline_path="cohort-analysis_baseline_schema.json"):
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

# ── context_packet.json 읽기 ─────────────────────────────────────────
def load_cohort_hints():
    hints = {"domain_notes": DOMAIN_NOTES}
    if os.path.exists("context_packet.json"):
        with open("context_packet.json", "r", encoding="utf-8") as f:
            pkt = json.load(f)
        hints["domain_notes"] = pkt.get("domain_notes", DOMAIN_NOTES)
        print("📦 context_packet 로드됨")
    return hints

df    = load_data(DATA_PATH)
hints = load_cohort_hints()
check_schema_drift(df)

if hints["domain_notes"]:
    print("\n📋 도메인 노트:")
    for note in hints["domain_notes"]: print(f"   • {note}")

print(f"\n✅ 데이터 로드 완료: {df.shape[0]:,}행 × {df.shape[1]}열")
```

---

## 셀 3: 데이터 전처리 및 검증

```python
print("=" * 60)
print("1단계: 데이터 전처리 및 컬럼 검증")
print("=" * 60)

# 필수 컬럼 존재 확인
required = [USER_COL, COHORT_COL, ACTIVITY_COL]
missing_req = [c for c in required if c not in df.columns]
if missing_req:
    raise ValueError(f"❌ 필수 컬럼 없음: {missing_req}\n"
                     f"   Config Block에서 컬럼명을 확인하세요.\n"
                     f"   실제 컬럼: {list(df.columns)}")

print(f"✅ 필수 컬럼 확인: {required}")

# 날짜 변환
for col in [COHORT_COL, ACTIVITY_COL]:
    if df[col].dtype == "object":
        df[col] = pd.to_datetime(df[col], errors="coerce")
        n_fail = df[col].isna().sum()
        if n_fail > 0:
            print(f"⚠️  '{col}' 날짜 변환 실패: {n_fail}행 → 제거됨")
            df = df[df[col].notna()]
    print(f"   {col}: {df[col].min().date()} ~ {df[col].max().date()}")

# 값 컬럼 확인
if VALUE_COL and VALUE_COL not in df.columns:
    print(f"⚠️  VALUE_COL '{VALUE_COL}' 없음 → 사용자 수 기반 분석으로 전환")
    effective_value_col = None
else:
    effective_value_col = VALUE_COL

# 활동일이 코호트일보다 앞선 이상 데이터 제거
n_before = len(df)
df = df[df[ACTIVITY_COL] >= df[COHORT_COL]]
n_removed = n_before - len(df)
if n_removed > 0:
    print(f"⚠️  활동일 < 코호트일 이상 데이터 제거: {n_removed}행")

print(f"\n유효 데이터: {len(df):,}행")
print(f"고유 사용자: {df[USER_COL].nunique():,}명")
print(f"데이터 기간: {df[COHORT_COL].min().date()} ~ {df[ACTIVITY_COL].max().date()}")
```

---

## 셀 4: 코호트 생성 및 기간 계산

```python
print("=" * 60)
print("2단계: 코호트 생성 및 기간 계산")
print("=" * 60)

# 코호트 단위 매핑
freq_map = {"D": "D", "W": "W", "M": "MS", "Q": "QS"}
freq = freq_map.get(COHORT_UNIT, "MS")

unit_label_map = {"D": "일", "W": "주", "M": "월", "Q": "분기"}
unit_label = unit_label_map.get(COHORT_UNIT, "월")

# 코호트 기준 기간 (Period)
df["cohort_period"]   = df[COHORT_COL].dt.to_period(COHORT_UNIT)
df["activity_period"] = df[ACTIVITY_COL].dt.to_period(COHORT_UNIT)

# 기간 인덱스 (0 = 가입 기간)
df["period_number"] = (df["activity_period"] - df["cohort_period"]).apply(
    lambda x: x.n if hasattr(x, "n") else int(x)
)

# 음수 기간 제거 (재처리)
df = df[df["period_number"] >= 0]

# PERIODS 제한
df = df[df["period_number"] <= PERIODS]

# 코호트별 최초 사용자 수 (period_number == 0)
cohort_sizes = df[df["period_number"] == 0].groupby("cohort_period")[USER_COL].nunique()

# 최소 코호트 크기 필터
valid_cohorts = cohort_sizes[cohort_sizes >= MIN_COHORT_SIZE].index
n_excluded = len(cohort_sizes) - len(valid_cohorts)
if n_excluded > 0:
    print(f"⚠️  최소 사용자 수({MIN_COHORT_SIZE}명) 미만 코호트 제외: {n_excluded}개")

df = df[df["cohort_period"].isin(valid_cohorts)]
cohort_sizes = cohort_sizes[cohort_sizes.index.isin(valid_cohorts)]

print(f"코호트 수: {len(valid_cohorts)}개")
print(f"추적 기간: {PERIODS}{unit_label}")
print(f"\n코호트별 초기 사용자 수 (상위 10):")
print(cohort_sizes.head(10).to_string())
```

---

## 셀 5: 유지율 매트릭스 계산

```python
print("=" * 60)
print("3단계: 유지율 매트릭스 계산")
print("=" * 60)

if effective_value_col:
    # 금액 기반: 코호트별 기간별 합계 금액
    cohort_data = df.groupby(["cohort_period", "period_number"])[effective_value_col].sum().reset_index()
    cohort_pivot = cohort_data.pivot_table(
        index="cohort_period",
        columns="period_number",
        values=effective_value_col,
        aggfunc="sum"
    )
    # 초기 금액 대비 유지율
    cohort_size_values = cohort_pivot[0]
    retention_matrix = cohort_pivot.divide(cohort_size_values, axis=0) * 100
    metric_label = f"{effective_value_col} 기반 유지율"
else:
    # 사용자 수 기반: 코호트별 기간별 고유 사용자 수
    cohort_data = df.groupby(["cohort_period", "period_number"])[USER_COL].nunique().reset_index()
    cohort_data.columns = ["cohort_period", "period_number", "n_users"]
    cohort_pivot = cohort_data.pivot_table(
        index="cohort_period",
        columns="period_number",
        values="n_users",
        aggfunc="sum"
    )
    # 초기 사용자 수 대비 유지율 (%)
    retention_matrix = cohort_pivot.divide(cohort_sizes, axis=0) * 100
    metric_label = "사용자 수 기반 유지율"

# 컬럼명 정리
retention_matrix.columns = [f"P{int(c)}" for c in retention_matrix.columns]
cohort_pivot.columns      = [f"P{int(c)}" for c in cohort_pivot.columns]

print(f"✅ 유지율 매트릭스 생성 완료 ({metric_label})")
print(f"   코호트 수: {len(retention_matrix)}개")
print(f"   추적 기간: P0 ~ P{PERIODS}")
print(f"\n유지율 매트릭스 (상위 5개 코호트):")
print(retention_matrix.head(5).round(1).to_string())
```

---

## 셀 6: 코호트 히트맵 시각화

```python
print("=" * 60)
print("4단계: 코호트 히트맵 시각화")
print("=" * 60)

fig, ax = plt.subplots(figsize=(
    max(12, len(retention_matrix.columns) * 0.9),
    max(6,  len(retention_matrix) * 0.45)
))

# 히트맵 데이터 (P0 제외 — 항상 100%)
plot_data = retention_matrix.drop(columns=["P0"], errors="ignore").fillna(np.nan)

sns.heatmap(
    plot_data,
    annot=True,
    fmt=".1f",
    cmap="YlOrRd_r",   # 높을수록 녹색 계열
    linewidths=0.3,
    ax=ax,
    vmin=0,
    vmax=100,
    annot_kws={"size": 8},
    cbar_kws={"label": "유지율 (%)"}
)

ax.set_title(
    f"코호트 유지율 히트맵\n({metric_label}, COHORT_UNIT={COHORT_UNIT})",
    fontsize=13, pad=15
)
ax.set_xlabel(f"가입 후 기간 ({unit_label})", fontsize=11)
ax.set_ylabel("코호트 (가입 기간)", fontsize=11)
ax.tick_params(axis="x", rotation=0)
ax.tick_params(axis="y", rotation=0)

plt.tight_layout()
plt.savefig("cohort_heatmap.png", dpi=120, bbox_inches="tight")
print("📊 코호트 히트맵 저장됨 → cohort_heatmap.png")
plt.close()

# 코호트 크기 막대 차트
fig2, ax2 = plt.subplots(figsize=(max(10, len(cohort_sizes) * 0.5), 4))
cohort_sizes.plot(kind="bar", ax=ax2, color="steelblue", alpha=0.8)
ax2.axhline(MIN_COHORT_SIZE, color="red", linestyle="--",
            label=f"최소 코호트 크기 ({MIN_COHORT_SIZE}명)")
ax2.set_title("코호트별 초기 사용자 수")
ax2.set_xlabel("코호트 기간"); ax2.set_ylabel("사용자 수")
ax2.legend(); ax2.tick_params(axis="x", rotation=45)
plt.tight_layout()
plt.savefig("cohort_sizes.png", dpi=100, bbox_inches="tight")
print("📊 코호트 크기 차트 저장됨 → cohort_sizes.png")
plt.close()
```

---

## 셀 7: 기간별 평균 유지율 추이

```python
print("=" * 60)
print("5단계: 기간별 평균 유지율 추이")
print("=" * 60)

avg_retention = retention_matrix.mean(skipna=True).reset_index()
avg_retention.columns = ["기간", "평균유지율(%)"]
avg_retention["평균유지율(%)"] = avg_retention["평균유지율(%)"].round(2)

print("기간별 평균 유지율:")
print(avg_retention.to_string(index=False))

# 주요 지표 계산
p1_key = "P1"
p3_key = "P3"
p6_key = "P6"
p12_key = "P12"

def get_retention(period_key):
    row = avg_retention[avg_retention["기간"] == period_key]
    return row["평균유지율(%)"].values[0] if len(row) > 0 else None

r1  = get_retention(p1_key)
r3  = get_retention(p3_key)
r6  = get_retention(p6_key)
r12 = get_retention(p12_key)

print(f"\n📌 핵심 유지율 지표:")
if r1  is not None: print(f"   1{unit_label} 유지율: {r1:.1f}%")
if r3  is not None: print(f"   3{unit_label} 유지율: {r3:.1f}%")
if r6  is not None: print(f"   6{unit_label} 유지율: {r6:.1f}%")
if r12 is not None: print(f"  12{unit_label} 유지율: {r12:.1f}%")

# 추이 시각화
fig, ax = plt.subplots(figsize=(12, 5))

# 전체 평균
valid_avg = avg_retention[avg_retention["기간"] != "P0"]
ax.plot(valid_avg["기간"], valid_avg["평균유지율(%)"],
        "ko-", linewidth=2, markersize=7, label="전체 평균", zorder=5)
ax.fill_between(range(len(valid_avg)), valid_avg["평균유지율(%)"],
                alpha=0.1, color="steelblue")

# 개별 코호트 (최신 5개)
recent_cohorts = retention_matrix.index[-5:]
colors = plt.cm.Blues(np.linspace(0.4, 0.9, len(recent_cohorts)))
for cohort, color in zip(recent_cohorts, colors):
    row = retention_matrix.loc[cohort].drop("P0", errors="ignore").dropna()
    ax.plot(row.index, row.values, "--", color=color, alpha=0.7,
            linewidth=1.5, label=str(cohort))

ax.set_xticks(range(len(valid_avg)))
ax.set_xticklabels(valid_avg["기간"], rotation=0)
ax.set_xlabel(f"가입 후 기간 ({unit_label})")
ax.set_ylabel("유지율 (%)")
ax.set_title(f"코호트 유지율 추이 (평균 + 최근 {len(recent_cohorts)}개 코호트)")
ax.legend(fontsize=8, loc="upper right")
ax.set_ylim(0, 105)
ax.grid(axis="y", alpha=0.4)
plt.tight_layout()
plt.savefig("cohort_retention_trend.png", dpi=100, bbox_inches="tight")
print("📊 유지율 추이 차트 저장됨 → cohort_retention_trend.png")
plt.close()
```

---

## 셀 8: 코호트 비교 분석 (최고/최저 성과 코호트)

```python
print("=" * 60)
print("6단계: 코호트 비교 분석")
print("=" * 60)

# 각 코호트의 장기 유지율 대표값 (P3 또는 P6 사용)
benchmark_period = p6_key if p6_key in retention_matrix.columns else p3_key if p3_key in retention_matrix.columns else "P1"
benchmark_col = retention_matrix[benchmark_period].dropna()

if len(benchmark_col) >= 3:
    top3    = benchmark_col.nlargest(3)
    bottom3 = benchmark_col.nsmallest(3)

    print(f"📈 {benchmark_period} 유지율 기준 상위 3 코호트:")
    for cohort, val in top3.items():
        size = cohort_sizes.get(cohort, "N/A")
        print(f"   {cohort}: {val:.1f}% (초기 {size}명)")

    print(f"\n📉 {benchmark_period} 유지율 기준 하위 3 코호트:")
    for cohort, val in bottom3.items():
        size = cohort_sizes.get(cohort, "N/A")
        print(f"   {cohort}: {val:.1f}% (초기 {size}명)")

    gap = top3.iloc[0] - bottom3.iloc[0]
    print(f"\n🔍 최고-최저 코호트 유지율 차이: {gap:.1f}%p")
    if gap > 20:
        print("⚠️  코호트 간 유지율 차이가 큽니다 → 가입 시기별 품질 차이 확인 권장")
    else:
        print("✅ 코호트 간 유지율이 비교적 안정적입니다")
else:
    print("ℹ️  코호트 수가 적어 비교 분석 생략")

# 코호트 크기 vs 유지율 산점도
if len(benchmark_col) >= 5:
    common = benchmark_col.index.intersection(cohort_sizes.index)
    sizes_arr = [cohort_sizes[c] for c in common]
    retentions_arr = [benchmark_col[c] for c in common]

    fig, ax = plt.subplots(figsize=(8, 5))
    ax.scatter(sizes_arr, retentions_arr, alpha=0.7, s=80, color="steelblue")
    for cohort, s, r in zip(common, sizes_arr, retentions_arr):
        ax.annotate(str(cohort), (s, r), textcoords="offset points",
                    xytext=(3, 3), fontsize=7, alpha=0.8)
    ax.set_xlabel("초기 코호트 크기 (명)")
    ax.set_ylabel(f"{benchmark_period} 유지율 (%)")
    ax.set_title(f"코호트 크기 vs {benchmark_period} 유지율")
    plt.tight_layout()
    plt.savefig("cohort_size_vs_retention.png", dpi=100, bbox_inches="tight")
    print("\n📊 코호트 크기-유지율 산점도 저장됨 → cohort_size_vs_retention.png")
    plt.close()
```

---

## 셀 9: 결과 저장 및 리포트 생성

```python
print("=" * 60)
print("7단계: 결과 저장 및 리포트 생성")
print("=" * 60)

# ── result.csv — 유지율 매트릭스 ────────────────────────────────────
export_df = retention_matrix.copy().round(2)
export_df.insert(0, "cohort_size", cohort_sizes)
export_df.index.name = "cohort_period"
export_df.to_csv("cohort-analysis_result.csv", encoding="utf-8-sig")
print("✅ cohort-analysis_result.csv 저장됨")

# ── report.md ────────────────────────────────────────────────────────
now = datetime.now().strftime("%Y-%m-%d %H:%M")

# 핵심 지표 문자열 생성
kpi_lines = []
for period_key, label in [(p1_key, f"1{unit_label}"), (p3_key, f"3{unit_label}"),
                           (p6_key, f"6{unit_label}"), (p12_key, f"12{unit_label}")]:
    val = get_retention(period_key)
    if val is not None:
        status = "🟢" if val >= 40 else ("🟡" if val >= 20 else "🔴")
        kpi_lines.append(f"| {label} 평균 유지율 | {val:.1f}% | {status} |")
kpi_table = "\n".join(kpi_lines) if kpi_lines else "| (데이터 없음) | - | - |"

domain_txt = "\n".join(f"- {n}" for n in hints["domain_notes"]) \
             if hints["domain_notes"] else "- (없음)"

# 코호트 크기 요약
size_mean = cohort_sizes.mean()
size_min  = cohort_sizes.min()
size_max  = cohort_sizes.max()

report = f"""# 코호트 분석 리포트
생성일시: {now}
데이터: {DATA_PATH}

---

## 1. 분석 개요

| 항목 | 값 |
|------|----|
| 분석 대상 코호트 수 | {len(valid_cohorts)}개 |
| 코호트 단위 | {COHORT_UNIT} ({unit_label}별) |
| 추적 기간 | {PERIODS}{unit_label} |
| 분석 지표 | {metric_label} |
| 코호트 평균 초기 크기 | {size_mean:.0f}명 (min={size_min:.0f}, max={size_max:.0f}) |
| 분석 기간 | {df[COHORT_COL].min().date()} ~ {df[ACTIVITY_COL].max().date()} |

---

## 2. 핵심 유지율 지표

| 기간 | 평균 유지율 | 평가 |
|------|------------|------|
{kpi_table}

*(🟢 ≥ 40% 우수 / 🟡 20-40% 보통 / 🔴 < 20% 개선 필요)*

---

## 3. 코호트 비교

"""

if len(benchmark_col) >= 3:
    top_cohort    = str(top3.index[0])
    top_val       = top3.iloc[0]
    bottom_cohort = str(bottom3.index[0])
    bottom_val    = bottom3.iloc[0]
    report += f"""- 최고 성과 코호트: **{top_cohort}** ({benchmark_period} 유지율 {top_val:.1f}%)
- 최저 성과 코호트: **{bottom_cohort}** ({benchmark_period} 유지율 {bottom_val:.1f}%)
- 코호트 간 최대 차이: **{gap:.1f}%p**

"""

report += f"""---

## 4. 주요 인사이트

"""

# 동적 인사이트
if r1 is not None:
    if r1 < 30:
        report += f"- ⚠️ 1{unit_label} 유지율이 {r1:.1f}%로 낮습니다. 온보딩 프로세스 개선이 필요합니다.\n"
    else:
        report += f"- ✅ 1{unit_label} 유지율 {r1:.1f}% — 초기 사용자 경험이 양호합니다.\n"

if r3 is not None and r1 is not None:
    drop_rate = r1 - r3
    if drop_rate > 20:
        report += f"- ⚠️ 1{unit_label}→3{unit_label} 사이 이탈이 {drop_rate:.1f}%p로 급격합니다. 이 구간 이탈 원인 분석 권장.\n"
    else:
        report += f"- ✅ 1{unit_label}→3{unit_label} 이탈율 {drop_rate:.1f}%p — 안정적입니다.\n"

report += f"""
---

## 5. 도메인 노트

{domain_txt}

---

## 6. 권장 다음 단계

- 이탈 원인 분석 → **root-cause-investigation** 스킬 사용
- A/B 테스트 설계 → **ab-test-analysis** 스킬 사용
- 세그먼트별 분석 → **segmentation-analysis** 스킬 사용
- 임원 보고 → **executive-summary-generator** 스킬 사용

---
*생성: DA Skills Plugin — cohort-analysis*
"""

with open("cohort-analysis_report.md", "w", encoding="utf-8") as f:
    f.write(report)
print("✅ cohort-analysis_report.md 저장됨")
print(f"\n🎉 코호트 분석 완료!")
print(f"   생성 파일: cohort-analysis_result.csv, cohort-analysis_report.md")
print(f"   차트: cohort_heatmap.png, cohort_sizes.png, cohort_retention_trend.png")
```

---

## 출력 템플릿

**세 가지 주요 출력을 생성합니다:**

① `cohort-analysis_result.csv` — 코호트 × 기간별 유지율 매트릭스 (코호트 크기 포함)
② `cohort-analysis_report.md` — 핵심 유지율 지표·코호트 비교·인사이트·권장 다음 단계 한국어 리포트
③ `cohort-analysis.ipynb` — 위 셀 전체를 포함한 실행 가능 노트북
④ 차트 PNG 파일 — `cohort_heatmap.png`, `cohort_sizes.png`, `cohort_retention_trend.png`, `cohort_size_vs_retention.png`

---

## 다른 스킬과의 연결

| 방향 | 스킬 | 연결 방법 |
|------|------|-----------|
| 이전 | programmatic-eda | 데이터 품질 확인 후 코호트 분석 |
| 이전 | context-packager | `context_packet.json` 자동 읽기 |
| 다음 | ab-test-analysis | 코호트 성과 차이 통계 검정 |
| 다음 | root-cause-investigation | 이탈 급증 구간 원인 분석 |
| 다음 | segmentation-analysis | 코호트 특성별 세그먼트 비교 |
| 다음 | executive-summary-generator | 경영진 보고용 요약 생성 |
