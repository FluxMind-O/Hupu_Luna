$ErrorActionPreference = 'Continue'
$cookie = 'smidV2=20261003153515731a475711e8af3645ba315851326435002eee653f3098af0; _c_WBKFRo=1yfXtpxHjb4ENbemb4ZAWiGrtZ9srb85dd1bXo0w; _nb_ioWEgULi=; _HUPUSSOID=67f71f90-295a-44e0-a471-2eb5d9c129ce; u=110153686|6L+Z5Y+q6ISa5piv5qC85YWw5p2w6Lip55qE|ba13|4aeb05c3dcaa9947d6d558f1661b1935|4ecf72c7ea50407d|aHVwdV9kOGExMjVhNTk2ODdmMmRj; us=4536819eda6f679fbacc1a2e491709ec854a715ec86c348f4169a0415d8d3a787d0656a50784bcad810ea728b9411c64fdc9deca94e78c32f3fd2b49c8c5ad3d; ua=20586356; _CLT=00376064be821b71351c003dda774e37; tfstk=g6Kt35OdCXcMUzoIwl0h2dk2lIDHD2vNJCJ7msfglBdp3IEgjijGlt1p1PfcIK1vMBfUots6iIFvsBAAuA5cGsdDhFDnq0vwQiSfMbmoq0KANfATG1_jhk6NUvX_KKeAeiSjZXVqQdcV0Cc5N7sXdvBc3tNXG1wIpt6Ocl_bfyNCTtsfc16bdM6lHtZfhiMpd6WfcsOfcvICTtsfGIsj9DDcOr5bDItKXhKImDZ_fHBOWsEcxoLX2ubcNHfLcDKdBS1WC6Ebc_yt6ZppIfEyKG-MwTAiAldJCUOXPBiLXw86pnQy05MCcZ1hRhOb1P6RX1QWfww-UG7XJHIMfjzyKpC1yMYn8fbcXCLPaNgETIpdsItOR5hhiUvHfwdStkdVkFOOdgsPu3xJ6FPlwt4spvU4uN6EzJIQ5gic46BdZA30ur7nP9CopvU4uN6Fp_DH2rzV-41..'
$ua = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/130.0.0.0 Safari/537.36'
$headers = @{
    'User-Agent'  = $ua
    'Cookie'      = $cookie
    'Referer'     = 'https://bbs.hupu.com/'
    'Accept'      = 'application/json, text/html, */*'
}

Write-Output '===== TEST 1: GET /api/v2/user (login-state read) ====='
try {
    $r = Invoke-WebRequest -Uri 'https://bbs.hupu.com/api/v2/user' -Headers $headers -UseBasicParsing -TimeoutSec 20
    Write-Output ("HTTP " + $r.StatusCode)
    Write-Output ($r.Content.Substring(0, [Math]::Min(600, $r.Content.Length)))
} catch {
    Write-Output ("FAIL: " + $_.Exception.Message)
    if ($_.Exception.Response) {
        $body = New-Object System.IO.StreamReader($_.Exception.Response.GetResponseStream())
        Write-Output ("BODY: " + $body.ReadToEnd().Substring(0, 400))
    }
}

Write-Output ''
Write-Output '===== TEST 2: PC detail page puid (login-state via SSR) ====='
try {
    $r2 = Invoke-WebRequest -Uri 'https://bbs.hupu.com/642724300.html' -Headers $headers -UseBasicParsing -TimeoutSec 20
    $m = [regex]::Match($r2.Content, '"user"\s*:\s*\{[^}]*"puid"\s*:\s*"(\d+)"')
    if ($m.Success) { Write-Output ("pageProps user.puid = " + $m.Groups[1].Value) } else { Write-Output "puid pattern not found (user.puid=0 => not logged in)" }
} catch {
    Write-Output ("FAIL: " + $_.Exception.Message)
}
