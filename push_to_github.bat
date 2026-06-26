@echo off
chcp 65001 >nul
setlocal
cd /d "%~dp0"

echo ============================================
echo    Claude-Skills  GitHub 업로드
echo ============================================
echo.

where git >nul 2>nul
if errorlevel 1 (
  echo [오류] git이 설치되어 있지 않습니다.
  echo        https://git-scm.com/download/win 에서 설치 후 다시 실행하세요.
  pause & exit /b 1
)

echo [1/6] 기존 .git 정리...
if exist ".git" rmdir /s /q ".git"

echo [2/6] 저장소 초기화...
git init
git config user.name "김재천"
git config user.email "gorhkdwj@gmail.com"
git config core.autocrlf false

echo [3/6] 파일 추가 및 커밋...
git add -A
git commit -m "Initial commit: Claude 스킬 마켓플레이스 (7 plugins / 66 skills)"

echo [4/6] 기본 브랜치 main 설정...
git branch -M main

echo [5/6] 원격 연결...
git remote remove origin 1>nul 2>nul
git remote add origin https://github.com/gorhkdwj/Claude-Skills.git

echo [6/6] GitHub 푸시 (로그인 창이 뜨면 본인 GitHub 계정으로 인증)...
git push -u origin main

echo.
if errorlevel 1 (
  echo [실패] 위 메시지를 확인하세요.
  echo   - "Repository not found" : github.com 에서 빈 저장소 Claude-Skills 를 먼저 만드세요 ^(Add README 체크 해제^)
  echo   - 인증 실패 : GitHub 로그인 / 토큰을 확인하세요
) else (
  echo [완료] https://github.com/gorhkdwj/Claude-Skills 에서 확인하세요.
)
echo.
pause
