$h = [System.IO.File]::ReadAllText("$env:TEMP\hupu_detail.html", [System.Text.Encoding]::UTF8)
$m = [regex]::Match($h, '"fid"\s*:\s*"?(\d+)')
if ($m.Success) { Write-Output ("FID: " + $m.Groups[1].Value) } else { Write-Output "FID NOT FOUND" }
# 顺带列出 basicInfo 附近字段
$m2 = [regex]::Match($h, '"basicInfo".{0,600}')
if ($m2.Success) { Write-Output $m2.Value }
