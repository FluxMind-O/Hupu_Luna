$ErrorActionPreference = 'Continue'
$jsText = [System.IO.File]::ReadAllText("$env:TEMP\hupu_pc_js\reply-editor.js", [System.Text.Encoding]::UTF8)
# 提取全部接口定义与提交参数
$patterns = @(
    'baseURL:"[^"]{0,120}"',
    'method:"[a-z]+"',
    'content:[^,}]{1,60}',
    'tid:[^,}]{1,40}',
    'pid:[^,}]{1,40}',
    'puid:[^,}]{1,40}',
    'joinId[^,}]{0,50}',
    'type:[^,}]{1,30}'
)
$out = @{}
foreach ($p in $patterns) {
    [regex]::Matches($jsText, $p) | ForEach-Object { $out[$_.Index.ToString()] = $_.Value }
}
# 按位置排序输出，形成上下文
$sorted = $out.GetEnumerator() | Sort-Object { [int]$_.Key }
foreach ($kv in $sorted) { Write-Output ("@" + $kv.Key + "  " + $kv.Value) }
