$ErrorActionPreference = 'Continue'
Add-Type -AssemblyName System.IO.Compression

$path = 'c:\Users\SOC-USER-PC-04\Desktop\Portfolio\Md_Nafis_Salman_CV.pdf'
$bytes = [System.IO.File]::ReadAllBytes($path)
$latin = [System.Text.Encoding]::GetEncoding(28591)
$s = $latin.GetString($bytes)

function Inflate-Bytes([byte[]]$data) {
    foreach ($skip in 2, 0, 1) {
        try {
            $ms = New-Object System.IO.MemoryStream(,$data)
            $ms.Position = $skip
            $ds = New-Object System.IO.Compression.DeflateStream($ms, [System.IO.Compression.CompressionMode]::Decompress)
            $out = New-Object System.IO.MemoryStream
            $ds.CopyTo($out)
            $ds.Dispose(); $ms.Dispose()
            if ($out.Length -gt 0) { return $out.ToArray() }
        } catch { }
    }
    return $null
}

$idx = 0
$n = 0
$textStreams = @()
while ($true) {
    $st = $s.IndexOf('stream', $idx)
    if ($st -lt 0) { break }
    if ($st -ge 3 -and $s.Substring($st - 3, 3) -eq 'end') { $idx = $st + 6; continue }

    $dataStart = $st + 6
    if ($dataStart -lt $s.Length -and $s[$dataStart] -eq [char]13) { $dataStart++ }
    if ($dataStart -lt $s.Length -and $s[$dataStart] -eq [char]10) { $dataStart++ }

    $en = $s.IndexOf('endstream', $dataStart)
    if ($en -lt 0) { break }
    $len = $en - $dataStart
    $idx = $en + 9
    if ($len -le 0) { continue }

    $n++
    $chunk = New-Object byte[] $len
    [Array]::Copy($bytes, $dataStart, $chunk, 0, $len)
    $inf = Inflate-Bytes $chunk
    if ($null -eq $inf) {
        "STREAM $n raw=$len -> INFLATE FAILED"
    } else {
        $txt = $latin.GetString($inf)
        $hasBT = $txt.Contains('BT')
        $hasTJ = ($txt.Contains('Tj') -or $txt.Contains('TJ'))
        "STREAM $n raw=$len inflated=$($inf.Length) BT=$hasBT TJ=$hasTJ"
        if ($hasBT -and $hasTJ) {
            $textStreams += $txt
        }
    }
}
"TEXT STREAM COUNT: $($textStreams.Count)"
$outFile = 'c:\Users\SOC-USER-PC-04\Desktop\Portfolio\_tmp_content.txt'
[System.IO.File]::WriteAllText($outFile, ($textStreams -join "`n===== NEXT PAGE =====`n"), $latin)
"WROTE: $outFile size=$((Get-Item $outFile).Length)"
