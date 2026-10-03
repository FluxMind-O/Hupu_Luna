$ErrorActionPreference = 'Stop'
$h = [System.IO.File]::ReadAllText("$env:TEMP\hupu_detail.html", [System.Text.Encoding]::UTF8)
# 提取详情页全部 JS chunk
$chunks = [regex]::Matches($h, '(?:src="|href=")(//w1\.hoopchina\.com\.cn[^"]+\.js)"') | ForEach-Object { $_.Groups[1].Value } | Sort-Object -Unique
$chunks | Out-File "$env:TEMP\chunks_list.txt" -Encoding utf8
Write-Output ("CHUNKS: " + $chunks.Count)
$chunks | ForEach-Object { Write-Output $_ }

# 下载全部 chunk 到临时目录
$dir = "$env:TEMP\hupu_js"
New-Item -ItemType Directory -Force -Path $dir | Out-Null
foreach ($c in $chunks) {
    $name = ($c -split '/')[-1]
    $url = "https:" + $c
    try {
        Invoke-WebRequest -Uri $url -OutFile "$dir\$name" -UseBasicParsing -TimeoutSec 20
    } catch {
        Write-Output ("FAIL: " + $name)
    }
}

# 在全部 JS 中搜索 API 路径模式
$patterns = @('api/v2/[A-Za-z0-9_/\-]+', 'api/v[0-9]/[A-Za-z0-9_/\-]+', '"/[a-z]+/[a-z\-]+/light[A-Za-z0-9_/\-]*"', 'm\.hupu\.com/api/[A-Za-z0-9_/\-]+')
$found = @{}
Get-ChildItem $dir -Filter *.js | ForEach-Object {
    $js = [System.IO.File]::ReadAllText($_.FullName, [System.Text.Encoding]::UTF8)
    foreach ($p in $patterns) {
        [regex]::Matches($js, $p) | ForEach-Object { $found[$_.Value] = $_.Value }
    }
}
Write-Output ("APIS: " + $found.Count)
$found.Keys | Sort-Object | ForEach-Object { Write-Output $_ }
