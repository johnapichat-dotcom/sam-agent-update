param(
    [string]$TargetApp
)

$LogFile = "C:\IT_Support\SAM_Log.txt"

Function Write-SAMLog {
    param([string]$Message)
    $Timestamp = Get-Date -Format "MM/dd/yyyy HH:mm:ss"
    $LogEntry = "$Timestamp - [UninstallTask] $Message"
    try {
        $LogEntry | Out-File -FilePath $LogFile -Append -Encoding UTF8
    } catch { }
}

if (-not $TargetApp) { 
    Write-SAMLog "Failed: No target application specified in Payload."
    exit 
}

Write-SAMLog "Initiated search for target: '$TargetApp'"

# กวาดหาทั้ง 64-bit และ 32-bit Registry
$RegPaths = @(
    "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*",
    "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*"
)

# ค้นหาโปรแกรมจาก Keyword
$App = Get-ItemProperty $RegPaths -ErrorAction SilentlyContinue | Where-Object { $_.DisplayName -match $TargetApp } | Select-Object -First 1

if ($App -and $App.UninstallString) {
    $AppName = $App.DisplayName
    $UninstStr = $App.UninstallString -replace '"', ''
    
    Write-SAMLog "Match found: '$AppName'. Base String: $UninstStr"
    
    # ดึงเฉพาะพาธไฟล์ exe ออกมา
    $Exe = $UninstStr.Split(' ')[0]
    
    # วิเคราะห์และเลือก Silent Switch ให้เหมาะสม
    if ($App.UninstallString -match "msiexec") {
        $Args = "/x $($App.PSChildName) /qn /norestart"
        $Exe = "msiexec.exe"
    } elseif ($Exe -match "unins000.exe" -or $Exe -match "setup.exe") {
        $Args = "/VERYSILENT /SUPPRESSMSGBOXES /NORESTART"
    } else {
        $Args = "/S"
    }

    Write-SAMLog "Executing removal: $Exe $Args"

    # สั่งรันและรอจนกว่าจะลบเสร็จ พร้อมจับ Exit Code
    try {
        $Process = Start-Process -FilePath $Exe -ArgumentList $Args -WindowStyle Hidden -Wait -PassThru
        Write-SAMLog "Process finished. Exit Code: $($Process.ExitCode)"
    } catch {
        Write-SAMLog "Execution Error: $($_.Exception.Message)"
    }
} else {
    Write-SAMLog "Target '$TargetApp' not found in system Registry. Process aborted."
}
