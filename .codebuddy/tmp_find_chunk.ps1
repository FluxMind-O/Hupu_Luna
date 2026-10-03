$ErrorActionPreference = 'Continue'
$dir = "$env:TEMP\hupu_pc_js"
Get-ChildItem $dir -Filter *.js | ForEach-Object {
    $jsText = [System.IO.File]::ReadAllText($_.FullName, [System.Text.Encoding]::UTF8)
    # webpack chunk hash 映射: 数字id:"hash" 形式
    $patterns = @(
        '61636\s*:\s*"[a-f0-9]{8,24}"',
        '\{[0-9]{3,6}:"[a-f0-9]{8,24}"[^}]{0,400}\}'
    )
    foreach ($p in $patterns) {
        [regex]::Matches($jsText, $p) | ForEach-Object {
            Write-Output ("[" + $_.Name_1 + "]")
            Write-Output ($_.Value.Substring(0, [Math]::Min(500, $_.Value.Length)))
        }
    }
    # 也搜索 d.u 函数（chunk 文件名生成器）
    $idx = $jsText.IndexOf('".js"')
    while ($idx -ge 0 -and $idx -lt $jsText.Length) {
        $start = [Math]::Max(0, $idx - 600)
        $seg = $jsText.Substring($start, [Math]::Min(700, $jsText.Length - $start))
        if ($seg -match 'minor|chunkFilename|\.js"|miniCss') {
            Write-Output ("===== chunk-name-gen in " + $_.Name + " @ " + $idx + " =====")
            Write-Output $seg
        }
        $idx = $jsText.IndexOf('".js"', $idx + 5)
        if ($idx -gt 20000000) { break }
    }
}
