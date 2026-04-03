param([string]$DownloadUrl, [string]$FileName, [string]$InstallArgs = "/S")
$LogFile = "C:\IT_Support\SAM_Log.txt"
$TempPath = "$env:TEMP\$FileName"
try {
    Invoke-WebRequest -Uri $DownloadUrl -OutFile $TempPath -UseBasicParsing -ErrorAction Stop
    if (Test-Path $TempPath) {
        if ($FileName.EndsWith(".msi")) {
            $Args = if ($InstallArgs -ne "/S") { "/i `"$TempPath`" $InstallArgs" } else { "/i `"$TempPath`" /qn /norestart" }
            Start-Process msiexec.exe -ArgumentList $Args -WindowStyle Hidden -Wait
        } else {
            Start-Process $TempPath -ArgumentList $InstallArgs -WindowStyle Hidden -Wait
        }
        Remove-Item -Path $TempPath -Force -ErrorAction SilentlyContinue
        "$(Get-Date) - [Task_AppInstall] Installed $FileName" | Out-File $LogFile -Append
    }
} catch { "$(Get-Date) - Error: $($_.Exception.Message)" | Out-File $LogFile -Append }
