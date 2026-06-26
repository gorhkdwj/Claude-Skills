---
name: column-navigator
description: |
  수십~수백 개의 컬럼이 있는 광폭 데이터셋에서 분석 방향을 잡아주는 스킬.
  CSV·Excel·JSON·Parquet·TSV 등 다양한 형식을 지원합니다.
  컬럼을 자동 분류하고, 중복·불필요 컬럼을 제거하며,
  분석 목적에 맞는 핵심 컬럼을 우선순위화하여
  이후 EDA·통계·ML 분석에 집중할 컬럼 목록을 확정합니다.

  다음 상황에서 반드시 이 스킬을 사용하세요:
  - "컬럼이 너무 많아서 어디서 시작해야 할지 모르겠어" (50개 이상)
  - "중요한 컬럼과 불필요한 컬럼을 구분해줘"
  - "수백 개 컬럼 중에서 분석에 쓸 컬럼만 골라줘"
  - "컬럼들 간의 관계를 파악하고 싶어"
  - "wide 데이터셋의 분석 방향을 잡고 싶어"
  - multi-file-merge 이후 컬럼 수가 많아진 경우
---

# 컬럼 네비게이터 스킬

수십~수백 개의 컬럼을 체계적으로 분류하고, 분석 목적에 맞는 핵심 컬럼을 선별합니다.
출력물은 `column-navigator.ipynb`(실행결과 내장) + `column-navigator_result.csv`(컬럼 분류 및 우선순위 표) + `column-navigator_report.md`(분석 방향 권고 보고서)입니다.

## Phase
Phase 1 — 컬럼 방향 설정 (multi-file-merge 이후 또는 programmatic-eda 이전)

## Input
- 분석할 데이터 파일 (CSV·Excel·JSON·Parquet·TSV 등)
- 분석 목적 또는 비즈니스 질문 (가능하면)
- 도메인 지식 (컬럼 의미를 알고 있는 경우)

## Output
- `column-navigator.ipynb` — 전체 컬럼 분석 코드 (실행결과 내장)
- `column-navigator_result.csv` — 컬럼별 분류, 품질, 우선순위 정리표
- `column-navigator_report.md` — 핵심 컬럼 목록, 제거 권고 컬럼, 분석 방향 제안

---

## 빠른 시작

컬럼이 많을수록 "다 보려는 유혹"을 버려야 합니다.
**자동 분류 → 품질 필터링 → 목적 기반 선별** 순서로 집중할 컬럼을 줄여나갑니다.
AI가 컬럼명의 의미를 해석하고, 코드가 통계적 근거를 제공하며, 최종 결정은 사용자가 합니다.

---

## 필요한 컨텍스트

1. **데이터 파일**: 분석할 파일 경로 또는 업로드
2. **분석 목적**: 무엇을 알고 싶은지 (예: "고객 이탈 예측", "매출 분석", "품질 불량 원인 파악")
3. **타겟 변수** (있다면): 예측하거나 설명하고 싶은 컬럼명
4. **도메인 지식** (선택): 특정 컬럼의 의미나 중요도를 알고 있다면

---

## 컨텍스트 수집

### 데이터가 제공되지 않은 경우:
"분석할 파일을 제공해주세요.

지원 형식: CSV, TSV, Excel (.xlsx/.xls), JSON, Parquet

컬럼이 많은 파일일수록 더 유용하게 활용됩니다."

### 분석 목적이 없는 경우:
"컬럼 우선순위를 정하려면 분석 목적이 필요합니다.

다음 중 가장 가까운 것을 선택해주세요:
1. 특정 결과 예측 (예: 이탈 여부, 매출, 불량률) → 타겟 변수가 있음
2. 패턴/그룹 발견 (예: 고객 세분화, 이상 거래 탐지) → 비지도 분석
3. 현황 파악 및 리포팅 (예: KPI 대시보드, 요약 통계)
4. 아직 목적이 불명확 → 데이터 구조를 먼저 탐색

목적을 모르더라도 진행할 수 있습니다. 분석 후 방향을 제안드릴게요."

---

## 워크플로우

### 1단계: 데이터 로드 및 전체 컬럼 개요

```python
import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
import matplotlib
import seaborn as sns
import warnings
warnings.filterwarnings('ignore')

matplotlib.rcParams['font.family'] = 'DejaVu Sans'
matplotlib.rcParams['axes.unicode_minus'] = False

def load_file(path):
    """확장자에 따라 파일 자동 로드"""
    ext = path.rsplit('.', 1)[-1].lower()
    loaders = {
        'csv':     lambda: pd.read_csv(path, encoding='utf-8'),
        'tsv':     lambda: pd.read_csv(path, sep='\t', encoding='utf-8'),
        'json':    lambda: pd.read_json(path),
        'parquet': lambda: pd.read_parquet(path),
        'xlsx':    lambda: pd.read_excel(path),
        'xls':     lambda: pd.read_excel(path),
    }
    try:
        return loaders[ext]()
    except UnicodeDecodeError:
        if ext in ('csv', 'tsv'):
            sep = '\t' if ext == 'tsv' else ','
            return pd.read_csv(path, sep=sep, encoding='cp949')
        raise

# ─── 파일 경로 입력 ───
df = load_file("파일경로")
# ─────────────────────

print(f"데이터 크기: {df.shape[0]:,}행 × {df.shape[1]}열")
print(f"컬럼 수: {df.shape[1]}개\n")

# 컬럼 타입별 현황
print("[dtype 분포]")
print(df.dtypes.value_counts().to_string())
```

### 2단계: 컬럼 자동 분류 및 품질 프로파일

```python
def classify_and_profile(df):
    """모든 컬럼을 분류하고 품질 지표를 계산"""
    results = []

    for col in df.columns:
        series = df[col]
        n = len(series)
        n_null = series.isnull().sum()
        null_rate = n_null / n
        n_unique = series.nunique()
        unique_rate = n_unique / n
        dtype = str(series.dtype)

        # ── 역할 분류 ──
        name_lower = col.lower().replace('_', '').replace('-', '').replace(' ', '')

        # 제거 후보: 결측치 과다 or 분산 0
        if null_rate > 0.9:
            role = '🔴 제거 권고 (결측 90%+)'
        elif n_unique <= 1:
            role = '🔴 제거 권고 (단일값)'
        # ID/Key
        elif any(kw in name_lower for kw in ['id','key','code','no','num','idx','seq','번호','코드']):
            if unique_rate > 0.8:
                role = '🔑 ID/식별자'
            else:
                role = '🏷️ 범주 코드'
        # 날짜/시간
        elif any(kw in name_lower for kw in ['date','time','dt','at','created','updated','day','month','year','날짜','일시','시간']):
            role = '📅 날짜/시간'
        # 이진
        elif n_unique == 2:
            role = '⚡ 이진(Binary)'
        # 수치형
        elif dtype in ['int64','float64','int32','float32','int16','float16']:
            if n_unique <= 10:
                role = '🏷️ 순서형/등급'
            else:
                role = '📊 수치형 지표'
        # 텍스트/범주형
        elif dtype == 'object' or dtype == 'category':
            if n_unique <= 10:
                role = '🏷️ 범주형 (저카디널리티)'
            elif n_unique <= 50:
                role = '🏷️ 범주형 (중카디널리티)'
            elif n_unique <= 200:
                role = '🏷️ 범주형 (고카디널리티)'
            else:
                role = '📝 자유 텍스트'
        else:
            role = '❓ 기타'

        # ── 품질 점수 (0~100) ──
        quality = 100
        quality -= null_rate * 50          # 결측 페널티
        if n_unique <= 1: quality -= 50    # 단일값 페널티
        quality = max(0, quality)

        results.append({
            '컬럼명': col,
            '역할 분류': role,
            'dtype': dtype,
            '결측률(%)': round(null_rate * 100, 1),
            '유니크 수': n_unique,
            '유니크 비율(%)': round(unique_rate * 100, 1),
            '품질 점수': round(quality, 0),
            '샘플값': str(series.dropna().head(2).tolist())
        })

    return pd.DataFrame(results)

profile_df = classify_and_profile(df)

# 결과 출력
print(f"\n{'='*80}")
print("📋 컬럼 분류 결과")
print(f"{'='*80}")
for role, group in profile_df.groupby('역할 분류'):
    print(f"\n{role} ({len(group)}개)")
    for _, row in group.iterrows():
        print(f"  • {row['컬럼명']:<40} 결측:{row['결측률(%)']:>5.1f}%  유니크:{row['유니크 수']:>8,}")
```

### 3단계: 상관관계 기반 중복 컬럼 탐지

```python
# 수치형 컬럼만 상관분석
numeric_cols = df.select_dtypes(include=[np.number]).columns.tolist()

if len(numeric_cols) >= 2:
    corr_matrix = df[numeric_cols].corr().abs()

    # 고상관 쌍 탐지 (0.95 이상)
    high_corr_pairs = []
    for i in range(len(corr_matrix.columns)):
        for j in range(i+1, len(corr_matrix.columns)):
            corr_val = corr_matrix.iloc[i, j]
            if corr_val >= 0.95:
                high_corr_pairs.append({
                    '컬럼A': corr_matrix.columns[i],
                    '컬럼B': corr_matrix.columns[j],
                    '상관계수': round(corr_val, 4),
                    '권고': '둘 중 하나 제거 검토'
                })

    if high_corr_pairs:
        print(f"\n⚠️ 고상관 컬럼 쌍 (상관계수 0.95 이상) — 중복 가능성")
        high_corr_df = pd.DataFrame(high_corr_pairs)
        print(high_corr_df.to_string(index=False))
    else:
        print("\n✓ 고상관 컬럼 쌍 없음 (0.95 기준)")

    # 시각화: 상관 히트맵 (컬럼이 30개 이하일 때)
    if len(numeric_cols) <= 30:
        fig, ax = plt.subplots(figsize=(12, 10))
        sns.heatmap(df[numeric_cols].corr(), annot=len(numeric_cols)<=15,
                    fmt='.2f', cmap='RdYlGn', center=0, ax=ax,
                    square=True, linewidths=0.5)
        ax.set_title('수치형 컬럼 상관관계 히트맵')
        plt.tight_layout()
        plt.show()
    else:
        print(f"\n(수치형 컬럼 {len(numeric_cols)}개 — 히트맵은 상위 30개만 표시)")
        top30 = numeric_cols[:30]
        fig, ax = plt.subplots(figsize=(14, 12))
        sns.heatmap(df[top30].corr(), cmap='RdYlGn', center=0, ax=ax,
                    square=True, linewidths=0.3)
        ax.set_title(f'수치형 컬럼 상관관계 히트맵 (상위 30개)')
        plt.tight_layout()
        plt.show()
```

### 4단계: 분석 목적 기반 핵심 컬럼 우선순위화

```python
# ─── 분석 목적 설정 ───
analysis_goal = "목적 입력"  # 예: "고객 이탈 예측", "매출 분석"
target_col = None            # 예: "churn", "revenue" (없으면 None)
# ─────────────────────

print(f"\n🎯 분석 목적: {analysis_goal}")
if target_col:
    print(f"   타겟 변수: {target_col}")

# 제거 권고 컬럼 목록
remove_candidates = profile_df[
    profile_df['역할 분류'].str.startswith('🔴')
]['컬럼명'].tolist()

# 타겟과의 상관 (수치형 타겟인 경우)
if target_col and target_col in df.columns and df[target_col].dtype in [np.float64, np.int64]:
    target_corr = df[numeric_cols].corrwith(df[target_col]).abs().sort_values(ascending=False)
    print(f"\n📊 타겟({target_col})과의 상관관계 상위 15개:")
    print(target_corr.head(15).to_string())

# 최종 우선순위 컬럼 분류
priority_cols = {
    '즉시 제거': remove_candidates,
    '핵심 분석 컬럼': [],   # 사용자 확인 후 채움
    '보조 참고 컬럼': [],
    '보류': []
}

print(f"\n\n{'='*60}")
print("📌 컬럼 우선순위 요약")
print(f"{'='*60}")
print(f"전체 컬럼: {df.shape[1]}개")
print(f"제거 권고: {len(remove_candidates)}개 → {remove_candidates[:5]}{'...' if len(remove_candidates)>5 else ''}")
print(f"분석 대상: {df.shape[1] - len(remove_candidates)}개")
```

### 5단계: 결과 저장

```python
# 컬럼 분류 결과 저장
output_path = "column-navigator_result.csv"
profile_df.to_csv(output_path, index=False, encoding='utf-8-sig')
print(f"\n✅ 컬럼 분류표 저장: {output_path}")
print(f"   총 {len(profile_df)}개 컬럼 분류 완료")
```

---

## AI 해석 단계 (코드 실행 후 Claude가 수행)

코드 실행 결과를 바탕으로 다음을 해석합니다:

1. **컬럼명 의미 해석**: 도메인 지식 없이도 컬럼명 패턴으로 비즈니스 의미를 추론합니다. 불명확한 것은 사용자에게 질문합니다.
2. **그룹 패턴 탐지**: 접두사/접미사가 같은 컬럼 그룹을 묶고 의미를 설명합니다. (예: `amt_jan`, `amt_feb`, `amt_mar` → 월별 금액 시계열)
3. **분석 목적과 연결**: 사용자가 제시한 분석 목적에 가장 관련 높은 컬럼을 추천합니다.
4. **도메인 특화 컬럼 확인**: 의미를 파악하기 어려운 축약어 컬럼은 사용자에게 명시적으로 질문합니다.

---

## 컨텍스트 유효성 검사

- [ ] 파일이 정상 로드되었음
- [ ] 전체 컬럼 수와 분류 결과를 확인했음
- [ ] 제거 권고 컬럼의 이유를 사용자에게 설명했음
- [ ] 불명확한 컬럼명에 대해 사용자에게 의미를 질문했음
- [ ] 최종 분석 대상 컬럼 목록을 사용자가 확인했음

---

## 출력 템플릿

```
컬럼 네비게이터 보고서
생성일: [날짜]
데이터: [파일명] ([N]행 × [N]열)
분석 목적: [목적]

## 컬럼 분류 요약
| 역할 분류           | 컬럼 수 |
|--------------------|---------|
| 🔑 ID/식별자        | N       |
| 📅 날짜/시간        | N       |
| 📊 수치형 지표       | N       |
| 🏷️ 범주형           | N       |
| 📝 자유 텍스트       | N       |
| 🔴 제거 권고        | N       |

## 제거 권고 컬럼 (이유 포함)
- [컬럼명]: [제거 이유]

## 고상관 중복 쌍
- [컬럼A] ↔ [컬럼B]: 상관계수 [N] → [처리 권고]

## 핵심 분석 컬럼 추천 (분석 목적 기반)
1. [컬럼명]: [선택 이유]
2. ...

## 불명확 컬럼 (도메인 확인 필요)
- [컬럼명]: "[추정 의미]" — 맞나요?

## 최종 분석 컬럼 목록
[사용자 확인 후 확정된 컬럼 목록]

## 다음 단계
→ programmatic-eda 스킬로 확정된 컬럼만 EDA 진행
```

---

## 자주 발생하는 상황 및 대응

**상황: 컬럼이 200개 이상**
→ 먼저 즉시 제거 후보(결측 90%+, 단일값)를 정리하고, 역할 분류별로 묶어서 그룹 단위로 검토합니다.

**상황: 도메인 특화 축약어가 많음**
→ 파악 가능한 컬럼은 해석하고, 불명확한 컬럼 목록을 정리해서 사용자에게 한 번에 질문합니다. 개별로 반복 질문하지 않습니다.

**상황: 타겟 변수가 없음 (비지도 분석)**
→ ID 컬럼과 결측 컬럼을 제거한 후, 수치형/범주형을 분리하여 각각 EDA 또는 군집 분석(`ml-unsupervised`)으로 연결합니다.

**상황: 원핫 인코딩된 컬럼이 많음**
→ 동일 접두사를 가진 컬럼 그룹을 탐지하여 "이 N개 컬럼은 [원본 컬럼]의 원핫 인코딩으로 보입니다"라고 안내합니다.

---

## 다른 스킬과의 연계

```
[광폭 데이터셋 입력]
      ↓
column-navigator  (이 스킬)
  • 컬럼 분류 및 불필요 컬럼 제거
  • 핵심 컬럼 목록 확정
      ↓
programmatic-eda  (확정된 컬럼만 EDA)
      ↓
stats-basic / ml-supervised / ml-unsupervised
```
