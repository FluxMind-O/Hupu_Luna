$ErrorActionPreference = 'Continue'
$dir = "$env:TEMP\hupu_pc_js"
New-Item -ItemType Directory -Force -Path $dir | Out-Null
Get-ChildItem $dir -Filter *.js | Remove-Item -Force

$base = 'https://w1.hoopchina.com.cn'
$headers = @{ Referer = 'https://bbs.hupu.com/' }
Get-Content "$env:TEMP\pc_js_list.txt" | Where-Object { $_ -match '_next/static/chunks' } | ForEach-Object {
    $name = ($_ -split '/')[-1]
    $url = "https:" + $_
    try {
        Invoke-WebRequest -Uri $url -OutFile "$dir\$name" -UseBasicParsing -TimeoutSec 25 -Headers $headers -UserAgent 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) Chrome/126.0'
    } catch {
        Write-Output ("FAIL: " + $name + " - " + $_.Exception.Message)
    }
}
Write-Output ("DOWNLOADED: " + (Get-ChildItem $dir -Filter *.js).Count)

# 枚举 API 路径（聚焦写操作）
$found = @{}
Get-ChildItem $dir -Filter *.js | ForEach-Object {
    $jsText = [System.IO.File]::ReadAllText($_.FullName, [System.Text.Encoding]::UTF8)
    $patterns = @(
        '[a-z0-9\-\.]+\.hupu\.com/[A-Za-z0-9_/\.\-]{3,80}',
        '"/api/[A-Za-z0-9_/\-]{2,80}"',
        "'/api/[A-Za-z0-9_/\-]{2,80}'",
        'bbs-pc-svc[A-Za-z0-9_/\-]{0,80}'
    )
    foreach ($p in $patterns) {
        [regex]::Matches($jsText, $p) | ForEach-Object { $found[$_.Value] = $_.Value }
    }
}
# 过滤出疑似写操作/接口相关的
Write-Output ("ALL: " + $found.Count)
$found.Keys | Sort-Object | Where-Object { $_ -match 'api|light|reply|fav|collect|vote|comment|post|thread|user|login' } | ForEach-Object { Write-Output $_ }
