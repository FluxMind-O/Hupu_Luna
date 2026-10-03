$ErrorActionPreference = 'Continue'
$dir = "$env:TEMP\hupu_pc_js"
Get-ChildItem $dir -Filter *.js | ForEach-Object {
    $jsText = [System.IO.File]::ReadAllText($_.FullName, [System.Text.Encoding]::UTF8)
    foreach ($kw in @('unlight', 'api/v2/light', 'passport.hupu.com', 'api/v2/threads')) {
        $idx = $jsText.IndexOf($kw)
        while ($idx -ge 0) {
            $start = [Math]::Max(0, $idx - 350)
            $len = [Math]::Min(800, $jsText.Length - $start)
            Write-Output ("===== " + $_.Name + " @ " + $idx + " [" + $kw + "] =====")
            Write-Output ($jsText.Substring($start, $len))
            $idx = $jsText.IndexOf($kw, $idx + $kw.Length)
            if ($idx -gt 5000000) { break }
        }
    }
}
