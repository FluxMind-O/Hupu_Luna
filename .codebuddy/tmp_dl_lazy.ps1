$ErrorActionPreference = 'Continue'
$dir = "$env:TEMP\hupu_pc_js"
$base = 'https://w1.hoopchina.com.cn/games/static/bbs-pc-web/_next/static/chunks/'
$headers = @{ Referer = 'https://bbs.hupu.com/' }
$ua = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) Chrome/126.0'
$chunks = @(
    '673f057a.a7eb2cd27c1228b4.js',
    '05978e0a00a428c8.js',
    'bab823fa.cc45d10464998f61.js',
    'cd5f5a368040fa0a.js',
    'f7e91afdb6493831.js',
    '1c6f97795888cb1c.js',
    '348fa0d31320d915.js',
    '90b3b69d6928c990.js',
    'fc83e031.d90bb1e3692d04ce.js',
    '3db446d1e9c11d47.js',
    '7d9bb5f9.7a8ebcb6542248a5.js',
    '69364278.6ba3552338db5dea.js'
)
foreach ($c in $chunks) {
    try {
        Invoke-WebRequest -Uri ($base + $c) -OutFile "$dir\lazy_$c" -UseBasicParsing -TimeoutSec 25 -Headers $headers -UserAgent $ua
        Write-Output ("OK: " + $c)
    } catch {
        Write-Output ("FAIL: " + $c)
    }
}
Write-Output ("TOTAL: " + (Get-ChildItem $dir -Filter 'lazy_*').Count)
