$h = [System.IO.File]::ReadAllText("$env:TEMP\hupu_pc.html", [System.Text.Encoding]::UTF8)
# 提取 __NEXT_DATA__ JSON
$s = $h.IndexOf('id="__NEXT_DATA__"')
if ($s -lt 0) { Write-Output 'NO NEXT_DATA'; exit }
$s = $h.IndexOf('>', $s) + 1
$e = $h.IndexOf('</script>', $s)
$json = $h.Substring($s, $e - $s)
# 顶层结构（截取前 3000 字符看 pageProps 键布局）
Write-Output ("LEN: " + $json.Length)
$head = $json.Substring(0, [Math]::Min(2600, $json.Length))
Write-Output $head
