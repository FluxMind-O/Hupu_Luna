$ErrorActionPreference = 'Continue'
$dir = "$env:TEMP\hupu_pc_js"
Get-ChildItem $dir -Filter *.js | ForEach-Object {
    $jsText = [System.IO.File]::ReadAllText($_.FullName, [System.Text.Encoding]::UTF8)
    # 搜索 webpack 常量定义: p8:"..." M5:"..." Am:"..." b$:"..." r8:
    $patterns = @('p8:"[^"]{1,60}"', 'M5:"[^"]{1,60}"', 'Am:"[^"]{1,60}"', 'b\$:"[^"]{1,60}"', 'r8:[^,}]{1,30}', 'pcmapi[A-Za-z0-9_/\.\-]{0,60}')
    foreach ($p in $patterns) {
        [regex]::Matches($jsText, $p) | ForEach-Object {
            Write-Output ($_.Value)
        }
    }
}