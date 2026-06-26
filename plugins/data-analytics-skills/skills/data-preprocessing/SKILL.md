---
name: data-preprocessing
description: |
  결측값 처리·이상치 제거·인코딩·스케일링 등 분석 전 데이터 정제 스킬.
  데이터 품질 감사(data-quality-audit) 이후, ML·통계 분석 전 단계로 사용합니다.
  통계 기반으로 처리 방법을 자동 제안하고 사용자가 비즈니스 맥락으로 확정합니다.

  다음 상황에서 반드시 이 스킬을 사용하세요:
  - "결측값을 어떻게 처리해야 할지 모르겠어"
  - "이상치가 있는데 제거해야 할까?"
  - "범주형 컬럼을 숫자로 바꿔야 해" (Label Encoding, One-Hot Encoding)
  - "ML 모델에 넣기 전에 정규화/표준화 해야 해"
  - "data-quality-audit 이후 다음 단계가 뭔지 모르겠어"
  - "전처리 코드를 Jupyter Notebook으로 만들어줘"
---

# 데이터 전처리 스킬

데이터 품질 감사 결과를 바탕으로, 분석/ML에 바로 사용할 수 있는 깨끗한 데이터셋을 만듭니다.
출력물은 `data-preprocessing.ipynb`(실행결과 내장) + `data-preprocessing_result.csv`(전처리 완료 데이터) + `data-preprocessing_report.md`(처리 내역 및 근거 보고서)입니다.

## Phase
Phase 3.5 — 데이터 전처리 (data-quality-audit 이후, stats-basic / ml-supervised / ml-unsupervised 이전)

## Input
- 이전 스킬: data-quality-audit (또는 programmatic-eda)
- 받는 파일: 원본 데이터 파일 (CSV·Excel·JSON·Parquet·TSV 등)
- 선택: `data-quality-audit_result.csv` (품질 감사 결과)

## Output
- `data-preprocessing.ipynb` — 전처리 전 과정 코드 (실행결과 내장)
- `data-preprocessing_result.csv` — 전처리 완료 데이터셋
- `data-preprocessing_report.md` — 처리 항목, 선택 근거, 전후 비교 통계

---

## 빠른 시작

전처리는 "무조건 결측값을 채우고 이상치를 제거"하는 것이 아닙니다.
**데이터를 이해한 뒤, 분석 목적에 맞는 처리 방법을 선택**하는 과정입니다.
AI가 통계적 근거로 방법을 제안하고, 사용자가 비즈니스 맥락에서 최종 결정합니다.

---

## 필요한 컨텍스트

1. **데이터 파일**: 전처리할 파일 경로 또는 업로드
2. **분석 목적**: 이후 어떤 분석을 할 것인지 (통계 검정, 회귀, 분류 등)
3. **타깃 컬럼** (선택): 예측하거나 분석할 대상 컬럼
4. **도메인 제약** (선택): "이 컬럼의 결측은 0으로 채워야 해" 같은 비즈니스 규칙

---

## 컨텍스트 수집

### 데이터가 제공된 경우:
먼저 데이터를 로드하고 품질 현황을 빠르게 파악합니다.

```python
import pandas as pd
import numpy as np

def load_file(path):
    """다양한 확장자 자동 로드"""
    ext = path.split('.')[-1].lower()
    try:
        if ext == 'csv':
            try:
                return pd.read_csv(path, encoding='utf-8')
            except UnicodeDecodeError:
                return pd.read_csv(path, encoding='cp949')
        elif ext == 'tsv':
            try:
                return pd.read_csv(path, sep='\t', encoding='utf-8')
            except UnicodeDecodeError:
                return pd.read_csv(path, sep='\t', encoding='cp949')
        elif ext in ['xlsx', 'xls']:
            return pd.read_excel(path)
        elif ext == 'json':
            return pd.read_json(path)
        elif ext == 'parquet':
            return pd.read_parquet(path)
        else:
            raise ValueError(f"지원하지 않는 확장자: {ext}")
    except Exception as e:
        raise RuntimeError(f"파일 로드 실패: {e}")

df = load_file("데이터_파일_경로")
print(f"행: {df.shape[0]:,}  컬럼: {df.shape[1]}")
print(f"\n결측값 현황:\n{df.isnull().sum()[df.isnull().sum() > 0]}")
print(f"\n데이터 타입:\n{df.dtypes}")
```

### 분석 목적이 불명확한 경우:
"다음을 알려주세요:
1. 이후 어떤 분석을 할 예정인가요? (예: 분류 모델, 회귀 분석, 시각화, 통계 검정)
2. 예측/분석하려는 타깃 컬럼이 있나요?
3. 특정 컬럼에 대해 알고 있는 비즈니스 규칙이 있나요?
   (예: 'age' 컬럼이 0이면 데이터 오류, 'revenue'가 음수면 환불)"

---

## 컨텍스트 패킷 기반 전처리 전략 결정

`context_packet.json`이 있으면 자동으로 읽어 전처리 전략을 설정합니다.
패킷이 없으면 기본값으로 진행하고 사용자에게 추가 질문합니다.

```python
import json
import os

def load_preprocessing_strategy(packet_path="context_packet.json"):
    """
    context_packet.json을 읽어 전처리 전략 플래그를 결정합니다.
    반환값: strategy dict
    """
    defaults = {
        "use_interpolation": False,      # 시간 보간 사용 여부
        "skip_encoding_scaling": False,  # 통계 검정 목적이면 인코딩·스케일링 불필요
        "protect_target_col": None,      # 스케일링에서 제외할 타깃 컬럼
        "time_col": None,                # 날짜 컬럼명 (시계열 전처리용)
        "time_interval": "없음",         # 시간 간격 (보간 방법 결정)
        "domain_notes": [],              # 비즈니스 규칙 (이상치 처리 참고)
        "packet_loaded": False
    }

    if not os.path.exists(packet_path):
        print("⚠️  context_packet.json 없음 — 기본 전략으로 진행합니다.")
        print("   더 정확한 전처리를 위해 analysis-path-guide → context-packager 실행을 권장합니다.")
        return defaults

    with open(packet_path, "r", encoding="utf-8") as f:
        packet = json.load(f)

    strategy = defaults.copy()
    strategy["packet_loaded"] = True

    table_type     = packet.get("table_type", "")
    time_col_role  = packet.get("time_column_role", "없음")
    time_interval  = packet.get("time_interval", "없음")
    analysis_purpose = packet.get("analysis_purpose", "")

    # ── 보간 전략 결정 ────────────────────────────────────────────
    # 시간 보간은 '시계열_집계 + 인덱스 역할 + 규칙적 간격'일 때만 유효
    is_ts_aggregate = "시계열" in str(table_type)
    is_index_role   = time_col_role in ["인덱스", "인덱스_후보"]
    is_regular      = time_interval not in ["불규칙", "없음"]

    strategy["use_interpolation"] = is_ts_aggregate and is_index_role and is_regular
    strategy["time_col"]          = packet.get("time_column_name")
    strategy["time_interval"]     = time_interval

    # ── 인코딩·스케일링 스킵 결정 ─────────────────────────────────
    # 통계 검정(원인분석, AB검정)은 인코딩·스케일링이 해석을 왜곡할 수 있음
    stats_purposes = ["원인분석", "AB검정"]
    strategy["skip_encoding_scaling"] = any(p in str(analysis_purpose) for p in stats_purposes)

    # ── 타깃 컬럼 보호 ───────────────────────────────────────────
    strategy["protect_target_col"] = packet.get("target_col")

    # ── 도메인 노트 ──────────────────────────────────────────────
    strategy["domain_notes"] = packet.get("domain_notes", [])

    return strategy

# ── 전략 로드 및 출력 ──────────────────────────────────────────────
strategy = load_preprocessing_strategy()

if strategy["packet_loaded"]:
    print("📦 context_packet.json 로드 완료 — 전처리 전략 자동 설정됨\n")
    print(f"  🔁 시간 보간 사용:         {'✅ 사용' if strategy['use_interpolation'] else '❌ 미사용'}")
    if strategy["use_interpolation"]:
        print(f"     → 날짜 컬럼: '{strategy['time_col']}', 간격: {strategy['time_interval']}")
    else:
        if strategy["time_col"]:
            print(f"     → 날짜 컬럼 있음 ({strategy['time_col']}) 이지만 "
                  f"table_type/time_interval 조건 미충족 → 일반 결측 처리 적용")
    print(f"  🔢 인코딩·스케일링 적용:   {'❌ 스킵 (통계 검정 목적)' if strategy['skip_encoding_scaling'] else '✅ 적용'}")
    print(f"  🎯 타깃 컬럼 보호:         {strategy['protect_target_col'] or '없음 (미지정)'}")
    if strategy["domain_notes"]:
        print(f"\n  📋 도메인 노트 (이상치·결측 처리 시 참고):")
        for note in strategy["domain_notes"]:
            print(f"     • {note}")
    print()
```

> **⚠️ 보간(interpolation) 사용 조건**
> 시간 보간은 `시계열_집계` 테이블에서 날짜 인덱스 사이에 누락된 집계값을 채울 때만 유효합니다.
> 독립 관측값(고객별 회원 정보, 개별 거래 로그 등)에 시간 보간을 적용하면 존재하지 않는 행을 만들어냅니다.
> `context_packet.json`의 `table_type`이 `시계열_집계`이고 `time_column_role`이 `인덱스`일 때만 자동으로 활성화됩니다.

---

## 워크플로우

### Step 0: 의미 있는 결측 선언 (MEANINGFUL_MISSING)

> **이 단계가 가장 먼저 실행되어야 합니다.**
> 통계적 결측값 처리(1단계 이후)를 적용하기 전에, **결측 자체가 정보인 컬럼**을 먼저 식별하고 처리 전략을 선언합니다.
> 선언된 컬럼은 이후 통계 기반 처리 단계에서 **자동으로 제외**됩니다.

**결측이 의미를 갖는 전형적인 사례:**
- `exam_score` NaN → 시험 미응시 (0점이 아님, '없음'과 다름)
- `coupon_discount` NaN → 쿠폰 미사용 (= 0으로 처리 가능)
- `last_purchase_date` NaN → 한 번도 구매 안 함 (별도 범주 필요)
- `survey_response` NaN → 설문 미참여 (플래그 처리)
- `penalty_fee` NaN → 위반 없음 (= 0으로 처리)

```python
import pandas as pd
import numpy as np
import json
import os

def load_file(path):
    """다양한 확장자 자동 로드"""
    ext = path.split('.')[-1].lower()
    try:
        if ext == 'csv':
            try:
                return pd.read_csv(path, encoding='utf-8')
            except UnicodeDecodeError:
                return pd.read_csv(path, encoding='cp949')
        elif ext == 'tsv':
            try:
                return pd.read_csv(path, sep='\t', encoding='utf-8')
            except UnicodeDecodeError:
                return pd.read_csv(path, sep='\t', encoding='cp949')
        elif ext in ['xlsx', 'xls']:
            return pd.read_excel(path)
        elif ext == 'json':
            return pd.read_json(path)
        elif ext == 'parquet':
            return pd.read_parquet(path)
    except Exception as e:
        raise RuntimeError(f"파일 로드 실패: {e}")

# ── context_packet.json에서 의미 있는 결측 선언 자동 로드 ──────────────
def load_meaningful_missing_from_packet(packet_path="context_packet.json"):
    """컨텍스트 패킷에서 사전 선언된 meaningful_missing 로드"""
    if os.path.exists(packet_path):
        with open(packet_path, "r", encoding="utf-8") as f:
            packet = json.load(f)
        declarations = packet.get("meaningful_missing", [])
        if declarations:
            print(f"📦 context_packet.json에서 {len(declarations)}건의 의미 있는 결측 선언 로드됨:")
            for d in declarations:
                print(f"   {d['col']} → strategy: {d['strategy']}")
        return declarations
    return []

# ── AI 자동 탐지 (후보 제안) ──────────────────────────────────────────
def detect_meaningful_missing_candidates(df):
    """
    결측값이 있으면서 '의미 있는 결측' 가능성이 높은 컬럼을 탐지합니다.
    이 결과는 사용자 확인 전 후보일 뿐입니다.
    """
    semantic_keywords = [
        'score', 'exam', 'test', 'quiz',           # 시험/평가
        'survey', 'response', 'answer', 'feedback', # 설문
        'purchase', 'payment', 'order', 'buy',       # 구매
        'coupon', 'discount', 'promo',               # 프로모션
        'visit', 'login', 'session', 'click',        # 활동
        'fee', 'penalty', 'fine', 'charge',          # 비용/위반
        'point', 'reward', 'bonus'                   # 포인트
    ]
    candidates = []
    for col in df.columns:
        missing_cnt = df[col].isnull().sum()
        if missing_cnt == 0:
            continue
        col_lower = col.lower()
        matched_kw = next((kw for kw in semantic_keywords if kw in col_lower), None)
        if matched_kw:
            candidates.append({
                'col': col,
                'missing_pct': round(df[col].isnull().mean() * 100, 2),
                'dtype': str(df[col].dtype),
                'reason': f"키워드 '{matched_kw}' 감지 — 결측이 '미응시/미참여/해당없음'일 수 있음",
                'suggested_strategy': 'flag' if df[col].dtype in ['float64', 'int64'] else 'category'
            })
    return candidates

# ── 선언 적용 함수 ──────────────────────────────────────────────────
def apply_meaningful_missing(df, declarations):
    """
    선언된 전략에 따라 의미 있는 결측을 처리합니다.
    처리된 컬럼은 이후 통계적 결측값 처리 단계에서 제외됩니다.

    strategy 허용값:
      'flag'     — is_{col}_present boolean 컬럼 추가 후 원본 결측 유지 (또는 -1 대체)
      'category' — 결측을 지정 범주값으로 채움 (기본: '미응시')
      'zero'     — 결측을 0으로 채움 (수치 부재를 0으로 해석)
      'keep'     — 아무것도 하지 않음 (트리 모델 등 결측 허용 모델용)
      'impute'   — 통계적 대체에 위임 (일반 결측값과 동일하게 처리)
    """
    df_mm = df.copy()
    handled_cols = []
    mm_log = []

    for decl in declarations:
        col = decl['col']
        strategy = decl.get('strategy', 'flag')

        if col not in df_mm.columns:
            print(f"  ⚠️ 컬럼 '{col}' 없음 — 건너뜀")
            continue

        missing_cnt = df_mm[col].isnull().sum()
        if missing_cnt == 0:
            print(f"  ℹ️ '{col}': 결측 없음 — 건너뜀")
            continue

        if strategy == 'flag':
            flag_col = decl.get('flag_col_name', f'is_{col}_present')
            df_mm[flag_col] = df_mm[col].notna().astype(int)
            # 원본 결측은 유지 (이후 모델이 처리) 또는 -1로 마킹
            fill_val = decl.get('fill_value_after_flag', None)
            if fill_val is not None:
                df_mm[col] = df_mm[col].fillna(fill_val)
            log_msg = f"flag 컬럼 '{flag_col}' 추가 (결측 {missing_cnt}건)"

        elif strategy == 'category':
            cat_val = decl.get('category_value', '미응시')
            df_mm[col] = df_mm[col].fillna(cat_val).astype(str)
            log_msg = f"결측 → '{cat_val}' 범주 대체 ({missing_cnt}건)"

        elif strategy == 'zero':
            df_mm[col] = df_mm[col].fillna(0)
            log_msg = f"결측 → 0 대체 ({missing_cnt}건)"

        elif strategy == 'keep':
            log_msg = f"결측 유지 (keep 선언, {missing_cnt}건)"

        elif strategy == 'impute':
            log_msg = f"통계적 대체 위임 (impute 선언) — 2단계에서 처리"
            handled_cols.append(col)  # 통계 단계 포함
            mm_log.append({'col': col, 'strategy': strategy, 'log': log_msg})
            continue

        else:
            log_msg = f"알 수 없는 strategy '{strategy}' — 건너뜀"

        if strategy != 'impute':
            handled_cols.append(col)  # 통계 단계에서 제외할 컬럼

        mm_log.append({'col': col, 'strategy': strategy, 'log': log_msg})
        print(f"  ✅ '{col}': {log_msg}")

    return df_mm, handled_cols, mm_log

# ── Step 0 실행 ──────────────────────────────────────────────────────
df = load_file("데이터_파일_경로")  # ← 실제 경로로 변경

# 1. 패킷에서 사전 선언 로드
mm_declarations = load_meaningful_missing_from_packet()

# 2. 패킷이 없거나 후보 탐지 추가 필요 시 AI 자동 탐지
candidates = detect_meaningful_missing_candidates(df)
if candidates:
    print("\n🔍 의미 있는 결측 후보 탐지됨 (사용자 확인 필요):")
    for c in candidates:
        print(f"  {c['col']} ({c['missing_pct']}% 결측) — {c['reason']}")
        print(f"    → 제안 전략: {c['suggested_strategy']}")
    print("\n위 후보에 대해 전략을 결정해주세요.")
    print("예: {'col': 'exam_score', 'strategy': 'flag', 'flag_col_name': 'is_exam_taken'}")
    print("    {'col': 'coupon_discount', 'strategy': 'zero'}")

# 3. 선언 확정 후 적용 (mm_declarations를 실제 선언으로 채워주세요)
# mm_declarations = [
#     {"col": "exam_score", "strategy": "flag", "flag_col_name": "is_exam_taken"},
#     {"col": "coupon_discount", "strategy": "zero"},
# ]

print("\n=== Step 0: MEANINGFUL_MISSING 처리 ===")
df_step0, mm_handled_cols, mm_log = apply_meaningful_missing(df, mm_declarations)
print(f"\n처리 완료: {len(mm_log)}건")
print(f"이후 통계 처리에서 제외될 컬럼: {[c for c in mm_handled_cols if c in df_step0.columns]}")
```

> **⚠️ 핵심 원칙**: 의미 있는 결측으로 선언된 컬럼은 1단계 이후의 통계 기반 처리(KNN, 평균/중앙값 대체)에서 자동으로 제외됩니다.
> 잘못 대체하면 "시험을 안 본 것"을 "평균 점수를 받은 것"으로 왜곡할 수 있습니다.

---

### 1단계: 현황 파악 및 처리 계획 수립

```python
import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
import seaborn as sns
import warnings
warnings.filterwarnings('ignore')

# 전처리 계획 수립을 위한 컬럼별 진단
def diagnose_columns(df):
    report = []
    for col in df.columns:
        col_info = {
            'column': col,
            'dtype': str(df[col].dtype),
            'missing_count': df[col].isnull().sum(),
            'missing_pct': round(df[col].isnull().mean() * 100, 2),
            'unique_count': df[col].nunique(),
            'unique_pct': round(df[col].nunique() / len(df) * 100, 2)
        }
        # 수치형 컬럼: 이상치 진단
        if df[col].dtype in ['int64', 'float64']:
            Q1 = df[col].quantile(0.25)
            Q3 = df[col].quantile(0.75)
            IQR = Q3 - Q1
            outlier_count = ((df[col] < Q1 - 1.5 * IQR) | (df[col] > Q3 + 1.5 * IQR)).sum()
            col_info['outlier_count'] = outlier_count
            col_info['outlier_pct'] = round(outlier_count / len(df) * 100, 2)
            col_info['mean'] = round(df[col].mean(), 4)
            col_info['median'] = round(df[col].median(), 4)
            col_info['std'] = round(df[col].std(), 4)
            col_info['skewness'] = round(df[col].skew(), 4)
        # 범주형/오브젝트 컬럼: 카디널리티 진단
        elif df[col].dtype == 'object':
            col_info['top_values'] = df[col].value_counts().head(5).to_dict()
        report.append(col_info)
    return pd.DataFrame(report)

diagnosis = diagnose_columns(df)
print(diagnosis.to_string())
```

**AI 판단 기준 — 결측값 처리 방법 자동 제안:**

| 조건 | 권장 처리 방법 | 근거 |
|------|--------------|------|
| 결측 비율 < 5% + 수치형 + 정규분포 | 평균 대체 (mean imputation) | 분포에 영향 최소화 |
| 결측 비율 < 5% + 수치형 + 비대칭 분포 | 중앙값 대체 (median imputation) | 이상치 영향 방지 |
| 결측 비율 < 5% + 범주형 | 최빈값 대체 (mode imputation) | 범주 분포 유지 |
| 결측 비율 5~30% + 수치형 | KNN 또는 반복 대체 (iterative imputer) | 다변량 관계 반영 |
| 결측 비율 > 30% | 컬럼 제거 또는 'Unknown' 범주 추가 | 노이즈 주입 위험 |
| 결측 자체가 정보인 경우 | `is_missing` 이진 플래그 컬럼 추가 | 결측 패턴 보존 |

> **사용자 확인 필요**: AI가 통계적으로 방법을 제안하지만,
> "이 컬럼의 결측이 실제로 '해당 없음'을 의미한다면 0 또는 별도 범주로 채워야 합니다."
> 비즈니스 의미를 아는 경우 AI 제안을 수정해주세요.

---

### 2단계: 결측값 처리

```python
from sklearn.impute import SimpleImputer, KNNImputer
from sklearn.experimental import enable_iterative_imputer
from sklearn.impute import IterativeImputer

# Step 0에서 처리된 df를 이어받아 사용
# df_step0, mm_handled_cols가 없으면 원본 df로 시작
if 'df_step0' not in dir():
    df_step0 = df.copy()
    mm_handled_cols = []

# ── 시계열 보간 (strategy["use_interpolation"]=True인 경우만) ─────────────
# 조건: table_type=시계열_집계 + time_column_role=인덱스 + 규칙적 간격
if strategy.get("use_interpolation") and strategy.get("time_col"):
    time_col   = strategy["time_col"]
    freq_map   = {"일별": "D", "주별": "W", "월별": "MS", "시간별": "h"}
    freq       = freq_map.get(strategy["time_interval"])

    if time_col in df_step0.columns and freq:
        df_step0[time_col] = pd.to_datetime(df_step0[time_col])
        df_step0 = df_step0.set_index(time_col).sort_index()

        full_idx   = pd.date_range(df_step0.index.min(), df_step0.index.max(), freq=freq)
        n_added    = len(full_idx) - len(df_step0)
        df_step0   = df_step0.reindex(full_idx)

        ts_num_cols = df_step0.select_dtypes(include='number').columns.tolist()
        df_step0[ts_num_cols] = df_step0[ts_num_cols].interpolate(method='time')
        df_step0 = df_step0.reset_index().rename(columns={'index': time_col})

        mm_handled_cols.extend(ts_num_cols)  # 이후 통계 처리에서 제외
        print(f"📅 시계열 보간 완료 ({strategy['time_interval']})")
        print(f"   누락 날짜 {n_added}행 추가, {len(ts_num_cols)}개 컬럼 선형 보간")
    else:
        if time_col not in df_step0.columns:
            print(f"⚠️ 날짜 컬럼 '{time_col}' 없음 → 일반 결측 처리로 진행")
        else:
            print(f"⚠️ time_interval='{strategy['time_interval']}' — freq 매핑 없음 → 일반 결측 처리로 진행")
else:
    print(f"ℹ️ 시계열 보간 미적용 — 일반 통계 기반 결측 처리 진행")

df_processed = df_step0.copy()
missing_log = []  # 처리 내역 기록

# --- 수치형 컬럼 결측값 처리 (Step 0 및 시계열 보간에서 처리된 컬럼 제외) ---
numeric_cols = [
    c for c in df_processed.select_dtypes(include=['number']).columns.tolist()
    if c not in mm_handled_cols
]

for col in numeric_cols:
    missing_pct = df[col].isnull().mean() * 100
    skewness = abs(df[col].skew())

    if missing_pct == 0:
        continue
    elif missing_pct > 30:
        # 결측 비율이 너무 높으면 플래그 컬럼 추가 후 중앙값 대체
        df_processed[f'{col}_was_missing'] = df[col].isnull().astype(int)
        df_processed[col].fillna(df[col].median(), inplace=True)
        method = f"중앙값 대체 + missing 플래그 (결측 {missing_pct:.1f}%)"
    elif missing_pct > 5:
        # KNN 대체 (다른 컬럼 정보 활용)
        imputer = KNNImputer(n_neighbors=5)
        df_processed[numeric_cols] = imputer.fit_transform(df_processed[numeric_cols])
        method = f"KNN 대체 (k=5, 결측 {missing_pct:.1f}%)"
        # KNN은 한 번에 처리하므로 루프 종료
        missing_log.append({'column': '수치형 전체 (KNN)', 'method': method})
        break
    elif skewness > 1:
        df_processed[col].fillna(df[col].median(), inplace=True)
        method = f"중앙값 대체 (왜도={skewness:.2f}, 결측 {missing_pct:.1f}%)"
    else:
        df_processed[col].fillna(df[col].mean(), inplace=True)
        method = f"평균 대체 (왜도={skewness:.2f}, 결측 {missing_pct:.1f}%)"

    missing_log.append({'column': col, 'method': method})

# --- 범주형 컬럼 결측값 처리 (Step 0에서 처리된 컬럼 제외) ---
cat_cols = [
    c for c in df_processed.select_dtypes(include=['object', 'category']).columns.tolist()
    if c not in mm_handled_cols
]

for col in cat_cols:
    missing_pct = df[col].isnull().mean() * 100
    if missing_pct == 0:
        continue
    elif missing_pct > 30:
        df_processed[col].fillna('Unknown', inplace=True)
        method = f"'Unknown' 범주 추가 (결측 {missing_pct:.1f}%)"
    else:
        mode_val = df[col].mode()[0]
        df_processed[col].fillna(mode_val, inplace=True)
        method = f"최빈값 대체 ('{mode_val}', 결측 {missing_pct:.1f}%)"

    missing_log.append({'column': col, 'method': method})

print("=== 결측값 처리 완료 ===")
for log in missing_log:
    print(f"  {log['column']}: {log['method']}")
print(f"\n처리 후 잔여 결측값: {df_processed.isnull().sum().sum()}")
```

---

### 3단계: 이상치 처리

```python
outlier_log = []

def handle_outliers(df, col, method='iqr_cap', multiplier=1.5):
    """
    이상치 처리 방법:
    - 'iqr_cap': IQR 기준으로 상한/하한에 클리핑 (권장 — 데이터 보존)
    - 'iqr_remove': IQR 기준으로 행 제거 (이상치가 실제 오류인 경우)
    - 'zscore_cap': Z-score 3 기준 클리핑
    """
    Q1 = df[col].quantile(0.25)
    Q3 = df[col].quantile(0.75)
    IQR = Q3 - Q1
    lower = Q1 - multiplier * IQR
    upper = Q3 + multiplier * IQR

    outlier_mask = (df[col] < lower) | (df[col] > upper)
    outlier_count = outlier_mask.sum()

    if outlier_count == 0:
        return df, 0

    if method == 'iqr_cap':
        df[col] = df[col].clip(lower=lower, upper=upper)
        return df, outlier_count
    elif method == 'iqr_remove':
        return df[~outlier_mask], outlier_count

# 이상치 처리 실행
# ⚠️ 기본값: 클리핑(cap) — 데이터를 제거하지 않고 경계값으로 대체
# 분석 목적에 따라 'iqr_remove'로 변경 가능

for col in numeric_cols:
    Q1 = df_processed[col].quantile(0.25)
    Q3 = df_processed[col].quantile(0.75)
    IQR = Q3 - Q1
    outlier_pct = ((df_processed[col] < Q1 - 1.5*IQR) | (df_processed[col] > Q3 + 1.5*IQR)).mean() * 100

    if outlier_pct > 0.1:  # 이상치가 0.1% 이상인 경우만 처리
        df_processed, count = handle_outliers(df_processed, col, method='iqr_cap')
        outlier_log.append({
            'column': col,
            'outlier_pct': f"{outlier_pct:.2f}%",
            'method': 'IQR 클리핑 (상한/하한 대체)'
        })

print("=== 이상치 처리 완료 ===")
for log in outlier_log:
    print(f"  {log['column']}: {log['outlier_pct']} → {log['method']}")
```

> **사용자 확인 필요**: 이상치 클리핑은 가장 안전한 기본값입니다.
> - 이상치가 **실제 오류**(입력 실수, 센서 오류)라면 → `method='iqr_remove'`로 변경
> - 이상치가 **비즈니스적으로 중요한 데이터**(VIP 구매, 바이럴 이벤트)라면 → 처리하지 않음

---

### 4단계: 범주형 인코딩

```python
from sklearn.preprocessing import LabelEncoder, OrdinalEncoder

# ── 통계 검정 목적이면 인코딩·스케일링 스킵 ─────────────────────────────
if strategy.get("skip_encoding_scaling"):
    print("⏭️  인코딩·스케일링 스킵 (analysis_purpose: 통계 검정 목적)")
    print("   통계 검정(t-test, 카이제곱 등)은 원본 값·범주 그대로 사용해야 해석이 정확합니다.")
    df_encoded = df_processed.copy()
    df_scaled  = df_processed.copy()
    encoding_log = []
    scaling_log  = []
else:

encoding_log = []

# 인코딩 방법 자동 선택 기준:
# - 카디널리티 <= 10: One-Hot Encoding (컬럼 수 증가 허용 가능)
# - 카디널리티 > 10: Label Encoding (고카디널리티는 원핫 비효율)
# - 순서가 있는 범주 (low/mid/high 등): Ordinal Encoding

# 순서형 컬럼이 있다면 아래에 직접 정의
ORDINAL_COLUMNS = {}  # 예: {'size': ['S', 'M', 'L', 'XL'], 'grade': ['F', 'D', 'C', 'B', 'A']}

df_encoded = df_processed.copy()
cols_to_drop = []

for col in cat_cols:
    if col not in df_encoded.columns:
        continue

    n_unique = df_encoded[col].nunique()

    if col in ORDINAL_COLUMNS:
        # 순서형: Ordinal Encoding
        oe = OrdinalEncoder(categories=[ORDINAL_COLUMNS[col]])
        df_encoded[col] = oe.fit_transform(df_encoded[[col]])
        encoding_log.append({'column': col, 'method': f'Ordinal ({ORDINAL_COLUMNS[col]})'})

    elif n_unique <= 10:
        # 저카디널리티: One-Hot Encoding
        dummies = pd.get_dummies(df_encoded[col], prefix=col, drop_first=True)
        df_encoded = pd.concat([df_encoded, dummies], axis=1)
        cols_to_drop.append(col)
        encoding_log.append({'column': col, 'method': f'One-Hot ({n_unique}개 카테고리 → {n_unique-1}개 컬럼)'})

    else:
        # 고카디널리티: Label Encoding
        le = LabelEncoder()
        df_encoded[col] = le.fit_transform(df_encoded[col].astype(str))
        encoding_log.append({'column': col, 'method': f'Label Encoding ({n_unique}개 유니크값)'})

df_encoded.drop(columns=cols_to_drop, inplace=True)

print("=== 범주형 인코딩 완료 ===")
for log in encoding_log:
    print(f"  {log['column']}: {log['method']}")
print(f"\n인코딩 후 컬럼 수: {df_processed.shape[1]} → {df_encoded.shape[1]}")
```

---

### 5단계: 수치형 스케일링

```python
from sklearn.preprocessing import StandardScaler, MinMaxScaler, RobustScaler

scaling_log = []

# 스케일링 방법 선택 기준:
# - StandardScaler: 정규분포에 가까운 수치형 (ML 일반 목적)
# - MinMaxScaler:   0~1 범위가 필요한 경우 (신경망, KNN)
# - RobustScaler:   이상치가 많은 경우 (중앙값/IQR 기반)

# 기본값: StandardScaler (가장 범용적)
SCALING_METHOD = 'standard'  # 'standard', 'minmax', 'robust' 중 선택

# 스케일링 제외 컬럼 (이진 변수, 이미 인코딩된 범주형, ID 등)
# context_packet의 target_col이 있으면 자동으로 제외 목록에 추가
SKIP_SCALING = []  # 예: ['user_id', 'is_active']
_target = strategy.get("protect_target_col")
if _target and _target not in SKIP_SCALING:
    SKIP_SCALING.append(_target)
    print(f"🎯 타깃 컬럼 '{_target}' 스케일링 제외 (context_packet에서 자동 설정)")

# 스케일링 대상: 수치형 컬럼 중 이진이 아닌 것 + 타깃 제외
scale_cols = [
    col for col in df_encoded.select_dtypes(include='number').columns
    if col not in SKIP_SCALING
    and df_encoded[col].nunique() > 2  # 이진 변수 제외
]

if SCALING_METHOD == 'standard':
    scaler = StandardScaler()
    method_name = 'StandardScaler (평균=0, 표준편차=1)'
elif SCALING_METHOD == 'minmax':
    scaler = MinMaxScaler()
    method_name = 'MinMaxScaler (0~1 범위)'
else:
    scaler = RobustScaler()
    method_name = 'RobustScaler (중앙값/IQR 기반)'

df_scaled = df_encoded.copy()
df_scaled[scale_cols] = scaler.fit_transform(df_encoded[scale_cols])

scaling_log.append({'columns': scale_cols, 'method': method_name})

print(f"=== 스케일링 완료 ===")
print(f"  방법: {method_name}")
print(f"  대상 컬럼 수: {len(scale_cols)}")
print(f"\n  스케일링 전:\n{df_encoded[scale_cols].describe().loc[['mean','std','min','max']].round(3)}")
print(f"\n  스케일링 후:\n{df_scaled[scale_cols].describe().loc[['mean','std','min','max']].round(3)}")
```

---

### 6단계: 최종 검증 및 저장

```python
import os

# 전처리 전후 비교
print("=" * 60)
print("전처리 전후 비교")
print("=" * 60)
print(f"행 수:    {df.shape[0]:,} → {df_scaled.shape[0]:,} ({df_scaled.shape[0] - df.shape[0]:+,})")
print(f"컬럼 수:  {df.shape[1]} → {df_scaled.shape[1]}")
print(f"결측값:   {df.isnull().sum().sum()} → {df_scaled.isnull().sum().sum()}")
print(f"중복 행:  {df.duplicated().sum()} → {df_scaled.duplicated().sum()}")

# 처리된 데이터 저장
output_path = "data-preprocessing_result.csv"
df_scaled.to_csv(output_path, index=False, encoding='utf-8-sig')
print(f"\n✅ 전처리 완료: {output_path} 저장됨")

# 처리 내역 요약 출력
print("\n=== 전처리 처리 내역 요약 ===")
print("\n[결측값 처리]")
for log in missing_log:
    print(f"  • {log['column']}: {log['method']}")
print("\n[이상치 처리]")
for log in outlier_log:
    print(f"  • {log['column']}: {log['outlier_pct']} → {log['method']}")
print("\n[범주형 인코딩]")
for log in encoding_log:
    print(f"  • {log['column']}: {log['method']}")
print("\n[수치형 스케일링]")
for log in scaling_log:
    print(f"  • {', '.join(log['columns'][:5])}{'...' if len(log['columns'])>5 else ''}: {log['method']}")
```

---

## 컨텍스트 검증

전처리 완료 전 확인하세요:

- [ ] 결측값 처리 방법이 비즈니스 맥락과 맞는가? (예: 구매금액 결측 = 0 vs 제외)
- [ ] 이상치 클리핑 경계값이 비즈니스적으로 타당한가? (예: 나이 150세는 오류)
- [ ] 인코딩 방법이 컬럼 특성에 맞는가? (순서형 범주에 Label Encoding하면 오해 발생)
- [ ] 스케일링 방법이 이후 분석 방법과 맞는가? (트리 모델은 스케일링 불필요)
- [ ] 처리 후 타깃 컬럼이 변형되지 않았는가?
- [ ] 행 수가 예상치 않게 크게 줄지 않았는가?

---

## 출력 템플릿

### `data-preprocessing_report.md` 구조

```
# 데이터 전처리 보고서

## 처리 개요
- 원본 데이터: {행 수} 행 × {컬럼 수} 컬럼
- 처리 후 데이터: {행 수} 행 × {컬럼 수} 컬럼
- 처리 일시: {날짜}

## Step 0: 의미 있는 결측 처리 내역
| 컬럼 | 결측 비율 | 선언 전략 | 처리 결과 |

## 결측값 처리 내역 (통계 기반)
| 컬럼 | 결측 비율 | 처리 방법 | 근거 |

## 이상치 처리 내역
| 컬럼 | 이상치 비율 | 처리 방법 | 경계값 |

## 인코딩 내역
| 컬럼 | 카디널리티 | 인코딩 방법 | 결과 |

## 스케일링 내역
| 컬럼 그룹 | 방법 | 전 범위 | 후 범위 |

## 사용자 재정의 항목
(AI 기본 제안에서 변경된 항목 기록)

## 다음 단계
- 권장: stats-basic 또는 ml-supervised 진행
```
