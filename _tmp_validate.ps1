$ErrorActionPreference = 'Continue'
$root = 'c:\Users\SOC-USER-PC-04\Desktop\Portfolio'
$html = Get-Content (Join-Path $root 'index.html') -Raw
$css  = Get-Content (Join-Path $root 'assets\css\styles.css') -Raw
$js   = Get-Content (Join-Path $root 'assets\js\main.js') -Raw

'=== 1. Tag balance (block elements) ==='
$tags = 'html','head','body','header','nav','main','section','footer','div','ul','ol','li','article','aside','form','p','dl','dt','dd','h1','h2','h3','h4','span','a','button','label','textarea','svg'
foreach ($t in $tags) {
  $open  = ([regex]::Matches($html, "<$t(\s|>)")).Count
  $close = ([regex]::Matches($html, "</$t>")).Count
  $selfC = ([regex]::Matches($html, "<$t\b[^>]*/>")).Count
  $flag = if (($open - $selfC) -ne $close) { '  <== MISMATCH' } else { '' }
  "{0,-9} open={1,-4} close={2,-4} self={3,-3}{4}" -f $t, $open, $close, $selfC, $flag
}

'=== 2. CSS brace balance ==='
$o = ([regex]::Matches($css, '\{')).Count
$c = ([regex]::Matches($css, '\}')).Count
"css  open=$o  close=$c  $(if($o -ne $c){'<== MISMATCH'}else{'OK'})"

'=== 3. JS brace / paren balance ==='
$jo = ([regex]::Matches($js, '\{')).Count
$jc = ([regex]::Matches($js, '\}')).Count
$po = ([regex]::Matches($js, '\(')).Count
$pc = ([regex]::Matches($js, '\)')).Count
"js  curly open=$jo close=$jc  paren open=$po close=$pc"

'=== 4. Referenced local assets exist ==='
$refs = [regex]::Matches($html, '(?:href|src)="([^"#][^"]*)"') | ForEach-Object { $_.Groups[1].Value }
$refs = $refs | Where-Object { $_ -notmatch '^(https?:|mailto:|tel:|data:)' } | Sort-Object -Unique
foreach ($r in $refs) {
  $p = Join-Path $root ($r -replace '/', '\')
  $st = if (Test-Path $p) { 'OK' } else { 'MISSING' }
  "{0,-45} {1}" -f $r, $st
}

'=== 5. IDs used by JS exist in HTML ==='
$jsIds = [regex]::Matches($js, "getElementById\('([^']+)'\)") | ForEach-Object { $_.Groups[1].Value } | Sort-Object -Unique
foreach ($id in $jsIds) {
  $st = if ($html -match ('id="' + [regex]::Escape($id) + '"')) { 'OK' } else { 'MISSING IN HTML' }
  "{0,-16} {1}" -f $id, $st
}

'=== 6. Anchor targets exist ==='
$anchors = [regex]::Matches($html, 'href="#([A-Za-z][\w-]*)"') | ForEach-Object { $_.Groups[1].Value } | Sort-Object -Unique
foreach ($a in $anchors) {
  $st = if ($html -match ('id="' + [regex]::Escape($a) + '"')) { 'OK' } else { 'NO TARGET' }
  "#{0,-14} {1}" -f $a, $st
}

'=== 7. CSS classes used in HTML but not defined in CSS ==='
$htmlClasses = @()
foreach ($m in [regex]::Matches($html, 'class="([^"]+)"')) {
  $htmlClasses += ($m.Groups[1].Value -split '\s+')
}
$htmlClasses = $htmlClasses | Where-Object { $_ } | Sort-Object -Unique
$missing = @()
foreach ($cl in $htmlClasses) {
  if ($css -notmatch ('\.' + [regex]::Escape($cl) + '(?![\w-])')) { $missing += $cl }
}
if ($missing.Count -eq 0) { 'all HTML classes have CSS rules' } else { "unstyled: " + ($missing -join ', ') }

'=== 8. Labels point at real inputs ==='
foreach ($m in [regex]::Matches($html, '<label for="([^"]+)"')) {
  $id = $m.Groups[1].Value
  $st = if ($html -match ('id="' + [regex]::Escape($id) + '"')) { 'OK' } else { 'NO INPUT' }
  "label for={0,-12} {1}" -f $id, $st
}
