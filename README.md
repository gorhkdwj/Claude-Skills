# Claude 플러그인 마켓플레이스 (gorhk-cowork-marketplace)

여러 PC에서 동일한 Claude 스킬을 쓰기 위해 GitHub로 동기화하는 저장소입니다.
**마켓플레이스 = 플러그인들을 모아둔 GitHub 저장소(카탈로그)**. 다른 PC에서 이 저장소 주소만 한 번 등록하면, 안에 든 플러그인을 골라 설치할 수 있습니다.

이 저장소에는 **작성자 본인(김재천)이 직접 만든 플러그인만** 들어 있어 공개(Public)해도 됩니다.

---

## 1. 담긴 플러그인 (2개)

| 플러그인 | 제작자 | 설명 |
|---|---|---|
| **data-analytics-skills** | 김재천 | 데이터 분석 40개 스킬 (EDA·통계·ML·시각화·보고) |
| **job-application-coach** | 김재천 | 이력서·포트폴리오 맞춤 코칭 |

---

## 2. 폴더 구조

```
Claude-Skills/
├── .claude-plugin/
│   └── marketplace.json     ← 카탈로그(목록표). 이 파일이 핵심
├── plugins/                 ← 각 플러그인 폴더
│   ├── data-analytics-skills/
│   └── job-application-coach/
├── README.md
└── NOTICE.md
```

각 플러그인 폴더는 `.claude-plugin/plugin.json`(설명서) + `skills/`(실제 스킬)로 구성됩니다.

---

## 3. 다른 PC에서 설치하기

### A. Claude Code (CLI)
```
/plugin marketplace add gorhkdwj/Claude-Skills
/plugin install data-analytics-skills@gorhk-cowork-marketplace
/plugin install job-application-coach@gorhk-cowork-marketplace
```

### B. Claude Cowork (데스크톱 앱)
앱의 **설정 → Capabilities(기능)** 에서 마켓플레이스를 GitHub 주소로 추가한 뒤, 원하는 플러그인을 켜면 됩니다.

> 저장소가 **Private**이면 앱이 인증 없이 가져오지 못해 추가에 실패합니다. GitHub 주소로 추가하려면 저장소를 **Public**으로 두세요.

---

## 4. 내용 수정 후 반영하기

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

## 5. 자주 막히는 부분

- **`git push` 인증 오류** → GitHub는 비밀번호 대신 [Personal Access Token](https://github.com/settings/tokens) 또는 SSH 키를 씁니다.
- **설치 시 플러그인 이름** → `<플러그인이름>@<마켓플레이스이름>` 형식. 마켓플레이스 이름은 `gorhk-cowork-marketplace`(= marketplace.json의 `name`)입니다.
- **새 플러그인 추가** → `plugins/`에 폴더를 넣고, `marketplace.json`의 `plugins` 배열에 `{ "name": ..., "source": "./plugins/...", "description": ... }` 한 줄을 추가합니다.
