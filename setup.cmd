@echo off
where pwsh >nul 2>nul
if %ERRORLEVEL% neq 0 (
    echo PowerShell not found. Installing...
    :: Prefer winget if available
    where winget >nul 2>nul
    if %ERRORLEVEL% equ 0 (
        winget install --id Microsoft.Powershell --source winget -e --accept-source-agreements --accept-package-agreements
    ) else (
        echo winget not found. Please install PowerShell manually: https://aka.ms/powershell
        exit /b 1
    )
)

:: Now call the PowerShell script
pwsh -File setup-odoo.ps1 %*
