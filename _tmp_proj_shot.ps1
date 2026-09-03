$ErrorActionPreference = 'Continue'
$root = 'c:\Users\SOC-USER-PC-04\Desktop\Portfolio'
$src  = Join-Path $root 'index.html'
$chrome = 'C:\Program Files\Google\Chrome\Application\chrome.exe'
$html = Get-Content $src -Raw

$all = @('hero','about','skills','experience','projects','credentials','education','contact')
$target = 'projects'
$hide = ($all | Where-Object { $_ -ne $target } | ForEach-Object { "#$_" }) -join ','
$style = "<style>$hide{display:none !important}[data-reveal]{opacity:1 !important;transform:none !important}.hero{min-height:auto !important}</style>"

foreach ($w in @(1380, 900)) {
  $tmpHtml = Join-Path $root "_tmp_proj_$w.html"
  ($html -replace '</head>', ($style + '</head>')) | Set-Content -Path $tmpHtml -Encoding UTF8
  $png = Join-Path $env:TEMP "pf_proj_$w.png"
  Start-Process $chrome -ArgumentList '--headless=new','--disable-gpu','--no-sandbox','--hide-scrollbars',
    '--force-prefers-reduced-motion',"--window-size=$w,1700",'--virtual-time-budget=6000',
    "--user-data-dir=$env:TEMP\pf-proj-$w","--screenshot=$png",
    ('file:///' + ($tmpHtml -replace '\\','/')) -NoNewWindow -Wait 2>$null | Out-Null
  Copy-Item $png (Join-Path $root "_tmp_proj_$w.png") -Force
  Remove-Item $tmpHtml -Force
  "$w -> $((Get-Item (Join-Path $root "_tmp_proj_$w.png")).Length) bytes"
}
