$ErrorActionPreference = 'Continue'
$path = 'c:\Users\SOC-USER-PC-04\Desktop\Portfolio\Md_Nafis_Salman_CV.pdf'
$bytes = [System.IO.File]::ReadAllBytes($path)
$latin = [System.Text.Encoding]::GetEncoding(28591)
$s = $latin.GetString($bytes)

"--- URI ACTIONS ---"
foreach ($m in [regex]::Matches($s, '/URI\s*\(([^)]*)\)')) { $m.Groups[1].Value }

"--- IMAGE XOBJECT DICTS ---"
foreach ($m in [regex]::Matches($s, '<<[^<>]*?/Subtype\s*/Image[^>]*?>>')) { $m.Value }

"--- OBJ 43 DICT ---"
$i43 = $s.IndexOf("`n43 0 obj")
if ($i43 -lt 0) { $i43 = $s.IndexOf("43 0 obj") }
if ($i43 -ge 0) { $s.Substring($i43, 400) -replace '[^\x20-\x7E]', '.' }
