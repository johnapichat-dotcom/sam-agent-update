# รับค่า Argument และตัดช่องว่างส่วนเกิน
$AppName = $args[0].Trim()
$LogFile = "C:\IT_Support\SAM_Task_Log.txt"

"$(Get-Date) - [Task: Uninstall] Initiated for: $AppName" | Out-File $LogFile -Append

# ค้นหาโปรแกรมจาก Registry (ครอบคลุมทั้ง 32-bit และ 64-bit)
$RegPaths = @("HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*", "HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*")
$App = Get-ItemProperty $RegPaths -ErrorAction SilentlyContinue | Where-Object { $_.DisplayName -match [regex]::Escape($AppName) } | Select-Object -First 1

if ($App) {
    "$(Get-Date) - [Task: Uninstall] Found app: $($App.DisplayName)" | Out-File $LogFile -Append
    
    # 1. เช็คว่าผู้พัฒนาเตรียมคำสั่ง Silent ไว้ให้แล้วหรือไม่
    if ($App.QuietUninstallString) {
        $UninstallCmd = $App.QuietUninstallString
    }
    # 2. กรณีเป็นไฟล์ MSI (เช่น LibreOffice)
    elseif ($App.UninstallString -match "msiexec") {
        # เปลี่ยน /I (Install) เป็น /X (Uninstall) และเติม /qn (Quiet No UI) /norestart
        $UninstallCmd = $App.UninstallString -replace "(?i)/I", "/X"
        $UninstallCmd += " /qn /norestart"
    }
    # 3. กรณีเป็นไฟล์ EXE ทั่วไป (เช่น FusionInventory)
    else {
        $UninstallCmd = $App.UninstallString
        # แนบ Switch มาตรฐานที่ EXE ส่วนใหญ่ใช้ (/S สำหรับ NSIS, /VERYSILENT สำหรับ Inno Setup)
        $UninstallCmd += " /S /VERYSILENT /quiet /norestart"
    }

    "$(Get-Date) - [Task: Uninstall] Executing: $UninstallCmd" | Out-File $LogFile -Append

    # สั่งประมวลผลคำสั่งแบบซ่อนหน้าต่างและรอจนกว่าจะเสร็จ
    try {
        $Process = Start-Process cmd.exe -ArgumentList "/c `"$UninstallCmd`"" -Wait -WindowStyle Hidden -PassThru
        "$(Get-Date) - [Task: Uninstall] Process completed. Exit Code: $($Process.ExitCode)" | Out-File $LogFile -Append
    } catch {
        "$(Get-Date) - [Task: Uninstall] Execution failed: $($_.Exception.Message)" | Out-File $LogFile -Append
    }

} else {
    "$(Get-Date) - [Task: Uninstall] ERROR: App matching '$AppName' not found." | Out-File $LogFile -Append
}
