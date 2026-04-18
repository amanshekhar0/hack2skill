@echo off
echo ==========================================
echo Starting Ngrok Tunnel for Aman
echo ==========================================
echo This will expose your local Flask server (port 5000) to the internet.
echo Make sure you have Ngrok installed and authenticated on Windows.
echo Check the ngrok URL generated or use the custom domain.
echo.

ngrok http --domain=volatilisable-demetrice-unchambered.ngrok-free.dev 5000
pause
