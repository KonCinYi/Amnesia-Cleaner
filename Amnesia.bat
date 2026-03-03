# 2>nul & @cls & @echo off
# 2>nul & chcp 65001 >nul
# 2>nul & fltmc >nul 2>&1 || (powershell -Command "Start-Process '%~f0' -Verb RunAs" & exit /b)
# 2>nul & powershell -NoProfile -ExecutionPolicy Bypass -Command "Invoke-Command -ScriptBlock ([ScriptBlock]::Create([IO.File]::ReadAllText('%~f0')))"
# 2>nul & pause & exit /b

# ==============================================================================
# НАЧАЛО СКРИПТА POWERSHELL
# ==============================================================================
Clear-Host
Write-Host "=======================================================" -ForegroundColor Cyan
Write-Host "  ГЛОБАЛЬНАЯ ОЧИСТКА РАБОЧИХ СТАНЦИЙ (TEMP + БРАУЗЕРЫ) " -ForegroundColor Cyan
Write-Host "=======================================================" -ForegroundColor Cyan
Write-Host ""

$usersPath = "C:\Users"
$excludeFolders = @("Public", "Default", "Default User", "All Users", "Administrator")
$userProfiles = Get-ChildItem -Path $usersPath -Directory -Force | Where-Object { $_.Name -notin $excludeFolders }

# Порог безопасности для Temp (файлы старше 5 дней)
$limitDate = (Get-Date).AddDays(-5)

# Массив всех возможных путей к браузерам (относительно корня папки пользователя C:\Users\Имя)
$browserPaths = @(
    # --- Семейство Chromium (Local AppData) ---
    "AppData\Local\Google\Chrome\User Data\Default",
    "AppData\Local\Google\Chrome\User Data\Profile*",
    "AppData\Local\Microsoft\Edge\User Data\Default",
    "AppData\Local\Microsoft\Edge\User Data\Profile*",
    "AppData\Local\Yandex\YandexBrowser\User Data\Default",
    "AppData\Local\Yandex\YandexBrowser\User Data\Profile*",
    "AppData\Local\BraveSoftware\Brave-Browser\User Data\Default",
    "AppData\Local\Vivaldi\User Data\Default",
    "AppData\Local\Chromium\User Data\Default",
    "AppData\Local\Mail.Ru\Atom\User Data\Default",
    "AppData\Local\Comodo\Dragon\User Data\Default",
    "AppData\Local\AVAST Software\Browser\User Data\Default",
    "AppData\Local\AVG\Browser\User Data\Default",
    "AppData\Local\CCleaner Browser\User Data\Default",
    "AppData\Local\CentBrowser\User Data\Default",
    "AppData\Local\Slimjet\User Data\Default",
    "AppData\Local\360Chrome\Chrome\User Data\Default",
    "AppData\Local\UCBrowser\User Data_i18n\Default",
    "AppData\Local\Epic Privacy Browser\User Data\Default",
    
    # --- Семейство Opera (Roaming AppData) ---
    "AppData\Roaming\Opera Software\Opera Stable",
    "AppData\Roaming\Opera Software\Opera GX Stable",
    "AppData\Roaming\Opera Software\Opera Neon\User Data\Default",
    
    # --- Семейство Firefox / Mozilla (Roaming AppData) ---
    # Удаляем корень настроек, чтобы браузер корректно сбросился к заводским
    "AppData\Roaming\Mozilla\Firefox",
    "AppData\Local\Mozilla\Firefox",
    "AppData\Roaming\Waterfox",
    "AppData\Roaming\Moonchild Productions\Pale Moon"
)

foreach ($user in $userProfiles) {
    Write-Host "[*] Пользователь: $($user.Name)" -ForegroundColor Yellow
    
    # ==========================================
    # 1. МЯГКАЯ ОЧИСТКА TEMP (Только старые файлы)
    # ==========================================
    $tempPath = Join-Path -Path $user.FullName -ChildPath "AppData\Local\Temp"
    if (Test-Path $tempPath) {
        Write-Host "    -> Очистка Temp (только файлы старше 5 дней, папки не трогаем)..." -ForegroundColor DarkGray
        
        # Ключ -File гарантирует, что папки останутся целыми
        Get-ChildItem -Path $tempPath -Recurse -File -Force -ErrorAction SilentlyContinue | 
            Where-Object { $_.LastWriteTime -lt $limitDate } |
            Remove-Item -Force -ErrorAction SilentlyContinue
    }

    # ==========================================
    # 2. ЖЕСТКИЙ СБРОС ВСЕХ НАЙДЕННЫХ БРАУЗЕРОВ
    # ==========================================
    foreach ($bPath in $browserPaths) {
        $fullBrowserPath = Join-Path -Path $user.FullName -ChildPath $bPath
        
        # Test-Path понимает звездочки (Profile*), поэтому сработает даже на доп. профили
        if (Test-Path $fullBrowserPath) {
            # Вытаскиваем имя браузера для красивого вывода в консоль
            $browserName = $bPath.Split('\')[2]
            if ($bPath -match "Mozilla|Opera") { $browserName = $bPath.Split('\')[3] }
            
            Write-Host "    -> [СБРОС] Найден браузер: $browserName" -ForegroundColor Red
            
            # Уничтожаем профиль
            Remove-Item -Path $fullBrowserPath -Recurse -Force -ErrorAction SilentlyContinue
        }
    }
    Write-Host ""
}

Write-Host "=======================================================" -ForegroundColor Green
Write-Host " УСПЕХ! Мусор удален, браузеры сброшены, система цела." -ForegroundColor Green
Write-Host "=======================================================" -ForegroundColor Green
