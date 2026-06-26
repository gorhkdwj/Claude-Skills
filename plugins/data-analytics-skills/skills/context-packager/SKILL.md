---
name: context-packager
description: AI 보조 분석을 위한 배경정보를 효율적으로 패키징합니다. Claude와 함께 분석 작업을 준비할 때, 배경정보 문서를 정리할 때, 또는 복잡한 분석 작업을 위한 프롬프트를 구성할 때 사용하세요. Efficiently package context for AI-assisted analysis. Use when preparing to work with Claude on analysis, organizing context documents, or structuring prompts for complex analytical tasks.
---

# DA Skills 컨텍스트 패키저

DA Skills 전체 워크플로우에서 **스킬 간 정보 전달의 공식 채널**입니다.
`analysis-path-guide`가 생성한 컨텍스트 패킷을 정제·보완하여 `context_packet.json`으로 저장하고,
하위 스킬(data-preprocessing, time-series-analysis 등)이 이 파일을 읽어 재질문 없이 맥락을 이어받습니다.

## Phase
Phase 0.5 — 컨텍스트 패키징 (analysis-path-guide 이후, 전처리·분석 스킬 이전)

## Input
- `context_packet.json` (analysis-path-guide가 생성) — 없으면 대화로 직접 작성
- 데이터 파일 (선택) — 추가 자동 탐지에 사용

## Output
- `context_packet.json` — 하위 스킬 전체가 읽는 구조화 메타데이터 (생성 또는 갱신)

---

## 패킷 스키마 (표준 정의)

DA Skills 컨텍스트 패킷의 전체 필드 정의입니다.
이 스키마를 기준으로 하위 스킬은 필요한 필드만 선택적으로 읽습니다.

```json
{
  // ── 데이터 구조 ───────────────────────────────────────
  "table_type": "시계열_집계",
  // 허용값: "거래_로그" | "시계열_집계" | "사용자_스냅샷" | "이벤트_로그" | "기타"
  // 설명:
  //   거래_로그   — 건별 이벤트 기록 (주문, 클릭, 로그인 등)
  //   시계열_집계 — 날짜 인덱스 + 집계 수치 (일별 매출, 월별 사용자 수 등)
  //   사용자_스냅샷 — 사용자/고객 1행씩 특성 기록 (CRM, 회원 테이블)
  //   이벤트_로그 — 타임스탬프 + 이벤트명 + 메타데이터 (앱 로그, 서버 로그)
  //   기타        — 위에 해당하지 않는 경우

  "time_column_role": "인덱스",
  // 허용값: "인덱스" | "집계기준" | "이벤트발생시각" | "없음"
  // 설명:
  //   인덱스         — 각 행이 시간상 고유한 집계 단위 (일별 매출 등)
  //   집계기준       — 날짜로 GROUP BY 가능하지만 행이 중복될 수 있음
  //   이벤트발생시각 — 이벤트가 발생한 시각 (거래 로그의 created_at 등)
  //   없음           — 날짜/시간 컬럼 없음

  "time_column_name": "date",
  // 실제 컬럼명. time_column_role이 "없음"이면 null

  "time_interval": "일별",
  // 허용값: "일별" | "주별" | "월별" | "불규칙" | "없음"
  // 중요: "불규칙"이면 data-preprocessing에서 시간 보간을 사용하지 않음

  // ── 분석 목적 ───────────────────────────────────────
  "analysis_purpose": "시계열예측",
  // 허용값: "분류예측" | "회귀예측" | "군집화" | "시계열예측" | "원인분석" | "AB검정" | "탐색"

  "target_col": "daily_revenue",
  // 예측/분석 대상 컬럼. 없으면 null

  "recommended_path": "E",
  // analysis-path-guide가 추천한 경로 (A~G)

  // ── 데이터 현황 ───────────────────────────────────────
  "n_rows_approx": 365,
  "n_cols": 12,
  "n_files": 1,

  // ── 의미 있는 결측 선언 ───────────────────────────────
  "meaningful_missing": [
    {
      "col": "exam_score",
      "strategy": "flag",
      "flag_col_name": "is_exam_taken"
    },
    {
      "col": "coupon_discount",
      "strategy": "zero"
    }
  ],
  // strategy 허용값:
  //   "flag"     — is_{col}_present 같은 boolean 컬럼 추가 후 결측 유지 또는 0 처리
  //   "category" — 결측을 '미응시' / 'Not Applicable' 등 별도 범주로 채움
  //   "zero"     — 결측 = 0 (구매 없음, 방문 없음 등 수치 부재를 0으로 해석)
  //   "keep"     — 결측 그대로 유지 (트리 모델 등 결측 허용 모델용)
  //   "impute"   — 통계적 대체 (data-preprocessing 기본 로직에 위임)

  // ── 도메인 노트 ───────────────────────────────────────
  "domain_notes": [
    "주말 revenue=0은 정상 (영업 안 함)",
    "age=0은 데이터 오류로 제거 필요",
    "revenue 음수는 환불 — 제거하지 않음"
  ],

  // ── 메타 ──────────────────────────────────────────────
  "generated_by": "context-packager",
  "version": "1.0"
}
```

---

## 빠른 시작

### 시나리오 A: analysis-path-guide가 이미 context_packet.json을 생성한 경우

```python
import json

# 기존 패킷 로드
with open("context_packet.json", "r", encoding="utf-8") as f:
    packet = json.load(f)

print("현재 패킷 내용:")
for k, v in packet.items():
    print(f"  {k}: {v}")
```

기존 패킷을 확인한 뒤 아래 사항을 보완합니다:
- `meaningful_missing` 필드가 비어 있으면 사용자에게 의미 있는 결측 여부 확인
- `domain_notes`가 비어 있으면 비즈니스 제약 조건 수집
- `table_type`이 `_후보`로 끝나면 사용자 확인 후 확정

---

### 시나리오 B: context_packet.json이 없는 경우 (처음부터 작성)

아래 질문에 답하면 패킷을 생성합니다.

**질문 1 — 테이블 유형:**
"데이터가 어떤 형태인가요?
① 날짜별 집계 수치 (일별 매출, 주별 사용자 수 등) → 시계열_집계
② 사용자/고객 1명당 1행 (회원 정보, CRM 등) → 사용자_스냅샷
③ 건별 이벤트 기록 (주문 로그, 클릭 로그 등) → 거래_로그 또는 이벤트_로그
④ 기타"

**질문 2 — 날짜 컬럼 역할:**
"날짜/시간 컬럼이 있나요? 있다면:
- 그 컬럼이 각 행을 구분하는 인덱스인가요? (중복 없음)
- 아니면 여러 행이 같은 날짜를 가질 수 있나요?"

**질문 3 — 의미 있는 결측:**
"결측값 중 단순 누락이 아닌 것이 있나요?
예: 시험 점수 NaN → '미응시', 쿠폰 할인 NaN → '쿠폰 미사용(=0)'"

**질문 4 — 도메인 규칙:**
"데이터에서 알고 있는 비즈니스 규칙이 있나요?
예: 'age=0은 오류', '음수 매출은 환불로 정상'"

---

## 패킷 생성/갱신 코드

```python
import json
import os

def load_or_init_packet():
    """기존 패킷 로드 또는 빈 패킷 초기화"""
    if os.path.exists("context_packet.json"):
        with open("context_packet.json", "r", encoding="utf-8") as f:
            return json.load(f)
    return {
        "table_type": None,
        "time_column_role": "없음",
        "time_column_name": None,
        "time_interval": "없음",
        "analysis_purpose": None,
        "target_col": None,
        "recommended_path": None,
        "n_rows_approx": None,
        "n_cols": None,
        "n_files": 1,
        "meaningful_missing": [],
        "domain_notes": [],
        "generated_by": "context-packager",
        "version": "1.0"
    }

def save_packet(packet, path="context_packet.json"):
    """패킷 저장"""
    packet["generated_by"] = "context-packager"
    with open(path, "w", encoding="utf-8") as f:
        json.dump(packet, f, ensure_ascii=False, indent=2)
    print(f"✅ {path} 저장 완료")
    return packet

# 사용 예시
packet = load_or_init_packet()

# 대화에서 확인한 내용으로 갱신
# (아래 값을 실제 대화 결과로 채우세요)
updates = {
    "table_type": "시계열_집계",          # 사용자 확인 완료
    "time_column_role": "인덱스",
    "time_column_name": "date",
    "time_interval": "일별",
    "analysis_purpose": "시계열예측",
    "target_col": "daily_revenue",
    "recommended_path": "E",
    "n_files": 1,
    "meaningful_missing": [
        # strategy: "flag" | "category" | "zero" | "keep" | "impute"
        # {"col": "exam_score", "strategy": "flag", "flag_col_name": "is_exam_taken"}
    ],
    "domain_notes": [
        # "주말 revenue=0은 정상"
    ]
}

packet.update(updates)
save_packet(packet)
```

---

## 하위 스킬에서 패킷 읽는 방법

하위 스킬(data-preprocessing, time-series-analysis 등)은 세션 시작 시 다음 코드로 패킷을 로드합니다:

```python
import json
import os

def read_context_packet(path="context_packet.json"):
    """컨텍스트 패킷 로드. 없으면 None 반환."""
    if not os.path.exists(path):
        return None
    with open(path, "r", encoding="utf-8") as f:
        return json.load(f)

packet = read_context_packet()

if packet:
    print(f"📦 컨텍스트 패킷 감지됨 (생성: {packet.get('generated_by', '알 수 없음')})")
    print(f"  테이블 유형: {packet.get('table_type')}")
    print(f"  날짜 컬럼 역할: {packet.get('time_column_role')}")
    print(f"  시간 간격: {packet.get('time_interval')}")
    print(f"  분석 목적: {packet.get('analysis_purpose')}")
    print(f"  의미 있는 결측 선언: {len(packet.get('meaningful_missing', []))}건")
    print(f"  도메인 노트: {len(packet.get('domain_notes', []))}건")
else:
    print("⚠️ context_packet.json 없음 — 수동으로 맥락을 확인합니다.")
```

---

## 컨텍스트 패킷 필드 소비 맵

각 하위 스킬이 패킷에서 어떤 필드를 사용하는지 정리한 표입니다.

| 필드 | data-preprocessing | time-series-analysis | ml-supervised | stats-basic |
|------|:-----------------:|:--------------------:|:-------------:|:-----------:|
| `table_type` | ✅ 보간 전략 결정 | ✅ 입력 유효성 검사 | — | — |
| `time_column_role` | ✅ 보간 여부 결정 | ✅ 인덱스 설정 | — | — |
| `time_interval` | ✅ 보간 방법 선택 | ✅ 예측 주기 설정 | — | — |
| `analysis_purpose` | ✅ 스케일링 여부 | — | ✅ 모델 선택 | — |
| `target_col` | ✅ 타깃 보호 | — | ✅ 필수 | — |
| `meaningful_missing` | ✅ Step 0 자동 적용 | — | — | — |
| `domain_notes` | ✅ 이상치 규칙 참고 | ✅ 특이 기간 참고 | — | — |

---

## 컨텍스트 검증

패킷 저장 전 확인하세요:

- [ ] `table_type`에 `_후보` 접미사가 없는가? (사용자 확인 완료)
- [ ] `time_column_role`이 실제 컬럼 특성과 일치하는가?
- [ ] `meaningful_missing`의 `strategy`가 모두 지정되어 있는가?
- [ ] `domain_notes`에 이상치·결측 관련 비즈니스 규칙이 포함되어 있는가?
- [ ] 반복 수행 데이터라면 `DATA_PATH`만 바꾸면 되도록 경로가 변수로 분리되어 있는가?
