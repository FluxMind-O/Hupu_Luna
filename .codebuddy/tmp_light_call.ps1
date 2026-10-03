$ErrorActionPreference = 'Continue'
$dir = "$env:TEMP\hupu_pc_js"
Get-ChildItem $dir -Filter *.js | Where-Object { $_.Name -ne 'reply-editor.js' } | ForEach-Object {
    $jsText = [System.IO.File]::ReadAllText($_.FullName, [System.Text.Encoding]::UTF8)
    $idx = $jsText.IndexOf('unlight')
    while ($idx -ge 0) {
        $start = [Math]::Max(0, $idx - 450)
        $len = [Math]::Min(1000, $jsText.Length - $start)
        Write-Output ("===== " + $_.Name + " @ " + $idx + " =====")
        Write-Output ($jsText.Substring($start, $len))
        $idx = $jsText.IndexOf('unlight', $idx + 400)
    }
}
