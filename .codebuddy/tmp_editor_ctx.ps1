$ErrorActionPreference = 'Continue'
$jsText = [System.IO.File]::ReadAllText("$env:TEMP\hupu_pc_js\reply-editor.js", [System.Text.Encoding]::UTF8)
foreach ($pos in @(13800, 21000, 23600)) {
    $start = [Math]::Max(0, $pos - 200)
    $len = [Math]::Min(1400, $jsText.Length - $start)
    Write-Output ("===== @" + $pos + " =====")
    Write-Output ($jsText.Substring($start, $len))
}
