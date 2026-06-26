---
name: data-quality-audit
description: 정의된 비즈니스 규칙 및 제약 조건에 대한 포괄적인 데이터 품질 평가. 데이터를 예상 스키마와 검증하거나, 테이블 전체에서 참조 무결성을 확인하거나, 프로덕션 사용 전에 데이터 파이프라인 출력을 감사할 때 사용하세요. | Comprehensive data quality assessment against defined business rules and constraints. Use when validating data against expected schemas, checking referential integrity across tables, or auditing data pipeline outputs before production use.
---

# Data Quality Audit

## Phase
Phase 2 — 데이터 이해 (programmatic-eda 다음 단계)

## Input
- 이전 스킬: programmatic-eda
- 받는 파일: 원본 데이터 + `programmatic-eda_result.csv` (선택)
- `context_packet.json` (존재하면 자동 읽기)

## Output
- `data-quality-audit.ipynb` — 실행 결과 내장 노트북
- `data-quality-audit_result.csv` — 규칙별 위반 건수·비율 테이블
- `data-quality-audit_report.md` — 한국어 품질 감사 리포트

---

## 2단계 실행 구조

| 단계 | 언제 | 무엇을 |
|------|------|--------|
| **1단계 (최초 1회)** | 데이터를 처음 받을 때 | Claude가 대화로 비즈니스 규칙 파악 → Config Block 초안 제안 |
| **2단계 (매 실행)** | 노트북 실행할 때마다 | Config Block 상단 값만 수정 → 나머지는 자동 |

---

## 셀 1: Config Block

```python
# =====================================================================
# CONFIG BLOCK — 이 셀만 수정하세요
# =====================================================================
DATA_PATH       = "데이터_파일_경로.csv"  # ← 매 실행마다 변경

# 필수 컬럼 (없으면 즉시 오류)
REQUIRED_COLS   = []          # 예: ["user_id", "created_at", "amount"]

# 고유 키 컬럼 (중복 허용 안 됨)
UNIQUE_KEY_COLS = []          # 예: ["order_id"] or ["user_id", "date"]

# 타겟/핵심 컬럼 (결측 0 강제)
TARGET_COL      = None        # 예: "churn"

# 비즈니스 규칙 딕셔너리
# 형식: { "컬럼명": { "type": 규칙유형, ...파라미터 } }
#
# 지원 규칙 유형:
#   range      → {"min": 0, "max": 120}              숫자 범위
#   not_null   → {}                                   결측 불허
#   positive   → {}                                   양수만 허용
#   allowed    → {"values": ["A", "B", "C"]}          허용값 목록
#   date_order → {"before": "end_date"}               날짜 선후 관계
#   regex      → {"pattern": r"^\d{3}-\d{4}-\d{4}$"} 정규식 패턴
BUSINESS_RULES  = {}
# 예시:
# BUSINESS_RULES = {
#     "age":          {"type": "range",    "min": 0,   "max": 120},
#     "price":        {"type": "positive"},
#     "status":       {"type": "allowed",  "values": ["active", "inactive", "pending"]},
#     "signup_date":  {"type": "date_order", "before": "last_login_date"},
#     "phone":        {"type": "regex",    "pattern": r"^\d{2,3}-\d{3,4}-\d{4}$"},
#     "revenue":      {"type": "not_null"},
# }

DOMAIN_NOTES    = []          # 예: ["NULL은 미가입 의미", "amount 단위: 원"]
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
import os, json, re, warnings
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
def check_schema_drift(df, baseline_path="data-quality-audit_baseline_schema.json"):
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
def load_audit_hints():
    hints = {"domain_notes": DOMAIN_NOTES}
    if os.path.exists("context_packet.json"):
        with open("context_packet.json", "r", encoding="utf-8") as f:
            pkt = json.load(f)
        hints["domain_notes"]   = pkt.get("domain_notes", DOMAIN_NOTES)
        hints["meaningful_missing"] = pkt.get("meaningful_missing", {})
        print(f"📦 context_packet 로드됨")
    return hints

df    = load_data(DATA_PATH)
hints = load_audit_hints()
check_schema_drift(df)

if hints["domain_notes"]:
    print("\n📋 도메인 노트:")
    for note in hints["domain_notes"]: print(f"   • {note}")

print(f"\n✅ 데이터 로드 완료: {df.shape[0]:,}행 × {df.shape[1]}열")
```

---

## 셀 3: 스키마 검증 (필수 컬럼 존재 여부)

```python
print("=" * 60)
print("1단계: 스키마 검증")
print("=" * 60)

schema_issues = []

# 필수 컬럼 존재 확인
if REQUIRED_COLS:
    missing_cols = [c for c in REQUIRED_COLS if c not in df.columns]
    present_cols = [c for c in REQUIRED_COLS if c in df.columns]
    print(f"필수 컬럼 확인: {len(present_cols)}/{len(REQUIRED_COLS)}개 존재")
    if missing_cols:
        print(f"❌ 누락된 필수 컬럼: {missing_cols}")
        schema_issues.append(f"필수 컬럼 누락: {missing_cols}")
    else:
        print("✅ 모든 필수 컬럼 존재")
else:
    print("ℹ️  REQUIRED_COLS 미설정 — 필수 컬럼 검사 생략")

# 전체 컬럼 목록
print(f"\n전체 컬럼 ({df.shape[1]}개):")
for col in df.columns:
    flag = "✅" if col not in (REQUIRED_COLS or []) else "📌"
    print(f"   {flag} {col:<30} {str(df[col].dtype)}")

# 타겟 컬럼 확인
if TARGET_COL:
    if TARGET_COL not in df.columns:
        print(f"\n❌ TARGET_COL '{TARGET_COL}' 이 데이터에 없습니다!")
        schema_issues.append(f"TARGET_COL '{TARGET_COL}' 없음")
    else:
        t_null = df[TARGET_COL].isna().sum()
        if t_null > 0:
            print(f"\n⚠️  TARGET_COL '{TARGET_COL}': 결측 {t_null}개 → 즉시 조치 필요")
            schema_issues.append(f"TARGET_COL 결측 {t_null}개")
        else:
            print(f"\n✅ TARGET_COL '{TARGET_COL}': 결측 없음")
```

---

## 셀 4: 고유 키 중복 검사

```python
print("=" * 60)
print("2단계: 고유 키 중복 검사")
print("=" * 60)

key_issues = []

# 완전 행 중복
full_dup = df.duplicated().sum()
dup_rate = full_dup / len(df) * 100
status = "⚠️" if full_dup > 0 else "✅"
print(f"{status} 완전 행 중복: {full_dup:,}개 ({dup_rate:.3f}%)")
if full_dup > 0:
    key_issues.append(f"완전 행 중복 {full_dup}개")

# 고유 키 컬럼 중복
if UNIQUE_KEY_COLS:
    valid_key_cols = [c for c in UNIQUE_KEY_COLS if c in df.columns]
    if len(valid_key_cols) < len(UNIQUE_KEY_COLS):
        missing_key = set(UNIQUE_KEY_COLS) - set(valid_key_cols)
        print(f"⚠️  UNIQUE_KEY_COLS 중 없는 컬럼: {missing_key}")

    if valid_key_cols:
        key_dup = df.duplicated(subset=valid_key_cols).sum()
        key_rate = key_dup / len(df) * 100
        status = "⚠️" if key_dup > 0 else "✅"
        print(f"{status} 키 중복 ({valid_key_cols}): {key_dup:,}개 ({key_rate:.3f}%)")

        if key_dup > 0:
            key_issues.append(f"키 중복 {key_dup}개 ({valid_key_cols})")
            print("\n중복 키 샘플 (상위 10행):")
            dup_mask = df.duplicated(subset=valid_key_cols, keep=False)
            print(df[dup_mask].sort_values(valid_key_cols).head(10).to_string())
else:
    print("ℹ️  UNIQUE_KEY_COLS 미설정 — 고유 키 검사 생략")

if not key_issues:
    print("\n✅ 중복 이슈 없음")
```

---

## 셀 5: 결측값 감사

```python
print("=" * 60)
print("3단계: 결측값 감사")
print("=" * 60)

missing_issues = []
mm = hints.get("meaningful_missing", {})

missing_df = pd.DataFrame({
    "컬럼":       df.columns,
    "결측수":     df.isna().sum().values,
    "결측율(%)":  (df.isna().mean() * 100).round(3).values,
    "dtype":      df.dtypes.astype(str).values,
}).sort_values("결측율(%)", ascending=False)

missing_df["판정"] = missing_df.apply(
    lambda r: "✅ 의미있는 결측" if r["컬럼"] in mm
    else ("🔴 심각" if r["결측율(%)"] > 30
    else ("🟡 주의" if r["결측율(%)"] > 5
    else ("⚪ 없음" if r["결측율(%)"] == 0 else "🟢 양호"))),
    axis=1
)

print(missing_df.to_string(index=False))

critical = missing_df[
    (missing_df["결측율(%)"] > 30) &
    (~missing_df["컬럼"].isin(mm))
]["컬럼"].tolist()

caution = missing_df[
    (missing_df["결측율(%)"].between(5, 30)) &
    (~missing_df["컬럼"].isin(mm))
]["컬럼"].tolist()

if critical:
    print(f"\n🔴 심각 결측 컬럼 (>30%): {critical}")
    missing_issues.append(f"심각 결측 컬럼: {critical}")
if caution:
    print(f"🟡 주의 결측 컬럼 (5~30%): {caution}")
    missing_issues.append(f"주의 결측 컬럼: {caution}")
if mm:
    print(f"✅ 의미있는 결측 컬럼 (감사 제외): {list(mm.keys())}")
if not critical and not caution:
    print("\n✅ 모든 컬럼 결측 이슈 없음 (의미있는 결측 제외)")
```

---

## 셀 6: 비즈니스 규칙 적용

```python
print("=" * 60)
print("4단계: 비즈니스 규칙 검증")
print("=" * 60)

rule_results = []

if not BUSINESS_RULES:
    print("ℹ️  BUSINESS_RULES 미설정 — 비즈니스 규칙 검사 생략")
    print("   Config Block의 BUSINESS_RULES 딕셔너리에 규칙을 추가하세요.")
else:
    for col, rule in BUSINESS_RULES.items():
        if col not in df.columns:
            rule_results.append({
                "컬럼": col, "규칙": rule.get("type","?"),
                "위반수": "N/A", "위반율(%)": "N/A",
                "상태": "⚠️ 컬럼 없음"
            })
            continue

        s        = df[col]
        rtype    = rule.get("type", "")
        n_total  = len(s)
        violated = pd.Series([False] * n_total, index=s.index)

        try:
            if rtype == "range":
                mn, mx    = rule.get("min"), rule.get("max")
                s_num     = pd.to_numeric(s, errors="coerce")
                violated  = s_num.notna() & ((s_num < mn) | (s_num > mx))
                rule_desc = f"range [{mn}, {mx}]"

            elif rtype == "not_null":
                violated  = s.isna()
                rule_desc = "not_null"

            elif rtype == "positive":
                s_num     = pd.to_numeric(s, errors="coerce")
                violated  = s_num.notna() & (s_num <= 0)
                rule_desc = "positive (>0)"

            elif rtype == "allowed":
                allowed   = rule.get("values", [])
                violated  = s.notna() & (~s.isin(allowed))
                rule_desc = f"allowed={allowed}"

            elif rtype == "date_order":
                before_col = rule.get("before")
                if before_col in df.columns:
                    d1        = pd.to_datetime(s, errors="coerce")
                    d2        = pd.to_datetime(df[before_col], errors="coerce")
                    violated  = d1.notna() & d2.notna() & (d1 > d2)
                    rule_desc = f"≤ {before_col}"
                else:
                    rule_desc = f"date_order → '{before_col}' 없음"
                    violated  = pd.Series([False] * n_total)

            elif rtype == "regex":
                pattern   = rule.get("pattern", "")
                violated  = s.notna() & (~s.astype(str).str.match(pattern))
                rule_desc = f"regex={pattern}"

            else:
                rule_desc = f"알 수 없는 규칙: {rtype}"

        except Exception as e:
            rule_desc = str(e)
            violated  = pd.Series([False] * n_total)

        n_viol   = int(violated.sum())
        viol_rt  = round(n_viol / n_total * 100, 3)
        status   = "🔴 위반" if n_viol > 0 else "✅ 통과"

        rule_results.append({
            "컬럼":     col,
            "규칙":     rule_desc,
            "위반수":   n_viol,
            "위반율(%)": viol_rt,
            "상태":     status
        })

        if n_viol > 0 and n_viol <= 5:
            print(f"\n🔴 '{col}' ({rule_desc}) 위반 샘플:")
            print(df.loc[violated, [col]].head(5).to_string())

    rule_df = pd.DataFrame(rule_results)
    print("\n비즈니스 규칙 검증 결과:")
    print(rule_df.to_string(index=False))

    fail_rules = rule_df[rule_df["상태"] == "🔴 위반"]
    if len(fail_rules) > 0:
        print(f"\n🔴 위반 규칙: {len(fail_rules)}개 / {len(rule_results)}개")
    else:
        print(f"\n✅ 모든 비즈니스 규칙 통과 ({len(rule_results)}개)")
```

---

## 셀 7: 품질 점수 계산 및 시각화

```python
print("=" * 60)
print("5단계: 종합 품질 점수")
print("=" * 60)

# 품질 점수 계산 (100점 만점)
# 각 항목별 감점 방식
score = 100.0
score_detail = []

# 1) 완전 중복
dup_rate = df.duplicated().sum() / len(df) * 100
dup_penalty = min(20, dup_rate * 2)
score -= dup_penalty
score_detail.append(f"중복 감점: -{dup_penalty:.1f} (중복율 {dup_rate:.2f}%)")

# 2) 결측값 (심각 컬럼 수 기반)
mm_keys = set(hints.get("meaningful_missing", {}).keys())
missing_rates = df.isna().mean() * 100
severe_miss = (missing_rates > 30).sum() - sum(c in mm_keys for c in df.columns if missing_rates[c] > 30)
mild_miss   = ((missing_rates > 5) & (missing_rates <= 30)).sum()
miss_penalty = min(30, severe_miss * 10 + mild_miss * 2)
score -= miss_penalty
score_detail.append(f"결측 감점: -{miss_penalty:.1f} (심각 {severe_miss}개, 주의 {mild_miss}개)")

# 3) 비즈니스 규칙 위반
if BUSINESS_RULES and rule_results:
    n_rules   = len(rule_results)
    n_failed  = sum(1 for r in rule_results if str(r["위반수"]) not in ("0", "N/A") and r["위반수"] > 0)
    rule_penalty = min(30, n_failed / max(n_rules, 1) * 30)
    score -= rule_penalty
    score_detail.append(f"규칙 감점: -{rule_penalty:.1f} ({n_failed}/{n_rules} 위반)")
else:
    score_detail.append("규칙 감점: 0 (규칙 미설정)")

# 4) 키 중복
if UNIQUE_KEY_COLS:
    valid_key_cols = [c for c in UNIQUE_KEY_COLS if c in df.columns]
    if valid_key_cols:
        key_dup = df.duplicated(subset=valid_key_cols).sum()
        key_penalty = min(20, key_dup / len(df) * 100 * 2)
        score -= key_penalty
        score_detail.append(f"키 중복 감점: -{key_penalty:.1f} ({key_dup}개)")
    else:
        score_detail.append("키 중복 감점: 0 (유효한 키 컬럼 없음)")

score = max(0, round(score, 1))

# 등급 결정
if score >= 90:    grade = "A (우수)"
elif score >= 75:  grade = "B (양호)"
elif score >= 60:  grade = "C (보통)"
elif score >= 40:  grade = "D (주의)"
else:              grade = "F (위험)"

print(f"\n🏆 종합 품질 점수: {score}/100 — 등급: {grade}")
print("\n감점 내역:")
for d in score_detail:
    print(f"   • {d}")

# 시각화
fig, axes = plt.subplots(1, 2, figsize=(12, 5))

# 품질 점수 게이지 (막대)
ax = axes[0]
color = "green" if score >= 75 else "orange" if score >= 60 else "red"
ax.barh(["품질 점수"], [score], color=color, alpha=0.7)
ax.barh(["품질 점수"], [100 - score], left=[score], color="lightgray", alpha=0.5)
ax.set_xlim(0, 100)
ax.axvline(75, color="green",  linestyle="--", alpha=0.5, label="양호 기준(75)")
ax.axvline(60, color="orange", linestyle="--", alpha=0.5, label="보통 기준(60)")
ax.set_title(f"종합 품질 점수: {score}/100 ({grade})")
ax.legend(fontsize=8)
ax.text(score / 2, 0, f"{score}점", ha="center", va="center", fontsize=14, fontweight="bold")

# 항목별 결측율 상위 10
ax2 = axes[1]
miss_top = (df.isna().mean() * 100).sort_values(ascending=False).head(10)
if miss_top.max() > 0:
    colors = ["red" if v > 30 else "orange" if v > 5 else "steelblue"
              for v in miss_top.values]
    miss_top.plot(kind="barh", ax=ax2, color=colors[::-1], alpha=0.8)
    ax2.invert_yaxis()
    ax2.set_xlabel("결측율 (%)")
    ax2.set_title("컬럼별 결측율 (상위 10)")
else:
    ax2.text(0.5, 0.5, "결측값 없음 ✅",
             transform=ax2.transAxes, ha="center", va="center", fontsize=14)
    ax2.set_title("결측율 분포")

plt.tight_layout()
plt.savefig("dqa_summary_chart.png", dpi=100, bbox_inches="tight")
print("\n📊 품질 요약 차트 저장됨 → dqa_summary_chart.png")
plt.close()
```

---

## 셀 8: 결과 저장 및 리포트 생성

```python
print("=" * 60)
print("6단계: 결과 저장 및 리포트 생성")
print("=" * 60)

# ── result.csv ───────────────────────────────────────────────────────
result_rows = []
for col in df.columns:
    s         = df[col]
    n_miss    = s.isna().sum()
    miss_rt   = round(n_miss / len(df) * 100, 3)
    is_mm     = col in hints.get("meaningful_missing", {})

    # 해당 컬럼에 적용된 규칙 결과 찾기
    rule_row = next((r for r in rule_results if r["컬럼"] == col), {}) \
               if BUSINESS_RULES and "rule_results" in dir() else {}

    result_rows.append({
        "컬럼":        col,
        "dtype":       str(s.dtype),
        "결측수":      n_miss,
        "결측율(%)":   miss_rt,
        "의미있는결측": is_mm,
        "결측판정":    ("의미있는 결측" if is_mm
                        else "심각" if miss_rt > 30
                        else "주의" if miss_rt > 5
                        else "양호"),
        "규칙유형":    rule_row.get("규칙", "-"),
        "규칙위반수":  rule_row.get("위반수", "-"),
        "규칙상태":    rule_row.get("상태", "-"),
    })

result_df = pd.DataFrame(result_rows)
result_df.to_csv("data-quality-audit_result.csv", index=False, encoding="utf-8-sig")
print("✅ data-quality-audit_result.csv 저장됨")

# ── report.md ────────────────────────────────────────────────────────
now = datetime.now().strftime("%Y-%m-%d %H:%M")

miss_summary = "\n".join(
    f"| {r['컬럼']} | {r['결측율(%)']}% | {r['결측판정']} |"
    for r in result_rows
    if r["결측율(%)"] > 0
) or "| (결측값 없음) | - | - |"

rule_summary = ""
if BUSINESS_RULES and "rule_results" in dir():
    rule_summary = "\n".join(
        f"| {r['컬럼']} | {r['규칙']} | {r['위반수']} | {r['상태']} |"
        for r in rule_results
    )
else:
    rule_summary = "| (규칙 미설정) | - | - | - |"

domain_txt = "\n".join(f"- {n}" for n in hints["domain_notes"]) \
             if hints["domain_notes"] else "- (없음)"

report = f"""# Data Quality Audit 리포트
생성일시: {now}
데이터: {DATA_PATH}

---

## 1. 감사 개요

| 항목 | 값 |
|------|----|
| 행 수 | {len(df):,} |
| 컬럼 수 | {df.shape[1]} |
| 완전 중복 행 | {df.duplicated().sum():,}개 |
| 종합 품질 점수 | {score}/100 ({grade}) |
| 적용 비즈니스 규칙 | {len(BUSINESS_RULES)}개 |

---

## 2. 결측값 감사

| 컬럼 | 결측율 | 판정 |
|------|--------|------|
{miss_summary}

---

## 3. 비즈니스 규칙 검증

| 컬럼 | 규칙 | 위반수 | 상태 |
|------|------|--------|------|
{rule_summary}

---

## 4. 종합 품질 점수 상세

{chr(10).join("- " + d for d in score_detail)}

---

## 5. 도메인 노트

{domain_txt}

---

## 6. 권장 조치

"""

# 동적 권장사항
if score < 60:
    report += "⛔ 즉각적인 데이터 정제 필요 — 분석 또는 모델링 전 반드시 처리하세요.\n\n"
elif score < 75:
    report += "⚠️ 데이터 품질 개선 권장 — 주요 이슈를 처리 후 분석을 진행하세요.\n\n"
else:
    report += "✅ 데이터 품질 양호 — 분석/모델링 진행 가능합니다.\n\n"

report += """- 결측값 처리 → **data-preprocessing** 스킬 사용
- 추가 탐색 → **programmatic-eda** 스킬 사용
- 분석 진행 → **stats-basic** 또는 **ml-supervised** 스킬 사용

---
*생성: DA Skills Plugin — data-quality-audit*
"""

with open("data-quality-audit_report.md", "w", encoding="utf-8") as f:
    f.write(report)
print("✅ data-quality-audit_report.md 저장됨")
print(f"\n🎉 Data Quality Audit 완료! 종합 점수: {score}/100 ({grade})")
```

---

## 출력 템플릿

**세 가지 주요 출력을 생성합니다:**

① `data-quality-audit_result.csv` — 컬럼별 결측율·규칙위반 여부 테이블
② `data-quality-audit_report.md` — 품질 점수·감점 내역·권장 조치 한국어 리포트
③ `data-quality-audit.ipynb` — 위 셀 전체를 포함한 실행 가능 노트북
④ `dqa_summary_chart.png` — 품질 점수 게이지 + 결측율 분포 차트

---

## 다른 스킬과의 연결

| 방향 | 스킬 | 연결 방법 |
|------|------|-----------|
| 이전 | programmatic-eda | `programmatic-eda_result.csv` 참고 |
| 이전 | context-packager | `context_packet.json` 자동 읽기 |
| 다음 | data-preprocessing | 결측·이상치 처리 방향 전달 |
| 다음 | analysis-assumptions-log | 품질 이슈 가정 기록 |
