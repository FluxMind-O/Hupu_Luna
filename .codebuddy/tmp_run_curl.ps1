$ErrorActionPreference = 'Continue'
# 复制 curl 参数文件到 ASCII 路径
Copy-Item 'c:\Users\马龙\Desktop\hupu\.codebuddy\tmp_curl_test.txt' 'D:\hupluna\curl_args.txt' -Force
Set-Location 'D:\hupluna'
# 系统自带 curl.exe 执行（TLS 指纹与 PowerShell 的 SChannel 不同）
$out = cmd /c 'curl.exe $(type curl_args.txt) 2>&1'
Write-Output $out
Remove-Item 'D:\hupluna\curl_args.txt' -Force -ErrorAction SilentlyContinue
