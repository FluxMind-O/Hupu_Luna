$ErrorActionPreference = 'Continue'
$dir = "$env:TEMP\hupu_pc_js"
Get-ChildItem $dir -Filter *.js | ForEach-Object {
    $jsText = [System.IO.File]::ReadAllText($_.FullName, [System.Text.Encoding]::UTF8)
    # 找所有 baseURL 里含 reply/thread/post 的接口定义
    $patterns = @(
        'baseURL:"[^"]{0,100}reply[^"]{0,60}"',
        'baseURL:"[^"]{0,100}(post|Post)[^"]{0,60}"',
        'baseURL:"[^"]{0,80}(comment|send|create|add|publish)[^"]{0,60}"'
    )
    foreach ($p in $patterns) {
        [regex]::Matches($jsText, $p) | ForEach-Object {
            Write-Output ("[" + $_.BaseInput.Length.ToString() + "] " + $_.Index.ToString() + " " + $_.Value)
        }
    }
}
