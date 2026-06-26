---
name: multi-file-merge
description: |
  여러 파일(CSV·Excel·JSON·Parquet·TSV 등)을 하나의 분석용 데이터셋으로 통합하는 스킬.
  각 파일의 컬럼 구조를 먼저 완전히 파악한 뒤, 파일 간 관계와 조인 키를 탐지하고,
  병합 전략을 결정하여 실행하고, 결과를 검증합니다.
  이후 programmatic-eda 또는 column-navigator로 넘길 준비까지 완료합니다.

  다음 상황에서 반드시 이 스킬을 사용하세요:
  - "여러 CSV/Excel 파일을 하나로 합치고 싶어"
  - "10개 이상의 파일이 있는데 어떻게 병합해야 할지 모르겠어"
  - "파일마다 컬럼 구조가 달라서 join 키를 찾아야 해"
  - "병합 후 데이터가 맞는지 검증하고 싶어"
  - "분석 전에 여러 소스 데이터를 통합해야 해"
---

# 다중 파일 병합 스킬

여러 파일을 하나의 분석 준비된 데이터셋으로 통합합니다.
출력물은 `multi-file-merge.ipynb`(실행결과 내장) + `multi-file-merge_result.csv`(병합 완료 데이터) + `multi-file-merge_report.md`(병합 과정 및 결정 사항 보고서)입니다.

## Phase
Phase 0 — 데이터 통합 (programmatic-eda 또는 column-navigator 이전 단계)

## Input
- 분석할 파일들 (CSV·Excel·JSON·Parquet·TSV 등, 2개 이상)
- 각 파일의 비즈니스 의미 (알고 있다면)

## Output
- `multi-file-merge.ipynb` — 전체 병합 과정 코드 (실행결과 내장)
- `multi-file-merge_result.csv` — 병합 완료된 최종 데이터셋
- `multi-file-merge_report.md` — 각 파일 구조 요약, 조인 키 선택 근거, 병합 전략, 검증 결과

---

## 빠른 시작

병합의 핵심은 "무작정 합치기"가 아니라 **구조 파악 → 관계 탐지 → 전략 결정 → 실행 → 검증** 순서입니다.
각 파일이 무엇을 의미하는지 먼저 이해한 뒤 병합하세요.

---

## 필요한 컨텍스트

1. **파일 목록**: 병합할 파일 경로 또는 업로드
2. **파일 형식**: CSV·Excel·JSON·Parquet·TSV (혼합 가능)
3. **분석 목적**: 병합 후 무엇을 분석할 예정인지
4. **도메인 지식** (선택): 각 파일이 무엇을 나타내는지 (고객, 거래, 상품 등)

---

## 컨텍스트 수집

### 파일이 제공되지 않은 경우:
"병합할 파일들을 제공해주세요.

지원하는 형식:
- CSV, TSV (구분자 구분 텍스트)
- Excel (.xlsx, .xls)
- JSON (레코드 또는 배열 형식)
- Parquet

파일 경로 또는 직접 업로드 모두 가능합니다."

### 분석 목적이 불명확한 경우:
"병합 전략을 최적화하려면 다음을 알아야 합니다:
- 병합 후 어떤 분석을 진행할 예정인가요?
- 최종 데이터셋에서 가장 중요한 핵심 항목(row 단위)은 무엇인가요?
  예: 고객 1명, 거래 1건, 제품 1개, 날짜 1일
- 파일 간 공통 키(ID, 코드 등)가 있다고 알고 계신 것이 있나요?"

### 파일 수가 많아 컨텍스트가 부족한 경우:
"파일이 많네요. 효율적으로 진행하기 위해:
- 각 파일의 이름이나 용도를 간단히 설명해주실 수 있나요?
- 어떤 파일이 '핵심 테이블'이고 나머지가 '보조 테이블'인지 알고 계신가요?"

---

## 워크플로우

### 1단계: 전체 파일 구조 파악 (컬럼 프로파일링)

**이 단계가 가장 중요합니다. 구조를 완전히 파악한 뒤에만 병합을 시작하세요.**

```python
import pandas as pd
import numpy as np
import os
import warnings
warnings.filterwarnings('ignore')

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
    # encoding 오류 시 fallback
    try:
        return loaders[ext]()
    except UnicodeDecodeError:
        if ext == 'csv':
            return pd.read_csv(path, encoding='cp949')
        raise

# ─── 파일 경로 목록을 여기에 입력 ───
file_paths = [
    "파일1.csv",
    "파일2.xlsx",
    "파일3.json",
    # 필요한 만큼 추가
]
# ──────────────────────────────────

# 전체 파일 프로파일링
profiles = {}
dfs = {}

for path in file_paths:
    name = os.path.basename(path)
    df = load_file(path)
    dfs[name] = df

    profile = {
        'shape': df.shape,
        'columns': list(df.columns),
        'dtypes': df.dtypes.to_dict(),
        'null_rate': (df.isnull().sum() / len(df) * 100).round(2).to_dict(),
        'unique_counts': {col: df[col].nunique() for col in df.columns},
        'sample_values': {col: df[col].dropna().head(3).tolist() for col in df.columns}
    }
    profiles[name] = profile

    print(f"\n{'='*60}")
    print(f"📄 {name}")
    print(f"   크기: {df.shape[0]:,}행 × {df.shape[1]}열")
    print(f"   컬럼({df.shape[1]}개):")
    for col in df.columns:
        null_pct = profile['null_rate'][col]
        uniq = profile['unique_counts'][col]
        dtype = str(df[col].dtype)
        flag = "⚠️" if null_pct > 30 else ("△" if null_pct > 5 else "✓")
        print(f"     {flag} {col:<30} {dtype:<12} 유니크:{uniq:>8,}  결측:{null_pct:>5.1f}%")
```

### 2단계: 컬럼 타입 자동 분류

```python
def classify_column(col_name, series):
    """컬럼을 비즈니스 역할별로 자동 분류"""
    name_lower = col_name.lower()
    nuniq = series.nunique()
    n = len(series)
    dtype = str(series.dtype)

    # ID/Key 판별 (고유값 비율 높음 + 이름 패턴)
    id_keywords = ['id', 'key', 'code', 'no', 'num', 'idx', 'seq', '번호', '코드', '아이디']
    if any(kw in name_lower for kw in id_keywords) or (nuniq / n > 0.95 and nuniq > 100):
        return 'ID/Key'

    # 날짜 판별
    date_keywords = ['date', 'time', 'dt', 'at', 'day', 'month', 'year', '날짜', '일시', '시간']
    if any(kw in name_lower for kw in date_keywords) or 'datetime' in dtype:
        return '날짜/시간'

    # 수치형 지표
    if dtype in ['int64', 'float64', 'int32', 'float32']:
        if nuniq <= 2:
            return '이진(Binary)'
        return '수치형 지표'

    # 범주형
    if dtype == 'object' or dtype == 'category':
        if nuniq <= 20:
            return '범주형 (저카디널리티)'
        elif nuniq <= 100:
            return '범주형 (중카디널리티)'
        else:
            return '텍스트/고카디널리티'

    return '기타'

# 전체 파일 컬럼 분류표 생성
print("\n📊 전체 컬럼 타입 분류")
print(f"{'파일명':<20} {'컬럼명':<35} {'타입 분류':<25} {'유니크':<10} {'결측률'}")
print("-" * 100)
for name, df in dfs.items():
    for col in df.columns:
        col_type = classify_column(col, df[col])
        nuniq = df[col].nunique()
        null_pct = df[col].isnull().mean() * 100
        print(f"{name:<20} {col:<35} {col_type:<25} {nuniq:<10,} {null_pct:.1f}%")
```

### 3단계: 조인 키 후보 자동 탐지

```python
def find_join_candidates(dfs, top_n=5):
    """파일 간 조인 키 후보를 자동으로 탐지"""
    candidates = []
    file_names = list(dfs.keys())

    for i in range(len(file_names)):
        for j in range(i+1, len(file_names)):
            name_a, name_b = file_names[i], file_names[j]
            df_a, df_b = dfs[name_a], dfs[name_b]

            for col_a in df_a.columns:
                for col_b in df_b.columns:
                    # 1. 컬럼명 유사도
                    a_lower = col_a.lower().replace('_', '').replace('-', '')
                    b_lower = col_b.lower().replace('_', '').replace('-', '')
                    name_match = (a_lower == b_lower) or (a_lower in b_lower) or (b_lower in a_lower)

                    # 2. dtype 일치
                    dtype_match = str(df_a[col_a].dtype) == str(df_b[col_b].dtype)

                    # 3. 값 겹침 비율
                    try:
                        vals_a = set(df_a[col_a].dropna().astype(str))
                        vals_b = set(df_b[col_b].dropna().astype(str))
                        if len(vals_a) > 0 and len(vals_b) > 0:
                            overlap = len(vals_a & vals_b) / min(len(vals_a), len(vals_b))
                        else:
                            overlap = 0
                    except:
                        overlap = 0

                    # 점수 계산
                    score = (name_match * 0.5) + (dtype_match * 0.2) + (overlap * 0.3)

                    if score > 0.3:
                        candidates.append({
                            '파일A': name_a, '컬럼A': col_a,
                            '파일B': name_b, '컬럼B': col_b,
                            '점수': round(score, 3),
                            '이름유사': name_match,
                            '타입일치': dtype_match,
                            '값겹침': f"{overlap:.1%}"
                        })

    result = pd.DataFrame(candidates).sort_values('점수', ascending=False).head(top_n * 3)
    return result

candidates_df = find_join_candidates(dfs)
print("\n🔑 조인 키 후보 (점수 높은 순)")
print(candidates_df.to_string(index=False))
```

### 4단계: 병합 전략 결정 (사용자 확인)

조인 키 후보를 제시한 뒤 사용자에게 다음을 확인하세요:

"탐지된 조인 키 후보를 바탕으로 병합 전략을 제안합니다.

**확인이 필요한 사항:**
1. 제안된 조인 키가 맞나요? 아니면 수동으로 지정하시겠어요?
2. 병합 방식을 선택해주세요:
   - `inner` — 양쪽 파일에 모두 있는 행만 유지 (교집합)
   - `left`  — 왼쪽 기준 파일의 모든 행 유지
   - `outer` — 양쪽 파일의 모든 행 유지 (합집합)
3. 중복 컬럼(같은 정보가 양쪽에 있음)은 어느 쪽을 우선할까요?
4. 병합 순서가 있나요? (예: A+B 먼저, 그 결과에 C 병합)

결정이 어려우시면 제가 추천 전략을 제안드릴 수 있습니다."

### 5단계: 병합 실행

```python
# ─── 병합 설정 (4단계 확인 후 수정) ───
merge_plan = [
    {
        'left': '파일A.csv',
        'right': '파일B.csv',
        'left_on': 'id',       # 왼쪽 조인 키
        'right_on': 'user_id', # 오른쪽 조인 키
        'how': 'left',         # inner / left / outer
        'suffixes': ('_A', '_B')
    },
    # 추가 병합 단계 (결과에 파일C 병합 등)
]
# ──────────────────────────────────────

merged = None
merge_log = []

for step_idx, plan in enumerate(merge_plan):
    left_df = merged if merged is not None else dfs[plan['left']]
    right_df = dfs[plan['right']]
    before_rows = len(left_df)

    merged = left_df.merge(
        right_df,
        left_on=plan['left_on'],
        right_on=plan['right_on'],
        how=plan['how'],
        suffixes=plan.get('suffixes', ('_x', '_y'))
    )

    after_rows = len(merged)
    row_change = after_rows - before_rows
    change_pct = row_change / before_rows * 100 if before_rows > 0 else 0

    log = {
        '단계': step_idx + 1,
        '병합파일': plan['right'],
        '방식': plan['how'],
        '병합전행수': before_rows,
        '병합후행수': after_rows,
        '행변화': f"{row_change:+,} ({change_pct:+.1f}%)"
    }
    merge_log.append(log)
    print(f"✓ 단계 {step_idx+1}: {plan['right']} 병합 완료 → {after_rows:,}행")

print(f"\n최종 데이터셋: {merged.shape[0]:,}행 × {merged.shape[1]}열")
```

### 6단계: 병합 결과 검증

```python
print("\n" + "="*60)
print("📋 병합 결과 검증")
print("="*60)

# 1. 행 수 검증
print(f"\n[행 수 변화]")
for log in merge_log:
    print(f"  단계 {log['단계']}: {log['병합전행수']:,} → {log['병합후행수']:,}  ({log['행변화']})")

# 2. 결측치 증가 확인
print(f"\n[결측치 현황] (상위 10개 컬럼)")
null_summary = (merged.isnull().sum() / len(merged) * 100).sort_values(ascending=False).head(10)
for col, pct in null_summary.items():
    flag = "🔴" if pct > 30 else ("🟡" if pct > 5 else "🟢")
    print(f"  {flag} {col:<40} {pct:.1f}%")

# 3. 중복 행 확인
dup_count = merged.duplicated().sum()
print(f"\n[중복 행]: {dup_count:,}개 {'⚠️ 확인 필요' if dup_count > 0 else '✓ 없음'}")

# 4. 컬럼 충돌(_x, _y) 확인
conflict_cols = [c for c in merged.columns if c.endswith('_x') or c.endswith('_y')]
if conflict_cols:
    print(f"\n[컬럼 충돌 감지]: {conflict_cols}")
    print("  → 중복 컬럼 정리가 필요합니다. 어느 쪽을 유지할지 결정해주세요.")
else:
    print(f"\n[컬럼 충돌]: ✓ 없음")

# 5. 최종 저장
output_path = "multi-file-merge_result.csv"
merged.to_csv(output_path, index=False, encoding='utf-8-sig')
print(f"\n✅ 저장 완료: {output_path} ({merged.shape[0]:,}행 × {merged.shape[1]}열)")
```

---

## 컨텍스트 유효성 검사

병합 실행 전 다음을 반드시 확인하세요:

- [ ] 모든 파일이 정상적으로 로드되었음
- [ ] 각 파일의 컬럼 구조와 타입을 파악했음
- [ ] 조인 키의 값 겹침 비율이 충분함 (최소 10% 이상 권장)
- [ ] 병합 방식(inner/left/outer)이 분석 목적에 맞음
- [ ] 병합 순서가 올바르게 설정됨

---

## 출력 템플릿

```
다중 파일 병합 보고서
생성일: [날짜]
병합 파일 수: [N]개

## 파일별 구조 요약
| 파일명 | 행 수 | 컬럼 수 | 주요 컬럼 | 특이사항 |
|--------|-------|---------|-----------|---------|
| ...    | ...   | ...     | ...       | ...     |

## 선택된 조인 키
| 파일A | 키A | 파일B | 키B | 값겹침률 |
|-------|-----|-------|-----|---------|

## 병합 전략
- 병합 방식: [inner/left/outer]
- 병합 순서: [순서 설명]
- 중복 컬럼 처리: [처리 방식]

## 검증 결과
- 최종 행 수: [N]행 (병합 전 대비 [+/-N]행)
- 최종 컬럼 수: [N]열
- 결측치 증가: [있음/없음]
- 중복 행: [N]개

## 주의사항 및 권고
- [발견된 이슈 및 권고사항]

## 다음 단계
- 컬럼이 많다면 (50개 이상): `column-navigator` 스킬로 방향 설정
- 컬럼이 적당하다면: `programmatic-eda` 스킬로 탐색적 분석 진행
```

---

## 자주 발생하는 상황 및 대응

**상황: 조인 키가 탐지되지 않음**
→ 대응: "파일 간 공통 키를 찾지 못했습니다. 수동으로 조인 키를 지정해주시거나, 파일들이 키 없이 단순 행 연결(concat)이 필요한지 확인해주세요."

**상황: 병합 후 행 수가 급격히 증가**
→ 대응: "병합 후 행 수가 [N배] 증가했습니다. 조인 키에 중복값이 있어 카르테시안 곱이 발생했을 수 있습니다. 조인 키의 유니크 여부를 확인해드릴까요?"

**상황: 컬럼 충돌(_x, _y)이 많음**
→ 대응: "충돌 컬럼이 [N]개 있습니다. 각 쌍에 대해 어느 쪽 값을 유지할지 결정이 필요합니다. 값 비교 후 추천해드릴 수 있습니다."

**상황: 파일 형식이 혼합됨**
→ 대응: 각 파일을 형식에 맞게 자동 로드 후 동일하게 처리합니다. 인코딩 오류 발생 시 CP949(한국어 Windows 환경)로 fallback합니다.

---

## 다른 스킬과의 연계

```
multi-file-merge  (이 스킬)
      ↓
[컬럼 50개 이상?]
  YES → column-navigator  (컬럼 방향 설정)
  NO  → programmatic-eda  (탐색적 데이터 분석)
      ↓
  이후 분석 스킬들
```
