@echo off
echo ==========================================
echo Starting Vaani Seva - Python ML Backend
echo ==========================================
cd backend

if not exist "venv" (
    echo Creating Python Virtual Environment...
    python -m venv venv
)

echo Activating Virtual Environment...
call venv\Scripts\activate.bat

echo Installing dependencies...
pip install -r requirements.txt

echo Starting Flask Server...
python app.py
pause
