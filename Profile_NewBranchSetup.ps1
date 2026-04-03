# 1. ถอนโปรแกรมเก่า
Start-Process cmd.exe -ArgumentList "/c msiexec.exe /x {รหัสโปรแกรมเก่า} /qn" -Wait
# 2. โหลดและลงโปรแกรมใหม่
Invoke-WebRequest -Uri "https://domain.com/newpos.exe" -OutFile "$env:TEMP\newpos.exe"
Start-Process "$env:TEMP\newpos.exe" -ArgumentList "/S" -Wait
# 3. เคลียร์ Temp
Remove-Item -Path "$env:TEMP\*" -Recurse -Force -ErrorAction SilentlyContinue
# 4. บังคับรีสตาร์ทตัวเอง
Restart-Computer -Force
