---
name: analysis-path-guide
description: |
  데이터와 분석 목적을 입력받아 최적의 분석 경로를 추천하는 입문 가이드 스킬.
  어디서 시작해야 할지 모르는 초보자, 또는 새로운 데이터셋을 처음 마주한 분석가를 위한 시작점입니다.
  데이터 구조를 자동으로 탐지하고, 목적에 맞는 스킬 사용 순서를 단계별로 안내합니다.

  다음 상황에서 반드시 이 스킬을 사용하세요:
  - "어디서 시작해야 할지 모르겠어"
  - "데이터가 있는데 무슨 분석을 해야 해?"
  - "분류 모델을 만들고 싶은데 어떤 스킬을 순서대로 써야 해?"
  - "이 데이터로 할 수 있는 분석이 뭐가 있어?"
  - "처음 데이터를 받았는데 어떻게 진행하지?"
  - "추천 분석 경로를 알려줘"
---

# 분석 경로 가이드 스킬

데이터와 목적을 입력하면, 어떤 스킬을 어떤 순서로 사용해야 하는지 맞춤 로드맵을 제시합니다.
분석 계획을 대화로 안내하고, 경로 확정 후 **`context_packet.json`을 생성**하여 하위 스킬에 맥락을 전달합니다.

## Phase
Phase 0 — 분석 시작점 (모든 스킬 이전, 또는 언제든지 방향을 잡고 싶을 때)

## Input
- 데이터 파일 (선택: 없어도 대화로 진행 가능)
- 분석 목적 또는 비즈니스 질문

## Output
- 맞춤형 분석 로드맵 (대화 출력)
- 권장 스킬 사용 순서
- 각 단계별 예상 결과물
- **컨텍스트 패킷** — `context_packet.json` (하위 스킬들이 읽는 구조화 메타데이터)

---

## 빠른 시작

이 스킬은 **질문에 답하는 방식**으로 분석 경로를 안내합니다.
데이터 파일을 제공하면 자동 탐지로 더 정확한 경로를 추천하고,
파일 없이 목적만 말해도 경로 추천이 가능합니다.

---

## 필요한 컨텍스트

다음 중 하나만 있어도 시작할 수 있습니다:
1. **데이터 파일** — 구조를 자동 분석해 경로 추천
2. **분석 목적** — "고객 이탈을 예측하고 싶어", "매출 추이를 보고 싶어"
3. **비즈니스 질문** — "왜 지난달 매출이 떨어졌지?", "어떤 고객이 가장 가치있어?"

---

## 컨텍스트 수집

### 데이터 파일이 제공된 경우:

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

def auto_detect_data_profile(df):
    """데이터 구조를 자동 탐지하여 분석 경로 결정 및 컨텍스트 패킷 생성에 사용할 프로파일 반환"""
    # 날짜/시간 컬럼 탐지
    datetime_cols = [
        c for c in df.columns
        if any(kw in c.lower() for kw in ['date', 'time', 'dt', 'at', 'created', 'updated', 'timestamp'])
    ]

    profile = {
        'n_rows': df.shape[0],
        'n_cols': df.shape[1],
        'n_numeric': df.select_dtypes(include='number').shape[1],
        'n_categorical': df.select_dtypes(include=['object', 'category']).shape[1],
        'has_datetime': len(datetime_cols) > 0,
        'datetime_cols': datetime_cols,
        'missing_pct': round(df.isnull().mean().mean() * 100, 2),
        'n_duplicate_rows': df.duplicated().sum(),
        'potential_target': None,
        'data_type_guess': None,
        # 컨텍스트 패킷 필드 (하위 스킬 전달용)
        'table_type': None,
        'time_column_role': '없음',
        'time_interval': '없음',
        'meaningful_missing_candidates': []
    }

    # 타깃 컬럼 후보 탐지 (이진 범주형 또는 수치형)
    for col in df.columns:
        if df[col].nunique() == 2:
            profile['potential_target'] = col
            profile['data_type_guess'] = 'classification'
            break
        elif col.lower() in ['target', 'label', 'y', 'churn', 'is_fraud', 'converted']:
            profile['potential_target'] = col
            break

    # 날짜 컬럼 역할 추론 (단순 키워드 탐지 — 사용자 확인 필요)
    if datetime_cols:
        date_col = datetime_cols[0]
        try:
            parsed = pd.to_datetime(df[date_col], errors='coerce')
            valid_ratio = parsed.notna().mean()
            if valid_ratio > 0.8:
                # 인덱스 역할: 중복 없이 순서대로 정렬된 경우
                if df[date_col].nunique() == len(df):
                    profile['time_column_role'] = '인덱스_후보'
                else:
                    profile['time_column_role'] = '집계기준_후보'

                # 시간 간격 추론
                diffs = parsed.dropna().sort_values().diff().dt.days.dropna()
                if len(diffs) > 0:
                    median_diff = diffs.median()
                    if median_diff <= 1:
                        profile['time_interval'] = '일별'
                    elif median_diff <= 7:
                        profile['time_interval'] = '주별'
                    elif median_diff <= 31:
                        profile['time_interval'] = '월별'
                    else:
                        profile['time_interval'] = '불규칙'
        except Exception:
            pass

    # 시계열 데이터 감지
    if profile['has_datetime'] and profile['n_numeric'] >= 1:
        profile['data_type_guess'] = 'time_series'

    # 테이블 유형 추론 (사용자 확인 필요)
    id_like_cols = [c for c in df.columns if any(kw in c.lower() for kw in ['id', 'user', 'customer', 'session'])]
    event_like_cols = [c for c in df.columns if any(kw in c.lower() for kw in ['event', 'action', 'click', 'log', 'purchase'])]

    if profile['time_column_role'] in ['인덱스_후보'] and profile['n_numeric'] >= 2:
        profile['table_type'] = '시계열_집계_후보'
    elif id_like_cols and event_like_cols:
        profile['table_type'] = '이벤트_로그_후보'
    elif id_like_cols:
        profile['table_type'] = '사용자_스냅샷_후보'
    else:
        profile['table_type'] = '미분류'

    # 의미 있는 결측 후보 탐지
    # 결측이 있으면서 컬럼명이 시험·설문·참여 등 "미응시/미참여" 의미를 가질 수 있는 경우
    semantic_missing_keywords = ['score', 'exam', 'test', 'survey', 'response', 'answer',
                                  'purchase', 'payment', 'coupon', 'visit', 'point', 'fee']
    for col in df.columns:
        if df[col].isnull().sum() > 0:
            if any(kw in col.lower() for kw in semantic_missing_keywords):
                profile['meaningful_missing_candidates'].append({
                    'col': col,
                    'missing_pct': round(df[col].isnull().mean() * 100, 2),
                    'reason': f"'{col}' 컬럼의 결측은 단순 누락이 아닌 '미응시/미참여/해당없음' 의미일 수 있음"
                })

    return profile

# 파일 경로를 실제 경로로 변경하세요
# df = load_file("데이터_파일_경로")
# profile = auto_detect_data_profile(df)
# print(profile)
```

### 목적만 말한 경우 (파일 없이):
아래 질문에 답하면 분석 경로를 안내합니다.

---

## 워크플로우

### 핵심 질문 체계 (Claude가 사용자에게 묻는 순서)

**질문 1 — 분석 목적 파악:**
"어떤 결과를 얻고 싶으신가요? 아래 중 가장 가까운 것을 선택하거나 직접 말씀해주세요:

① **예측** — "다음 달 매출을 예측하고 싶어" / "고객 이탈 가능성을 알고 싶어"
② **분류** — "이 거래가 사기인지 아닌지 판단하고 싶어" / "고객을 등급별로 분류하고 싶어"
③**원인 분석** — "왜 매출이 떨어졌는지 알고 싶어" / "어떤 요소가 이탈에 영향을 주는지"
④ **탐색** — "데이터에 어떤 패턴이 있는지 보고 싶어" / "비슷한 고객끼리 묶고 싶어"
⑤ **추이 분석** — "시간에 따른 변화를 보고 싶어" / "계절성이 있는지 확인하고 싶어"
⑥ **비교/검증** — "A/B 테스트 결과가 유의미한지" / "두 그룹이 실제로 다른지""

**질문 2 — 데이터 환경 파악:**
"데이터가 어떤 형태인가요?

① **CSV / Excel 파일** — 로컬 파일로 분석 시작 → 경로 G (파일 기반)
② **DB / SQL 테이블** — 데이터베이스에 직접 접근 → 경로 G-DB (DB 전용)
③ **아직 없음** — 목적만 확정 후 경로 결정

**① 파일인 경우 추가 질문:**
- 파일이 몇 개인가요? (1개 / 여러 개)
- 행(데이터 건수)은 대략 몇 개인가요? (100 미만 / 수천 / 수만 / 수십만 이상)
- 예측하려는 컬럼(타깃)이 이미 있나요?

**② DB인 경우 추가 질문:**
- 어떤 DB를 사용하고 있나요? (PostgreSQL / MySQL / Snowflake / BigQuery / 기타)
- 어떤 스키마/테이블을 분석할 예정인가요?
- 테이블이 몇 개 정도 있나요? (스키마 전체 탐색 vs 특정 테이블만)"

**질문 3 — 데이터 품질 인식 확인:**
"데이터에 대해 알고 있는 것이 있나요?
- 결측값이 많은 컬럼이 있나요?
- 이상하거나 오류로 보이는 값이 있나요?
- 파일이 여러 개라면 어떻게 연결되나요?"

---

## 분석 경로 추천 매트릭스

사용자의 답변에 따라 아래 경로 중 하나를 추천합니다.

### 경로 A: 지도학습 — 분류 (이탈 예측, 사기 탐지, 합격 여부 등)

```
[시작] 데이터 파일 확보
  │
  ▼
① multi-file-merge      ← 파일이 여러 개인 경우
  │
  ▼
② column-navigator      ← 컬럼이 30개 이상인 경우
  │
  ▼
③ programmatic-eda      ← 항상 필수
  │
  ▼
④ data-quality-audit    ← 결측값·이상치 의심되는 경우
  │
  ▼
⑤ data-preprocessing    ← ML 전 필수 전처리
  │
  ▼
⑥ feature-engineering   ← 파생 변수로 성능 향상 원할 때
  │
  ▼
⑦ ml-supervised         ← 최종 분류 모델
  │
  ▼
⑧ analysis-documentation ← 결과 정리 및 보고
```

**예상 소요 시간**: 2~4시간 (데이터 크기 및 품질에 따라)

---

### 경로 B: 지도학습 — 회귀 (매출 예측, 가격 예측 등)

```
① (multi-file-merge → ) column-navigator →
② programmatic-eda → data-quality-audit →
③ data-preprocessing → feature-engineering →
④ ml-supervised (회귀 모드)
```

경로 A와 동일하나, ml-supervised 실행 시 타깃 컬럼이 연속형 수치임을 지정합니다.

---

### 경로 C: 비지도학습 — 군집화 (고객 세그먼트, 상품 분류 등)

```
① (multi-file-merge → ) column-navigator →
② programmatic-eda → data-quality-audit →
③ data-preprocessing →
④ ml-unsupervised (군집화 모드) →
⑤ segmentation-analysis (군집 해석) →
⑥ analysis-documentation
```

타깃 없이 데이터 구조 자체에서 그룹을 발견합니다.

---

### 경로 D: 원인 분석 — 지표 하락 이유 파악

```
① programmatic-eda (현황 파악) →
② root-cause-investigation (원인 탐색) →
③ stats-basic (통계 검정으로 유의미성 확인) →
④ data-narrative-builder (보고서 작성) →
⑤ executive-summary-generator (임원 보고용)
```

"왜 이런 일이 일어났는가"를 체계적으로 파고듭니다.

**SaaS·이커머스 지표 하락 분석 시 선택 분기:**

```
① programmatic-eda →
① (추가) business-metrics-calculator  ← MRR·이탈률·LTV 등 KPI 현황 먼저 파악
② root-cause-investigation            ← "어떤 지표가 얼마나 하락했는지" 확인 후 진입
③ stats-basic →
④ data-narrative-builder
```

> MRR 하락, 이탈률 급등, LTV:CAC 악화 등 비즈니스 KPI 이상이 감지된 경우,
> root-cause-investigation 전에 **business-metrics-calculator**로 지표 전체 현황을 먼저 잡아두면
> 원인 탐색의 기준점이 명확해집니다.

---

### 경로 E: 추이 분석 — 시계열 패턴 및 예측

```
① programmatic-eda →
② time-series-analysis (추세·계절성·예측) →
③ cohort-analysis (기간별 코호트 유지율) →
④ visualization-builder (차트 생성) →
⑤ data-narrative-builder
```

날짜 컬럼이 있는 데이터에서 시간 흐름을 분석합니다.

---

### 경로 F: 비교/검증 — A/B 테스트, 그룹 간 차이

```
① programmatic-eda →
② stats-basic (t-검정, 카이제곱 등) →
③ ab-test-analysis (A/B 테스트 유의성) →
④ methodology-explainer (방법론 설명) →
⑤ analysis-documentation
```

두 그룹 또는 실험군/대조군 비교에 사용합니다.

---

### 경로 G: 완전 탐색 — 파일 기반, 목적이 불명확한 경우

```
[시작] CSV / Excel 파일 확보
  │
  ▼
① multi-file-merge      ← 파일이 여러 개인 경우
  │
  ▼
② column-navigator      ← 컬럼이 30개 이상인 경우
  │
  ▼
③ programmatic-eda      ← 전체 탐색
  │
  ▼
④ data-quality-audit    ← 품질 점검
  │
  ▼
⑤ analysis-path-guide   ← 다시 실행 — 이제 목적 결정 가능
  → 경로 A~F 중 선택
```

처음에는 데이터를 충분히 이해한 뒤, 목적을 결정하고 전문 경로로 진입합니다.

---

### 경로 G-DB: 완전 탐색 — DB/SQL 환경, 목적이 불명확한 경우

```
[시작] DB 접근 정보 확보 (연결 문자열 또는 스키마 내보내기)
  │
  ▼
① schema-mapper         ← 테이블 구조·관계 파악, ERD 생성, 조인 경로 탐색
  │                        → schema-mapper_report.md (테이블·컬럼 목록, 조인 가이드)
  ▼
② programmatic-eda      ← SQL로 추출한 데이터 탐색
  │                        (schema-mapper 결과를 보고 어떤 테이블에서 뭘 뽑을지 결정)
  ▼
③ data-quality-audit    ← 품질 점검
  │
  ▼
④ analysis-path-guide   ← 다시 실행 — 이제 목적 결정 가능
  → 경로 A~F 중 선택
```

**파일 기반(경로 G)과의 차이:**

| 단계 | 경로 G (파일) | 경로 G-DB (DB) |
|------|--------------|----------------|
| 데이터 통합 | multi-file-merge | 불필요 (테이블이 DB에 이미 있음) |
| 구조 파악 | column-navigator | **schema-mapper** (ERD + 조인 경로) |
| 데이터 추출 | 파일 직접 로드 | SQL 쿼리 작성 후 로드 |
| EDA 선행 조건 | 없음 | schema-mapper 완료 후 진행 |

**예상 소요 시간**: 3~5시간 (테이블 수 및 관계 복잡도에 따라)

---

## 스킬 전체 맵 (빠른 참조)

| 단계 | 스킬 | 역할 | 필수 여부 |
|------|------|------|----------|
| 0 | **analysis-path-guide** | 분석 경로 결정 | 초보자 필수 |
| 0 | **multi-file-merge** | 여러 파일 통합 | 파일이 여러 개면 필수 |
| 0 (DB) | **schema-mapper** | DB 테이블 구조·관계 파악, ERD 생성 | **경로 G-DB 필수** |
| 1 | **column-navigator** | 컬럼 구조 파악 | 컬럼 30개+ 권장 (파일 기반) |
| 2 | **programmatic-eda** | 데이터 탐색 | 항상 필수 |
| 3 | **data-quality-audit** | 품질 점검 | 결측/이상치 있으면 필수 |
| 2.5 (선택) | **business-metrics-calculator** | SaaS·이커머스 KPI 현황 진단 | SaaS·이커머스 + 지표 하락 분석 시 |
| 3.5 | **data-preprocessing** | 데이터 전처리 | ML 전 필수 |
| 3.7 | **feature-engineering** | 파생 변수 생성 | ML 성능 향상 |
| 4 | **ml-supervised** | 분류/회귀 모델 | 예측 목적 |
| 4 | **ml-unsupervised** | 군집화/이상탐지 | 탐색/세분화 목적 |
| 4 | **stats-basic** | 기초 통계 검정 | 가설 검증 |
| 4 | **stats-advanced** | 심화 통계 | 복잡한 검정 |
| 4 | **time-series-analysis** | 시계열 분석 | 날짜 데이터 |
| 4 | **cohort-analysis** | 코호트 유지율 | SaaS/커머스 |
| 4 | **funnel-analysis** | 전환율 분석 | 퍼널 데이터 |
| 4 | **segmentation-analysis** | 세그먼트 해석 | 군집 결과 |
| 4 | **ab-test-analysis** | A/B 테스트 | 실험 데이터 |
| 4 | **root-cause-investigation** | 원인 분석 | 지표 이상 |
| 5 | **insight-synthesis** | 인사이트 정리 | 보고 전 |
| 5 | **data-narrative-builder** | 스토리 구성 | 보고서 작성 |
| 5 | **visualization-builder** | 차트 생성 | 시각화 |
| 5 | **executive-summary-generator** | 임원 요약 | 보고 |
| 5 | **analysis-documentation** | 전체 문서화 | 최종 아카이브 |

---

## 컨텍스트 패킷 생성

분석 경로가 확정되면 아래 형식의 **컨텍스트 패킷**을 `context_packet.json`으로 저장합니다.
이 파일은 하위 스킬(data-preprocessing, time-series-analysis 등)이 자동으로 읽어 불필요한 재질문을 줄입니다.

```python
import json

def build_context_packet(profile, user_confirmed):
    """
    profile: auto_detect_data_profile() 결과
    user_confirmed: 사용자가 대화에서 확인/수정한 항목 dict
    """
    packet = {
        # ── 데이터 구조 ──────────────────────────────────
        "table_type": user_confirmed.get("table_type", profile["table_type"]),
        # 가능한 값: '거래_로그' | '시계열_집계' | '사용자_스냅샷' | '이벤트_로그' | '기타'

        "time_column_role": user_confirmed.get("time_column_role", profile["time_column_role"]),
        # 가능한 값: '인덱스' | '집계기준' | '이벤트발생시각' | '없음'

        "time_column_name": user_confirmed.get("time_column_name",
                                                profile["datetime_cols"][0] if profile["datetime_cols"] else None),

        "time_interval": user_confirmed.get("time_interval", profile["time_interval"]),
        # 가능한 값: '일별' | '주별' | '월별' | '불규칙' | '없음'

        # ── 분석 목적 ──────────────────────────────────
        "analysis_purpose": user_confirmed.get("analysis_purpose", profile["data_type_guess"]),
        # 가능한 값: '분류예측' | '회귀예측' | '군집화' | '시계열예측' | '원인분석' | 'AB검정' | '탐색'

        "target_col": user_confirmed.get("target_col", profile["potential_target"]),

        "recommended_path": user_confirmed.get("recommended_path", "G"),
        # 가능한 값: 'A' | 'B' | 'C' | 'D' | 'E' | 'F' | 'G' | 'G-DB'

        # ── 데이터 현황 ──────────────────────────────────
        "data_source_type": user_confirmed.get("data_source_type", "file"),
        # 가능한 값: 'file' | 'db'
        # 'db'인 경우 schema-mapper를 Phase 0으로 실행

        "db_type": user_confirmed.get("db_type", None),
        # 가능한 값: 'postgresql' | 'mysql' | 'snowflake' | 'bigquery' | 'redshift' | 기타
        # data_source_type == 'db'인 경우만 사용

        "n_rows_approx": profile["n_rows"],
        "n_cols": profile["n_cols"],
        "n_files": user_confirmed.get("n_files", 1),

        # ── 도메인 노트 ──────────────────────────────────
        "domain_notes": user_confirmed.get("domain_notes", []),
        # 예: ["age=0은 데이터 오류", "revenue 음수는 환불"]

        "meaningful_missing_candidates": user_confirmed.get(
            "meaningful_missing_candidates",
            profile["meaningful_missing_candidates"]
        ),
        # 예: [{"col": "exam_score", "strategy": "flag", "flag_col_name": "is_exam_taken"}]

        # ── 메타 ──────────────────────────────────────
        "generated_by": "analysis-path-guide",
        "version": "1.0"
    }
    return packet

# ── 사용 예시 ──────────────────────────────────────────
# 1. 데이터 탐지
# df = load_file("sales_data.csv")
# profile = auto_detect_data_profile(df)
#
# 2. 사용자와 대화하여 확인/수정 사항 수집
# user_confirmed = {
#     "table_type": "시계열_집계",
#     "time_column_role": "인덱스",
#     "time_interval": "일별",
#     "analysis_purpose": "시계열예측",
#     "target_col": "daily_revenue",
#     "recommended_path": "E",
#     "n_files": 1,
#     "domain_notes": ["주말 데이터는 항상 0 — 정상"],
#     "meaningful_missing_candidates": []
# }
#
# 3. 패킷 생성 및 저장
# packet = build_context_packet(profile, user_confirmed)
# with open("context_packet.json", "w", encoding="utf-8") as f:
#     json.dump(packet, f, ensure_ascii=False, indent=2)
# print("✅ context_packet.json 저장 완료")
```

> **⚠️ AI 탐지는 후보 제안일 뿐입니다.**
> `table_type`, `time_column_role`, `time_interval` 등은 자동 탐지 결과를 사용자에게 보여주고
> **반드시 확인/수정을 받은 후** 패킷에 기록합니다.
> 잘못된 `table_type`은 data-preprocessing의 보간 전략 오적용으로 이어집니다.

---

## 컨텍스트 검증

분석 경로 결정 전 확인하세요:

- [ ] 분석의 최종 목적이 명확한가? (보고, 모델 배포, 의사결정 지원 등)
- [ ] 데이터가 목적에 충분한가? (행 수, 타깃 변수 존재 여부)
- [ ] 시간적 제약이 있는가? (빠른 인사이트 vs 정밀 모델)
- [ ] 결과를 누가 보는가? (비기술자 → 시각화·요약 중시, 기술자 → 코드 중시)
- [ ] 반복 수행이 필요한가? (자동화 필요 시 schedule 스킬 고려)

---

## 출력 템플릿

이 스킬은 **두 가지 출력**을 제공합니다.

**① 분석 로드맵** — 아래 형식으로 대화에 출력합니다. (파일 없음)

**② context_packet.json** — 분석 경로 확정 후 저장합니다. 위 "컨텍스트 패킷 생성" 섹션의 `build_context_packet()` 코드를 실행하면 생성됩니다.
하위 스킬(data-preprocessing, time-series-analysis 등)이 이 파일을 자동으로 읽어 재질문을 줄입니다.

---

분석 로드맵 출력 형식:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📊 맞춤형 분석 로드맵
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

🎯 분석 목적: [사용자 목적 요약]
📁 데이터 현황: [파일 수, 행 수, 주요 컬럼]
🔍 감지된 데이터 유형: [시계열 / 분류 / 회귀 / 탐색형]

📌 추천 분석 경로: 경로 [A~G]

단계별 실행 계획:
  1️⃣  [스킬명] — [이유 및 기대 결과]
  2️⃣  [스킬명] — [이유 및 기대 결과]
  ...

⚠️  주의사항:
  • [데이터 품질 이슈 등 특이사항]
  • [도메인 지식이 필요한 구간]

⏱️  예상 소요 시간: [~시간]
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```
