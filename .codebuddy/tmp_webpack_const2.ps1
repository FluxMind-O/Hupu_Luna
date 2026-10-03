$ErrorActionPreference = 'Continue'
$dir = "$env:TEMP\hupu_pc_js"
Get-ChildItem $dir -Filter *.js | ForEach-Object {
    $jsText = [System.IO.File]::ReadAllText($_.FullName, [System.Text.Encoding]::UTF8)
    # webpack 常量模块的另一种定义形式
    $patterns = @('p8\s*[:=]\s*function[^}]{0,80}', 'p8\s*[:=]\s*\(\)\s*=>\s*"[^"]{1,60}"', '"p8"[^}]{0,120}', 'p8:"?[^",}]{1,50}"?', 'M5:"?[^",}]{1,50}"?', 'Am:"?[^",}]{1,50}"?', 'XN:"?[^",}]{1,50}"?')
    foreach ($p in $patterns) {
        [regex]::Matches($jsText, $p) | ForEach-Object {
            $v = $_.Value
            if ($v -match 'hupu|hoopchina|http|\.com|\.cn|"/') { Write-Output ($_.Script? 0 : 0); Write-Output $v }
        }
    }
}
