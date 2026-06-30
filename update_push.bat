@echo off
chcp 65001 >nul
setlocal
cd /d "%~dp0"
echo ============================================
echo    Claude-Skills  변경분 업로드 (update)
echo ============================================
echo.
where git >nul 2>nul || (echo [오류] git 미설치: https://git-scm.com/download/win & pause & exit /b 1)

echo [1/3] 변경 파일 확인...
git status --short

echo [2/3] 커밋...
git add -A
git commit -m "Add project-setup plugin (CLAUDE.md governance setup)"

echo [3/3] 푸시...
git push

echo.
if errorlevel 1 (echo [실패] 위 메시지를 확인하세요.) else (echo [완료] https://github.com/gorhkdwj/Claude-Skills 에서 확인)
echo.
pause
