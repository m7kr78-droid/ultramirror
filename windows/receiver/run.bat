@echo off
chcp 65001 >nul
cd /d "%~dp0"

where python >nul 2>nul
if errorlevel 1 (
  echo Python غير مثبت. حمله من https://www.python.org/downloads/
  echo وتأكد إنك فعلت Add python.exe to PATH
  pause
  exit /b 1
)

python -m pip install -r requirements.txt
python main.py
if errorlevel 1 pause
