$ErrorActionPreference = 'Continue'
$cookie = 'smidV2=20261003153515731a475711e8af3645ba315851326435002eee653f3098af0; _c_WBKFRo=1yfXtpxHjb4ENbemb4ZAWiGrtZ9srb85dd1bXo0w; _nb_ioWEgULi=; _HUPUSSOID=67f71f90-295a-44e0-a471-2eb5d9c129ce; u=110153686|6L+Z5Y+q6ISa5piv5qC85YWw5p2w6Lip55qE|ba13|4aeb05c3dcaa9947d6d558f1661b1935|4ecf72c7ea50407d|aHVwdV9kOGExMjVhNTk2ODdmMmRj; us=4536819eda6f679fbacc1a2e491709ec854a715ec86c348f4169a0415d8d3a787d0656a50784bcad810ea728b9411c64fdc9deca94e78c32f3fd2b49c8c5ad3d; ua=20586356; _CLT=00376064be821b71351c003dda774e37; tfstk=g6Kt35OdCXcMUzoIwl0h2dk2lIDHD2vNJCJ7msfglBdp3IEgjijGlt1p1PfcIK1vMBfUots6iIFvsBAAuA5cGsdDhFDnq0vwQiSfMbmoq0KANfATG1_jhk6NUvX_KKeAeiSjZXVqQdcV0Cc5N7sXdvBc3tNXG1wIpt6Ocl_bfyNCTtsfc16bdM6lHtZfhiMpd6WfcsOfcvICTtsfGIsj9DDcOr5bDItKXhKImDZ_fHBOWsEcxoLX2ubcNHfLcDKdBS1WC6Ebc_yt6ZppIfEyKG-MwTAiAldJCUOXPBiLXw86pnQy05MCcZ1hRhOb1P6RX1QWfww-UG7XJHIMfjzyKpC1yMYn8fbcXCLPaNgETIpdsItOR5hhiUvHfwdStkdVkFOOdgsPu3xJ6FPlwt4spvU4uN6EzJIQ5gic46BdZA30ur7nP9CopvU4uN6Fp_DH2rzV-41..'
$ua = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/154.0.0.0 Safari/537.36 Edg/154.0.0.0'

function Try-Req($label, $method, $url, $ref, $extra) {
    $h = @{
        'User-Agent'      = $ua
        'Cookie'          = $cookie
        'Accept'          = 'application/json, text/plain, */*'
        'Accept-Language' = 'zh-CN,zh;q=0.9'
        'sec-ch-ua'       = '"Chromium";v="154", "Microsoft Edge";v="154", "Not A(Brand";v="99"'
        'sec-ch-ua-mobile' = '?0'
        'sec-ch-ua-platform' = '"Windows"'
        'sec-fetch-dest'  = 'empty'
        'sec-fetch-mode'  = 'cors'
        'sec-fetch-site'  = 'same-origin'
    }
    if ($ref) { $h['Referer'] = $ref }
    if ($extra) { foreach ($k in $extra.Keys) { $h[$k] = $extra[$k] } }
    try {
        $r = Invoke-WebRequest -Uri $url -Method $method -Headers $h -UseBasicParsing -TimeoutSec 20
        return "[$label] HTTP $($r.StatusCode) => " + $r.Content.Substring(0, [Math]::Min(500, $r.Content.Length))
    } catch {
        $resp = $_.Exception.Response
        if ($resp) {
            try {
                $body = New-Object System.IO.StreamReader($resp.GetResponseStream())
                $txt = $body.ReadToEnd()
                return "[$label] $($_.Exception.Message) => " + $txt.Substring(0, [Math]::Min(400, $txt.Length))
            } catch { return "[$label] $($_.Exception.Message)" }
        }
        return "[$label] $($_.Exception.Message)"
    }
}

Write-Output '===== A: m.hupu.com/api/v2/user (real UA) ====='
Try-Req 'user' 'GET' 'https://m.hupu.com/api/v2/user' 'https://m.hupu.com/' $null
Write-Output ''
Write-Output '===== B: collect (POST, real UA) ====='
Try-Req 'collect' 'POST' 'https://bbs.hupu.com/api/v2/threads/642724300/collect' 'https://bbs.hupu.com/642724300.html' @{ 'Content-Type' = 'application/json' }
Write-Output ''
Write-Output '===== C: un-collect (DELETE, restore) ====='
Try-Req 'uncollect' 'DELETE' 'https://bbs.hupu.com/api/v2/threads/642724300/collect' 'https://bbs.hupu.com/642724300.html' $null
