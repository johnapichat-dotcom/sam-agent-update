param(
    [string]$TargetApp
)

if (-not $TargetApp) { exit }

# กวาดหาทั้ง 64-bit และ 32-bit Registry
$RegPaths = @(
    "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*",
    "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*"
)

# ค้นหาโปรแกรมจาก Keyword
$App = Get-ItemProperty $RegPaths -ErrorAction SilentlyContinue | Where-Object { $_.DisplayName -match $TargetApp } | Select-Object -First 1

if ($App -and $App.UninstallString) {
    $UninstStr = $App.UninstallString -replace '"', ''
    
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

    # สั่งรันและรอจนกว่าจะลบเสร็จ
    Start-Process -FilePath $Exe -ArgumentList $Args -WindowStyle Hidden -Wait
}
