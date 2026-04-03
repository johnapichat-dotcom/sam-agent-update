param([string]$AppName)
$LogFile = "C:\IT_Support\SAM_Log.txt"
try {
    $Paths = @("HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*", "HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*")
    $App = Get-ItemProperty $Paths -ErrorAction SilentlyContinue | Where-Object { $_.DisplayName -match [regex]::Escape($AppName) } | Select-Object -First 1
    if ($App) {
        if ($App.QuietUninstallString) { Start-Process cmd.exe -ArgumentList "/c $($App.QuietUninstallString)" -WindowStyle Hidden -Wait }
        elseif ($App.UninstallString) {
            $Cmd = $App.UninstallString -replace "/I", "/X" -replace "msiexec.exe", "msiexec.exe /qn /norestart"
            if ($Cmd -notmatch "/qn" -and $Cmd -notmatch "/S" -and $Cmd -notmatch "/quiet") { $Cmd += " /S" }
            Start-Process cmd.exe -ArgumentList "/c $Cmd" -WindowStyle Hidden -Wait
        }
        "$(Get-Date) - [Task_AppUninstall] Uninstalled $AppName" | Out-File $LogFile -Append
    }
} catch { "$(Get-Date) - Error: $($_.Exception.Message)" | Out-File $LogFile -Append }
