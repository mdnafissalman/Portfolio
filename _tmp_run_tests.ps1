$ErrorActionPreference = 'Continue'
Add-Type -AssemblyName System.Web
$root = 'c:\Users\SOC-USER-PC-04\Desktop\Portfolio'
$src  = Join-Path $root 'index.html'
$dst  = Join-Path $root '_tmp_test.html'

$html = Get-Content $src -Raw
# Harness must be installed BEFORE main.js so the IO shim is in place,
# and mailto navigation is neutralised so the headless run does not bail out.
$inject = @'
  <script src="_tmp_harness.js"></script>
  <script src="assets/js/main.js"></script>
'@
$html = $html.Replace('  <script src="assets/js/main.js"></script>', $inject)
Set-Content -Path $dst -Value $html -Encoding UTF8
"wrote $dst ($((Get-Item $dst).Length) bytes)"

$out = Join-Path $root '_tmp_test_dom.html'
$err = Join-Path $root '_tmp_test_err.txt'
$p = Start-Process -FilePath 'C:\Program Files\Google\Chrome\Application\chrome.exe' `
  -ArgumentList '--headless=new','--disable-gpu','--no-sandbox','--window-size=1280,900',
                '--virtual-time-budget=20000',"--user-data-dir=$env:TEMP\pf-chrome-test",
                '--dump-dom',("file:///" + ($dst -replace '\\','/')) `
  -RedirectStandardOutput $out -RedirectStandardError $err -NoNewWindow -PassThru -Wait
"chrome exit=$($p.ExitCode)"

$dom = Get-Content $out -Raw
$m = [regex]::Match($dom, '<pre id="test-report">(.*?)</pre>', 'Singleline')
if ($m.Success) {
  '=========== TEST REPORT ==========='
  [System.Web.HttpUtility]::HtmlDecode($m.Groups[1].Value)
} else {
  'NO REPORT FOUND - dumping tail of DOM'
  $dom.Substring([Math]::Max(0, $dom.Length - 1500))
}
