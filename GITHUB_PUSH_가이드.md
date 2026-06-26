# GitHub 업로드 방법

스킬 모음은 이 폴더(`C:\Users\gorhk\Claude_Skills`)로 이미 옮겨졌습니다.
마지막 업로드(push)는 **본인 GitHub 로그인**이 필요해 직접 실행하셔야 합니다. 둘 중 하나만 하면 됩니다.

## 방법 A — 더블클릭 (가장 쉬움)
1. github.com 에서 빈 저장소 **Claude-Skills** 를 먼저 만듭니다. (이미 만들었다면 건너뜀)
   - *Add a README* 는 **체크 해제** 하세요. (비어 있어야 충돌이 없습니다)
   - 외부 플러그인이 포함돼 있으니 **Private** 권장 (NOTICE.md 참고)
2. 이 폴더의 **`push_to_github.bat`** 를 더블클릭합니다.
3. 처음이면 GitHub 로그인 창이 뜹니다 → 본인 계정으로 로그인하면 자동 업로드됩니다.

## 방법 B — 명령어 직접 입력
이 폴더에서 PowerShell 또는 Git Bash 를 열고:

```bash
git init
git add -A
git commit -m "Initial commit: Claude 스킬 마켓플레이스"
git branch -M main
git remote add origin https://github.com/gorhkdwj/Claude-Skills.git
git push -u origin main
```

> 폴더에 깨진 `.git` 폴더가 보이면 먼저 지우세요: PowerShell `Remove-Item -Recurse -Force .git`

## 업로드 후 — 다른 PC에서 설치
Claude Code:
```
/plugin marketplace add gorhkdwj/Claude-Skills
/plugin install data-analytics-skills@gorhk-cowork-marketplace
```
Cowork 앱: 설정 → Capabilities 에서 위 GitHub 주소로 마켓플레이스 추가.

## 참고
- git 미설치 시: https://git-scm.com/download/win
- 인증은 GitHub 비밀번호가 아니라 로그인 창 또는 [Personal Access Token](https://github.com/settings/tokens) 을 사용합니다.
