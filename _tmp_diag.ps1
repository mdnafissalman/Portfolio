$ErrorActionPreference = 'Continue'
Add-Type -AssemblyName System.IO.Compression

$path = 'c:\Users\SOC-USER-PC-04\Desktop\Portfolio\Md_Nafis_Salman_CV.pdf'
$bytes = [System.IO.File]::ReadAllBytes($path)
$latin = [System.Text.Encoding]::GetEncoding(28591)
$s = $latin.GetString($bytes)
"file bytes: $($bytes.Length)  string len: $($s.Length)"

$count = 0
$idx = 0
while ($true) {
    $st = $s.IndexOf('stream', $idx)
    if ($st -lt 0) { break }
    $count++
    $idx = $st + 6
}
"total 'stream' substring hits: $count"
