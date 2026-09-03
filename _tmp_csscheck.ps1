$ErrorActionPreference = 'Stop'
$path = 'c:\Users\SOC-USER-PC-04\Desktop\Portfolio\assets\css\styles.css'
$lines = Get-Content $path

# Strip block comments so their contents never confuse the depth tracker
$raw = Get-Content $path -Raw
$clean = [regex]::Replace($raw, '/\*.*?\*/', { param($m) ($m.Value -replace '[^\r\n]', ' ') }, 'Singleline')
$cl = $clean -split "`r?`n"

$depth = 0
$problems = @()
for ($i = 0; $i -lt $cl.Count; $i++) {
  $line = $cl[$i]
  $trim = $line.Trim()

  # A declaration (prop: value;) must never appear at depth 0
  if ($depth -eq 0 -and $trim -match '^[a-z-]+\s*:\s*.+;$' -and $trim -notmatch '^--') {
    $problems += ("line {0}: declaration outside any rule -> {1}" -f ($i + 1), $lines[$i].Trim())
  }
  # A lone closing brace at depth 0 means we already closed too many
  if ($depth -eq 0 -and $trim -eq '}') {
    $problems += ("line {0}: stray closing brace" -f ($i + 1))
  }

  $depth += ([regex]::Matches($line, '\{')).Count
  $depth -= ([regex]::Matches($line, '\}')).Count
  if ($depth -lt 0) { $depth = 0 }
}

"final depth: $depth"
if ($problems.Count -eq 0) {
  'CSS STRUCTURE OK - no declarations or braces outside rules'
} else {
  "PROBLEMS ($($problems.Count)):"
  $problems
}

# Duplicate selector-block detection for the big section headers
'--- duplicate top-level selectors ---'
$sels = [regex]::Matches($clean, '(?m)^([.#a-zA-Z\[][^{}\r\n]*?)\s*\{') | ForEach-Object { $_.Groups[1].Value.Trim() }
$sels | Group-Object | Where-Object { $_.Count -gt 1 } | ForEach-Object { "{0}  x{1}" -f $_.Name, $_.Count }
