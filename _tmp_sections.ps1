$ErrorActionPreference = 'Continue'
$root = 'c:\Users\SOC-USER-PC-04\Desktop\Portfolio'
$src  = Join-Path $root 'index.html'
$chrome = 'C:\Program Files\Google\Chrome\Application\chrome.exe'
$html = Get-Content $src -Raw

$all = @('hero','about','skills','experience','projects','credentials','education','contact')

foreach ($target in $all) {
  $hide = ($all | Where-Object { $_ -ne $target } | ForEach-Object { "#$_" }) -join ','
  # Hide the other sections and neutralise reveal animations so the shot is stable
  $style = "<style>$hide{display:none !important}[data-reveal]{opacity:1 !important;transform:none !important}.hero{min-height:auto !important}</style>"
  $tmpHtml = Join-Path $root "_tmp_sec_$target.html"
  ($html -replace '</head>', ($style + '</head>')) | Set-Content -Path $tmpHtml -Encoding UTF8

  $png = Join-Path $env:TEMP "pf_sec_$target.png"
  Start-Process $chrome -ArgumentList '--headless=new','--disable-gpu','--no-sandbox','--hide-scrollbars',
    '--force-prefers-reduced-motion','--window-size=1380,1500','--virtual-time-budget=6000',
    "--user-data-dir=$env:TEMP\pf-sec-$target","--screenshot=$png",
    ('file:///' + ($tmpHtml -replace '\\','/')) -NoNewWindow -Wait 2>$null | Out-Null
  Copy-Item $png (Join-Path $root "_tmp_sec_$target.png") -Force
  Remove-Item $tmpHtml -Force
  "$target -> $((Get-Item (Join-Path $root "_tmp_sec_$target.png")).Length) bytes"
}
