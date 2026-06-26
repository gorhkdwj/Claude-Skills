# Claude Cowork 플러그인 마켓플레이스 (gorhk-cowork-marketplace)

여러 PC에서 동일한 Claude 스킬/플러그인을 쓰기 위해 GitHub로 동기화하는 저장소입니다.
**마켓플레이스 = 플러그인들을 모아둔 GitHub 저장소(카탈로그)**. 다른 PC에서 이 저장소 주소만 한 번 등록하면, 안에 든 플러그인을 골라 설치할 수 있습니다.

---

## 1. 담긴 플러그인 (7개)

| 플러그인 | 제작자 | 설명 |
|---|---|---|
| **data-analytics-skills** | 김재천(본인) | 데이터 분석 40개 스킬 (EDA·통계·ML·시각화·보고) |
| **job-application-coach** | 김재천(본인) | 이력서·포트폴리오 맞춤 코칭 |
| data | Anthropic | SQL·탐색·시각화·대시보드 |
| finance | Anthropic | 분개·재무제표·변동분석 |
| productivity | Anthropic | 작업관리·일정·메모리 |
| pdf-viewer | Anthropic | PDF 보기·주석·서명 |
| slack-by-salesforce | Salesforce | 공식 Slack 연동 |

> 저작권 구분과 공개/비공개 권장사항은 `NOTICE.md` 참고.

---

## 2. 폴더 구조

```
claude-skills-marketplace/
├── .claude-plugin/
│   └── marketplace.json     ← 카탈로그(목록표). 이 파일이 핵심
├── plugins/                 ← 각 플러그인 폴더
│   ├── data-analytics-skills/
│   ├── job-application-coach/
│   └── ... (총 7개)
├── README.md
├── NOTICE.md
└── .gitignore
```

각 플러그인 폴더는 `.claude-plugin/plugin.json`(설명서) + `skills/`(실제 스킬)로 구성됩니다.

---

## 3. GitHub에 올리기 (최초 1회)

### 준비
- [Git 설치](https://git-scm.com/download/win) 후, GitHub에서 **비어 있는 새 저장소**를 하나 만듭니다.
  (외부 플러그인이 포함되어 있으니 **Private** 권장 — NOTICE.md 참고)

### 명령어 (Windows PowerShell 또는 Git Bash)
이 폴더 안에서 실행하세요. `<USERNAME>`과 `<REPO>`는 본인 것으로 바꿉니다.

```bash
cd claude-skills-marketplace

git init
git add .
git commit -m "Initial: Claude 스킬 마켓플레이스"
git branch -M main
git remote add origin https://github.com/<USERNAME>/<REPO>.git
git push -u origin main
```

> 이미 git이 설정돼 있다면 첫 줄(`git init`)부터가 아니라 `git remote add`부터 해도 됩니다.

---

## 4. 다른 PC에서 설치하기

### A. Claude Code (CLI)
Claude Code 안에서 슬래시 명령으로:

```
/plugin marketplace add <USERNAME>/<REPO>
/plugin install data-analytics-skills@gorhk-cowork-marketplace
/plugin install job-application-coach@gorhk-cowork-marketplace
```

> 비공개 저장소면 그 PC의 git이 GitHub 계정으로 인증돼 있어야 합니다.

### B. Claude Cowork (데스크톱 앱)
앱의 **설정 → Capabilities(기능)** 에서 마켓플레이스를 GitHub 주소로 추가한 뒤,
원하는 플러그인을 켜면 됩니다. (메뉴 명칭은 앱 버전에 따라 다를 수 있습니다.)

---

## 5. 내용 수정 후 반영하기

플러그인을 고치거나 새 스킬을 추가했다면, 이 폴더에서:

```bash
git add .
git commit -m "스킬 추가/수정"
git push
```

다른 PC에서는 최신본을 받아옵니다:

```
/plugin marketplace update gorhk-cowork-marketplace
```

---

## 6. 자주 막히는 부분

- **`git push`에서 인증 오류** → GitHub는 비밀번호 대신 [Personal Access Token](https://github.com/settings/tokens) 또는 SSH 키를 씁니다.
- **설치 시 플러그인 이름** → `<플러그인이름>@<마켓플레이스이름>` 형식. 마켓플레이스 이름은 `gorhk-cowork-marketplace`(= marketplace.json의 `name`)입니다.
- **새 플러그인을 마켓에 추가** → `plugins/`에 폴더를 넣고, `marketplace.json`의 `plugins` 배열에 `{ "name": ..., "source": "./plugins/...", "description": ... }` 한 줄을 추가하면 됩니다.
