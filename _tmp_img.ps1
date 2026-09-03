$ErrorActionPreference = 'Continue'
$path = 'c:\Users\SOC-USER-PC-04\Desktop\Portfolio\Md_Nafis_Salman_CV.pdf'
$bytes = [System.IO.File]::ReadAllBytes($path)
$latin = [System.Text.Encoding]::GetEncoding(28591)
$s = $latin.GetString($bytes)

$outDir = 'c:\Users\SOC-USER-PC-04\Desktop\Portfolio\assets\img'
New-Item -ItemType Directory -Force -Path $outDir | Out-Null

$names = @('profile.jpg', 'signature.jpg')
$k = 0
foreach ($m in [regex]::Matches($s, '/Subtype\s*/Image[^>]*?/Length\s+(\d+)>>\s*stream\r?\n')) {
    $len = [int]$m.Groups[1].Value
    $dataStart = $m.Index + $m.Length
    $chunk = New-Object byte[] $len
    [Array]::Copy($bytes, $dataStart, $chunk, 0, $len)
    if ($k -lt $names.Count) {
        $target = Join-Path $outDir $names[$k]
        [System.IO.File]::WriteAllBytes($target, $chunk)
        "WROTE $target ($len bytes) firstBytes=$($chunk[0]),$($chunk[1]),$($chunk[2])"
    }
    $k++
}
"images found: $k"
