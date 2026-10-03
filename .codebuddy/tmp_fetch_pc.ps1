$ErrorActionPreference = 'Stop'
$ua = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/126.0 Safari/537.36'

# 抓桌面端帖子页
Invoke-WebRequest -Uri 'https://bbs.hupu.com/642724300.html' -UserAgent $ua -OutFile "$env:TEMP\hupu_pc.html" -UseBasicParsing -TimeoutSec 25
$h = [System.IO.File]::ReadAllText("$env:TEMP\hupu_pc.html", [System.Text.Encoding]::UTF8)
Write-Output ("PC_PAGE_SIZE: " + $h.Length)

# 提取全部 JS
$js = [regex]::Matches($h, 'src="([^"]+\.js)"') | ForEach-Object { $_.Groups[1].Value } | Sort-Object -Unique
Write-Output ("PC_SCRIPTS: " + $js.Count)
$js | ForEach-Object { Write-Output $_ }
$js | Out-File "$env:TEMP\pc_js_list.txt" -Encoding utf8
