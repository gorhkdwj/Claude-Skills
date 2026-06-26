# DA Skills Plugin

데이터 분석가를 위한 Claude Cowork 플러그인.
분석 경로 가이드부터 전처리, 머신러닝, 보고까지 전체 DA 워크플로우를 커버하는 40개 스킬 모음.

---

## 현재 버전

| 항목 | 내용 |
|------|------|
| 버전 | v0.6.0 |
| 스킬 수 | 40개 (코어 11개 + 분석 10개 + 보고 6개 + 지원 15개) |
| 작성자 | 김재천 |
| 플러그인 파일 | `data-analytics-skills-v0.6.0.plugin` |
| 플로우맵 | `da-skills-flowmap.html` |

---

## 플러그인 구조

### Phase별 코어 스킬 (메인 파이프라인)

```
Phase 0   시작·통합        analysis-path-guide   multi-file-merge
Phase 1   컬럼탐색          column-navigator
Phase 2   탐색적 분석       programmatic-eda
Phase 3   품질검증          data-quality-audit
Phase 3.5 데이터 전처리     data-preprocessing
Phase 3.7 피처 엔지니어링   feature-engineering
Phase 4   분석·모델링       ml-supervised         ml-unsupervised
                            stats-basic           stats-advanced
                            time-series-analysis  cohort-analysis
                            funnel-analysis       segmentation-analysis
                            ab-test-analysis      root-cause-investigation
Phase 5   보고·커뮤니케이션  insight-synthesis     data-narrative-builder
                            visualization-builder executive-summary-generator
                            analysis-documentation dashboard-specification
```

### 지원 스킬 (어느 단계에서든 사용 가능)

| 카테고리 | 스킬 |
|----------|------|
| 계획·문서화 | analysis-planning, analysis-assumptions-log, analysis-qa-checklist, analysis-retrospective |
| 데이터 이해 | schema-mapper, data-catalog-entry, semantic-model-builder, metric-reconciliation |
| 인사이트·커뮤니케이션 | impact-quantification, technical-to-business-translator, context-packager, stakeholder-requirements-gathering, methodology-explainer |
| SQL·쿼리 | query-validation, sql-to-business-logic |
| 협업·리뷰 | peer-review-template |
| 비즈니스 | business-metrics-calculator |

---

## 7가지 분석 경로

| 경로 | 목적 | 주요 스킬 흐름 |
|------|------|---------------|
| A | 지도학습 분류 | EDA → 전처리 → 피처 → ml-supervised |
| B | 지도학습 회귀 | EDA → 전처리 → 피처 → ml-supervised (회귀) |
| C | 비지도학습 군집화 | EDA → 전처리 → ml-unsupervised → segmentation |
| D | 원인 분석 | EDA → root-cause → stats-basic → narrative |
| E | 시계열 분석 | EDA → time-series → cohort → visualization |
| F | 비교·검증 | EDA → stats-basic → ab-test → methodology |
| G | 완전 탐색 | path-guide → merge → column → EDA → (재진입) |

---

## 설계 원칙

### 1. AI 제안 + 사용자 검증 모델
모든 스킬은 "AI가 통계적 근거로 제안하고, 사용자가 도메인 지식으로 확정"하는 구조를 따릅니다.

### 2. context_packet.json 연결 채널
`analysis-path-guide` → `context-packager` → 하위 스킬로 구조화된 맥락이 전달됩니다.

| 필드 | 역할 |
|------|------|
| `table_type` | 독립 관측치 / 시계열_집계 / 이벤트_로그 |
| `time_column_role` | 인덱스 / 피처 / 없음 |
| `time_interval` | 규칙적 / 불규칙 / 해당없음 |
| `analysis_purpose` | 예측 / 탐색 / 검정 / 추이 |
| `target_col` | 예측 대상 컬럼명 |
| `meaningful_missing` | 의미있는 결측 컬럼별 전략 |
| `recommended_path` | 추천 분석 경로 |
| `domain_notes` | 도메인 특이사항 |

### 3. MEANINGFUL_MISSING 시스템
비즈니스 의미가 있는 결측값(시험 미응시 = NaN, 구매금액 없음 = 0 등)을 통계 기반 대체와 분리해 처리합니다.

| 전략 | 의미 | 예시 |
|------|------|------|
| `flag` | 결측 여부를 이진 플래그로 추가 | 시험 응시 여부 |
| `category` | 별도 범주로 채움 | "해당없음" |
| `zero` | 0으로 대체 | 미구매 고객의 구매금액 |
| `keep` | 결측 그대로 유지 | 이후 처리 예정 |
| `impute` | 통계 기반 대체 허용 | 일반 수치 결측 |

### 4. 2단계 실행 구조 (코어 7개 스킬)
코딩 초보자도 반복 실행이 쉽도록 설계된 구조입니다.

```
1단계 (최초 1회): Claude와 대화 → Config Block 초안 확정
2단계 (매 실행): 노트북 실행 → Config Block 상단만 수정
```

**Config Block 예시 (ml-supervised):**
```python
DATA_PATH    = "데이터_파일_경로.csv"  # ← 매 실행마다 변경
TARGET_COL   = "target"
FEATURE_COLS = None
TEST_SIZE    = 0.2
RANDOM_STATE = 42
DOMAIN_NOTES = []
```

**드리프트 탐지**: 첫 실행 시 기준 스키마를 `{skill}_baseline_schema.json`으로 저장.
이후 실행 시 컬럼·타입·카테고리 변화를 자동 감지하여 경고합니다.

### 5. 출력물 표준 (3종 세트)
코드 생성 스킬의 출력물은 항상 3종입니다:
- `{skill-name}.ipynb` — 실행결과 내장 Jupyter Notebook
- `{skill-name}_result.csv` — 처리 완료 데이터 또는 요약 테이블
- `{skill-name}_report.md` — 처리 내역·근거·다음 단계 한국어 리포트

### 6. load_data() 표준 패턴
- 지원 형식: CSV / TSV / Excel / JSON / Parquet
- 인코딩 폴백: UTF-8 → CP949 (한국어 Windows 환경 대응)

### 7. 토큰 효율 원칙
Claude는 데이터 파일 자체를 읽지 않습니다. 진단 코드 실행 결과(요약 통계)만 컨텍스트로 수신합니다.
VS Code + 로컬 Python 환경에서 가장 효율적으로 동작합니다.

---

## 개발 히스토리

### v0.1.0 — 초기 구축
- 기존 35개 스킬 통합 (외부 소스 기반)
- 전체 YAML frontmatter 한글 번역 (bilingual: 한국어|영어 description)
- 기술적 문제 해결:
  - CRLF → LF 변환 (Windows 파일의 YAML 파서 오류 해결)
  - `ml-supervised` UTF-8 절단 복구 (16806 bytes, 마지막 2 bytes 손상)
- `.claude-plugin` 구조로 패키징, Cowork 사용자 지정 탭 등록

### v0.2.0 — 워크플로우 완성
신규 스킬 5개 추가 및 플로우맵 시각화:

| 신규 스킬 | Phase | 역할 |
|-----------|-------|------|
| `multi-file-merge` | 0 | 10개+ 파일 컬럼 구조 파악 → 조인 키 탐지 → 병합 |
| `column-navigator` | 1 | 수십~수백 컬럼 자동 분류 → 핵심 컬럼 확정 |
| `data-preprocessing` | 3.5 | 결측·이상치·인코딩·스케일링 |
| `feature-engineering` | 3.7 | 파생변수 생성·선택·중요도 |
| `analysis-path-guide` | 0 | 초보자 맞춤 분석 경로 추천 |

플로우맵 시각화 (`da-skills-flowmap.html`) 추가.

### v0.3.0 — P1 텍스트 수정
- stats-basic: 통계 검정 전 전처리 범위 명시 (결측 처리만 선택적으로 필요)
- root-cause-investigation: 진입 조건 유연화 (지표 이상 감지 시 언제든 진입 가능)
- stats-advanced: 회귀 전 다중공선성 확인 안내 추가

### v0.4.0 — P2 컨텍스트 패킷 + MEANINGFUL_MISSING
- **analysis-path-guide**: 경로 확정 후 `context_packet.json` 자동 생성
- **context-packager**: DA Skills 공식 패킷 채널로 완전 재작성. 8개 필드 스키마 + 소비 스킬 매핑 테이블
- **data-preprocessing**: MEANINGFUL_MISSING Step 0 추가 (flag/category/zero/keep/impute 5가지 전략)
- **query-validation**: 보일러플레이트 → 완전한 워크플로 (안티패턴 7종·복잡도 스코어·비즈니스 로직 체크)
- 40개 스킬 전수 검사: Output 섹션 vs 출력 템플릿 불일치 전부 수정

### v0.5.0 — P3 context_packet 하위 스킬 연동
- **data-preprocessing**: context_packet 읽어 `use_interpolation`·`skip_encoding_scaling`·`protect_target_col` 플래그 자동 설정
  - 시계열_집계 + 인덱스 + 규칙 간격일 때만 보간 적용
  - 원인분석/AB검정 목적 시 인코딩·스케일링 생략
- **time-series-analysis**: context_packet에서 DATE_COL·TARGET_COL·FREQ 자동 로드. Config Block 추가

### v0.6.0 — P4 2단계 실행 구조 (현재)
코어 7개 스킬에 Config Block + 드리프트 탐지 적용, 3개 스킬 완전 재작성:

| 스킬 | 작업 내용 |
|------|-----------|
| `ml-supervised` | Config Block + check_schema_drift() |
| `ml-unsupervised` | Config Block + check_schema_drift() |
| `stats-basic` | Config Block + check_schema_drift() |
| `stats-advanced` | Config Block + check_schema_drift() |
| `programmatic-eda` | 보일러플레이트 → 8단계 완전 재작성 + Config Block + 차트 4종 |
| `data-quality-audit` | 보일러플레이트 → 6단계 완전 재작성 + BUSINESS_RULES 딕셔너리 + 품질 점수 A~F |
| `cohort-analysis` | 미완성 → 7단계 완전 재작성 + Config Block + 히트맵·추이 차트 |

---

## 논의 및 결정 기록

### feature-engineering → stats 경로 연결 (미추가 결정)

**결론: 공식 경로 연결 추가하지 않음**
- 데이터를 보고 피처를 만든 후 그 피처로 통계 검정 시 p-hacking 위험
- p-value 0.05 기준, 50개 피처 검정 시 우연히 유의한 결과 2~3개 발생
- 대신 stats-basic에 정규성을 위한 로그 변환, stats-advanced에 다중공선성 확인 내장

### time-series 전처리 연결 (context_packet으로 해결)

**문제**: datetime 탐지 → 자동 보간 로직의 한계:
- datetime 컬럼이 있어도 독립 관측치일 수 있음 (예: 사용자 가입일)
- 불규칙 간격에서 행 인덱스 기반 보간은 시간 간격 무시
- 예측 모델 미래 구간 보간 시 데이터 누수 발생

**해결**: context_packet의 `table_type` + `time_column_role` + `time_interval` 3가지 필드 조합으로 보간 여부 결정. datetime 감지 기반 자동 처리 → 의도 기반 분기 처리로 전환.

### 의미적 결측값 처리 (MEANINGFUL_MISSING으로 해결)

**문제**: 통계 임계값(30%)으로만 트리거되는 is_missing 플래그는 비즈니스 의미(시험 미응시 = NaN 등)를 놓침.

**해결**: MEANINGFUL_MISSING 딕셔너리로 컬럼별 전략 선언. 통계 기반 대체 이전 Step 0에서 먼저 처리. AI는 후보 탐지만, 최종 판단은 사용자.

### 2단계 구조와 반복 실행 효율성

**결론**: Config Block 분리 설계로 해결.
- 2단계 대화는 첫 실행(또는 데이터 구조 변경 시)에만 필요
- 이후 반복 실행은 DATA_PATH 한 줄만 변경
- `check_schema_drift()`가 컬럼·타입·카테고리 변화를 자동 감지해 필요할 때만 경고

---

## 파일 목록

```
data-analytics-skills/
├── .claude-plugin/
│   └── plugin.json          (v0.6.0)
├── skills/
│   ├── analysis-path-guide/      Phase 0  분석 경로 추천 + context_packet 생성
│   ├── multi-file-merge/         Phase 0  다중 파일 병합
│   ├── column-navigator/         Phase 1  컬럼 구조 탐색
│   ├── programmatic-eda/         Phase 2  탐색적 분석 ★완전 재작성 (v0.6)
│   ├── data-quality-audit/       Phase 3  품질 검증 ★완전 재작성 (v0.6)
│   ├── data-preprocessing/       Phase 3.5 데이터 전처리 + MEANINGFUL_MISSING
│   ├── feature-engineering/      Phase 3.7 피처 엔지니어링
│   ├── ml-supervised/            Phase 4  지도학습 + Config Block (v0.6)
│   ├── ml-unsupervised/          Phase 4  비지도학습 + Config Block (v0.6)
│   ├── stats-basic/              Phase 4  기초 통계 검정 + Config Block (v0.6)
│   ├── stats-advanced/           Phase 4  심화 통계 검정 + Config Block (v0.6)
│   ├── time-series-analysis/     Phase 4  시계열 분석 + context_packet 연동
│   ├── cohort-analysis/          Phase 4  코호트 분석 ★완전 재작성 (v0.6)
│   ├── funnel-analysis/          Phase 4  퍼널 분석
│   ├── segmentation-analysis/    Phase 4  세그먼트 분석
│   ├── ab-test-analysis/         Phase 4  A/B 테스트
│   ├── root-cause-investigation/ Phase 4  원인 분석
│   ├── insight-synthesis/        Phase 5  인사이트 정리
│   ├── data-narrative-builder/   Phase 5  스토리텔링
│   ├── visualization-builder/    Phase 5  시각화
│   ├── executive-summary-generator/ Phase 5 임원 요약
│   ├── analysis-documentation/   Phase 5  전체 문서화
│   ├── dashboard-specification/  Phase 5  대시보드 설계
│   ├── analysis-planning/        지원     계획 수립
│   ├── analysis-assumptions-log/ 지원     가정 추적
│   ├── analysis-qa-checklist/    지원     품질 보증
│   ├── analysis-retrospective/   지원     회고
│   ├── schema-mapper/            지원     DB 스키마
│   ├── data-catalog-entry/       지원     메타데이터
│   ├── semantic-model-builder/   지원     시맨틱 계층
│   ├── metric-reconciliation/    지원     지표 검증
│   ├── impact-quantification/    지원     영향 정량화
│   ├── technical-to-business-translator/ 지원 번역
│   ├── context-packager/         지원     컨텍스트 패키징 (공식 채널)
│   ├── stakeholder-requirements-gathering/ 지원 요구사항
│   ├── methodology-explainer/    지원     방법론 설명
│   ├── query-validation/         지원     SQL 검증 ★워크플로 완성 (v0.4)
│   ├── sql-to-business-logic/    지원     SQL 변환
│   ├── peer-review-template/     지원     동료 리뷰
│   └── business-metrics-calculator/ 지원 비즈니스 지표
└── README.md
```

---

## 남은 개선 제안

| 항목 | 내용 |
|------|------|
| `feature-engineering` Config Block | P4 대상 7개 스킬 중 유일하게 Config Block·드리프트 탐지 미적용 |
| funnel → ab-test 명시적 연결 | 퍼널 병목 발견 후 해당 단계를 A/B 테스트하는 흐름 안내 추가 |
| schema-mapper 경로 G 분기 | SQL/DB 환경에서 multi-file-merge 대신 schema-mapper를 Phase 0로 사용하는 DB 전용 분기 |
| business-metrics-calculator 위치 | 지원 스킬이지만 EDA 직후(Phase 2.5) 또는 보고 직전(Phase 4.5) 배치가 더 자연스러울 수 있음 |
| 실전 테스트 | 실제 CSV 데이터로 각 스킬 노트북 실행하여 버그 수정 |

---

## 배포

```bash
# 패키징
cd data-analytics-skills
zip -r ../data-analytics-skills-v0.6.0.plugin . -x "*.DS_Store" -x "__pycache__/*"
```

**설치**: Cowork → 사용자 지정 탭 → 플러그인 추가 → `.plugin` 파일 선택
**업데이트 시**: 기존 플러그인 제거 후 새 파일로 재설치 필요
