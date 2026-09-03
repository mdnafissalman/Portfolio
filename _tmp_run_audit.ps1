$ErrorActionPreference = 'Continue'
Add-Type -AssemblyName System.Web
$root = 'c:\Users\SOC-USER-PC-04\Desktop\Portfolio'
$src  = Join-Path $root 'index.html'
$dst  = Join-Path $root '_tmp_audit.html'

$html = Get-Content $src -Raw
$html = $html.Replace(
  '  <script src="assets/js/main.js"></script>',
  "  <script src=`"assets/js/main.js`"></script>`r`n  <script src=`"_tmp_audit.js`"></script>")
Set-Content -Path $dst -Value $html -Encoding UTF8

$chrome = 'C:\Program Files\Google\Chrome\Application\chrome.exe'
$url = 'file:///' + ($dst -replace '\\','/')

foreach ($vp in @('1440,1000','1024,900','768,900','390,844','320,700')) {
  $out = Join-Path $env:TEMP ("pf_audit_" + ($vp -replace ',','x') + ".html")
  $p = Start-Process $chrome -ArgumentList '--headless=new','--disable-gpu','--no-sandbox',
      "--window-size=$vp",'--virtual-time-budget=6000',
      "--user-data-dir=$env:TEMP\pf-audit-$($vp -replace ',','x')",'--dump-dom',$url `
      -RedirectStandardOutput $out -RedirectStandardError (Join-Path $env:TEMP 'pf_audit_err.txt') `
      -NoNewWindow -PassThru -Wait

  $dom = Get-Content $out -Raw
  $m = [regex]::Match($dom, '<pre id="audit-report">(.*?)</pre>', 'Singleline')
  "########## viewport $vp (exit $($p.ExitCode)) ##########"
  if ($m.Success) {
    [System.Web.HttpUtility]::HtmlDecode($m.Groups[1].Value)
  } else {
    'no report'
  }
}
