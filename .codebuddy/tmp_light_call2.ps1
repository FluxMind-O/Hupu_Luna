$ErrorActionPreference = 'Continue'
$dir = "$env:TEMP\hupu_pc_js"
Get-ChildItem $dir -Filter 'lazy_*.js' | ForEach-Object {
    $jsText = [System.IO.File]::ReadAllText($_.FullName, [System.Text.Encoding]::UTF8)
    foreach ($kw in @('ight', 'collect', 'createReply')) {
        $idx = $jsText.IndexOf($kw)
        $seen = @{}
        while ($idx -ge 0) {
            $start = [Math]::Max(0, $idx - 300)
            $len = [Math]::Min(700, $jsText.Length - $start)
            $seg = $jsText.Substring($start, $len)
            # 只输出含 API 调用特征或参数构造的片段
            if ($seg -match 'light|collect|createReply|tid|pid|puid' -and $seg -match 'function|=>|\.bind|\(') {
                $key = [Math]::Floor($idx / 250)
                if (-not $seen.ContainsKey($key)) {
                    $seen[$key] = 1
                    Write-Output ("===== " + $_.Name + " @ " + $idx + " [" + $kw + "] =====")
                    Write-Output $seg
                }
            }
            $idx = $jsText.IndexOf($kw, $idx + $kw.Length)
        }
    }
}
