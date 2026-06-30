---
name: project-setup
description: >
  새 프로젝트를 시작하거나 초기 구조를 잡을 때 쓰는 프로젝트 운영 체계 셋업 스킬.
  "새 프로젝트 시작", "프로젝트 셋업", "프로젝트 초기 세팅", "프로젝트 구조 잡아줘",
  "운영 체계 만들어줘", "CLAUDE.md 만들어줘", "project setup", "bootstrap project",
  "scaffold project" 같은 요청에는 반드시 이 스킬을 사용한다. 폴더와 git 상태를 먼저
  확인하고 기존 파일을 덮어쓰지 않으며, CLAUDE.md(작업 헌법)와
  Worklog/Decisionlog/Troubleshootinglog, docs(기획·요구사항 계약·구현·검증),
  src/tests/tools/out 구조를 제안·생성한다. 프로젝트 목적·사용자·산출물·마감·수준을
  질문해 채우고, 바로 구현하지 않고 1차 운영 구조와 계획부터 보고한다. 문서화·검증·보안·
  로그 기록 규칙을 프로젝트 내내 강제하고 싶을 때도 사용한다.
---

# 프로젝트 셋업 (운영 체계 스캐폴딩)

이 스킬은 새 프로젝트를 시작할 때 결과물만 급하게 만드는 대신, 문제 정의·판단·구현·검증·트러블슈팅을 구조적으로 관리하는 운영 체계를 먼저 깐다. 트리거되면 폴더 구조를 확인하고, 운영 파일을 제안·생성하고, 프로젝트 범위를 질문한 뒤, 구현을 시작하기 전에 1차 계획을 보고한다.

이 스킬의 산출물은 두 층이다. 첫째는 지금 셋업 절차를 수행하는 것, 둘째는 `CLAUDE.md`라는 "작업 헌법"을 프로젝트에 남겨 이후 모든 세션이 같은 규칙을 따르게 하는 것이다. 그래서 셋업이 끝나도 규칙이 프로젝트에 계속 살아 있다.

## 핵심 태도 (항상 적용)

- 바로 구현부터 시작하지 않는다. 먼저 현재 폴더와 기존 파일을 확인한다.
- 사용자가 만든 기존 파일·변경사항을 함부로 덮어쓰지 않는다.
- 실행하지 않은 테스트나 확인하지 않은 사실을 완료했다고 말하지 않는다.
- 결론을 먼저 말하고, 근거·세부는 뒤에 설명한다.
- 기술 용어는 처음 나올 때 비전문가도 이해하게 한 줄로 설명한다.
- 불확실한 내용은 단정하지 말고 `확인 필요`로 남긴다.

## 셋업 절차 (이 순서로 진행)

### 0단계 · 현재 상태 파악
- 현재 작업 폴더의 파일/폴더를 나열한다.
- git 저장소 여부와 상태를 확인한다(있으면 `git status`).
- 아래 운영 파일 중 이미 있는 것을 식별한다. 있으면 내용을 읽고 보고하되 **덮어쓰지 않는다.**

### 1단계 · 프로젝트 정보 수집
다음 항목을 사용자에게 묻는다(가능하면 객관식·입력 질문 도구 사용). 이미 대화에서 답이 나온 항목은 다시 묻지 않는다.

- 프로젝트 이름
- 프로젝트 목적(무엇을 만들고 싶은지)
- 주요 사용자(누가 쓰는지)
- 최종 산출물(앱 / 분석 보고서 / 플러그인 / 자동화 도구 / 논문 구현 / 포트폴리오 등)
- 마감·제약(마감일, 기술 제한, 제출 형식 등)
- 현재 사용자 수준(초급 / 중급 / 전공자 / 비전공자 등)
- 원하는 진행 방식(예: 초급자도 이해하게, 실무형 문서화, 검증 중시 등)

### 2단계 · 운영 파일 목록 제안
아래 표준 구조를 제시한다. 프로젝트 성격상 필요 없는 폴더는 억지로 만들지 말고 **왜 생략해도 되는지 설명**한다. (예: 데이터가 없으면 `data/`, 배포가 없으면 일부 생략)

### 3단계 · 운영 파일 생성
- 이 스킬의 `assets/` 템플릿을 복사해 만든다. 생성 시 `[프로젝트 이름]` 등 placeholder를 1단계 답으로 치환한다.
- **이미 있는 파일은 건너뛰고** 그 사실을 보고한다(덮어쓰기 금지).
- 템플릿 매핑:
  - `assets/CLAUDE.md.template` → `CLAUDE.md`  (작업 헌법; 가장 중요)
  - `assets/README.md.template` → `README.md`
  - `assets/Worklog.md.template` → `Worklog.md`
  - `assets/Decisionlog.md.template` → `Decisionlog.md`
  - `assets/Troubleshootinglog.md.template` → `Troubleshootinglog.md`
  - `assets/gitignore.template` → `.gitignore`
  - `assets/docs/project-plan.md.template` → `docs/project-plan.md`
  - `assets/docs/requirements-contract.md.template` → `docs/requirements-contract.md`
  - `assets/docs/implementation-plan.md.template` → `docs/implementation-plan.md`
  - `assets/docs/validation-plan.md.template` → `docs/validation-plan.md`
- 빈 폴더 `src/`, `tests/`, `tools/`, `out/`, `docs/references/`도 만든다(필요 없는 것은 생략·설명). 빈 폴더 유지가 필요하면 `.gitkeep`을 둔다.
- 생성 후 각 파일을 한 줄로 요약 보고한다.

### 4단계 · 1차 보고 (구현 전 정지)
- **여기서 구현을 시작하지 않는다.**
- 전체 운영 구조와 1차 계획(가장 작은 성공 단위부터)을 아래 "완료 보고 형식"으로 보고하고 사용자 확인을 받는다.

## 표준 구조

```text
project-root/
├── CLAUDE.md                  # AI가 항상 따라야 할 작업 규칙(헌법)
├── README.md                  # 외부 사용자가 이해·실행하는 문서
├── Worklog.md                 # 실제 작업 이력
├── Decisionlog.md             # 중요한 판단과 선택지 기록
├── Troubleshootinglog.md      # 오류·원인·해결·재발 방지
├── docs/
│   ├── project-plan.md
│   ├── requirements-contract.md
│   ├── implementation-plan.md
│   ├── validation-plan.md
│   └── references/
├── src/                       # 실제 실행 코드
├── tests/                     # 테스트 코드와 fixture
├── tools/                     # 개발·검증·빌드 보조 스크립트
├── out/                       # 로컬 실행 결과·임시 산출물(Git 제외)
└── .gitignore
```

## 운영 규칙 요약 (상세 형식은 생성된 CLAUDE.md 참조)

프로젝트 진행 내내 적용한다. 전체 형식과 세부는 `CLAUDE.md`에 있다.

- **Worklog**: 주요 사용자 요청이 끝날 때마다 `W-ID`로 기록.
- **Decisionlog**: 방향을 바꾸거나 이후에 영향을 주는 **중요한 결정만** `D-ID`로. 사소한 건 Worklog만.
- **Troubleshootinglog**: 실제 오류·실패·검증 실패가 생기면 `T-ID`로. 반복 시 새 ID 전에 기존 ID 확인.
- 구현 전 `docs/requirements-contract.md`로 입력·출력·지표·수식·판정·완료 기준을 먼저 고정한다. 기준이 바뀌면 코드보다 문서를 먼저 갱신한다.
- 검증은 정직하게. 실패 테스트를 지우거나 완화하지 않고 원인을 고친다. 검증 못 한 부분은 `미검증 범위`로 보고.
- 보안: API 키·비밀번호·토큰·실제 개인/계좌정보를 코드·문서·로그·테스트에 넣지 않는다. 원본 데이터는 수정하지 않는다.
- 문서화: README엔 실제 구현된 기능만 쓴다. 기획·계약·코드·테스트·README가 서로 모순되지 않게 관리한다.
- Git: 주요 단계마다 변경 확인 → 불필요 파일 제외 → 검증 → commit → push. `out/`·로그·비밀정보·임시 산출물은 올리지 않는다.

## 완료 보고 형식

```text
완료했습니다.

- 수행한 작업:
- 변경 파일:
- 검증 결과:
- 기록:
  - Worklog:
  - Decisionlog:
  - Troubleshootinglog:
- 남은 작업:
- 한계 또는 미검증 범위:
- Git 상태:
```

이 스킬을 실행한 직후의 1차 보고도 이 형식을 따른다. 검증 항목에는 "셋업만 수행, 구현 미착수"를 명시하고, 실행하지 않은 검증을 완료라고 말하지 않는다.
