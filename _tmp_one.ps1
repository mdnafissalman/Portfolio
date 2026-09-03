$ErrorActionPreference = 'Continue'
$root = 'c:\Users\SOC-USER-PC-04\Desktop\Portfolio'
$src  = Join-Path $root 'index.html'
$chrome = 'C:\Program Files\Google\Chrome\Application\chrome.exe'
$html = Get-Content $src -Raw
$all = @('hero','about','skills','experience','projects','credentials','education','contact')

# $args[0] = section id, $args[1] = 'dark' or 'light', $args[2] = viewport
$target = $args[0]
$theme  = if ($args[1]) { $args[1] } else { 'dark' }
$vp     = if ($args[2]) { $args[2] } else { '1380,1500' }

$hide = ($all | Where-Object { $_ -ne $target } | ForEach-Object { "#$_" }) -join ','
$style = "<style>$hide{display:none !important}[data-reveal]{opacity:1 !important;transform:none !important}.hero{min-height:auto !important}</style>"
$script = "<script>document.documentElement.setAttribute('data-theme','$theme');</script>"

$tmpHtml = Join-Path $root "_tmp_one.html"
($html -replace '</head>', ($style + '</head>')) -replace '</body>', ($script + '</body>') |
  Set-Content -Path $tmpHtml -Encoding UTF8

$png = Join-Path $env:TEMP "pf_one.png"
Start-Process $chrome -ArgumentList '--headless=new','--disable-gpu','--no-sandbox','--hide-scrollbars',
  '--force-prefers-reduced-motion',"--window-size=$vp",'--virtual-time-budget=6000',
  "--user-data-dir=$env:TEMP\pf-one","--screenshot=$png",
  ('file:///' + ($tmpHtml -replace '\\','/')) -NoNewWindow -Wait 2>$null | Out-Null

Copy-Item $png (Join-Path $root '_tmp_one.png') -Force
Remove-Item $tmpHtml -Force
"$target / $theme / $vp -> $((Get-Item (Join-Path $root '_tmp_one.png')).Length) bytes"
