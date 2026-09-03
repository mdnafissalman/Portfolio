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

# Collect the two page content streams (indices 1 and 3 from the diagnostic run)
$wanted = @(1, 3)
$idx = 0
$n = 0
$pages = @()
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
    if ($wanted -notcontains $n) { continue }
    $chunk = New-Object byte[] $len
    [Array]::Copy($bytes, $dataStart, $chunk, 0, $len)
    $inf = Inflate-Bytes $chunk
    if ($inf) { $pages += $latin.GetString($inf) }
}

function Unescape-PdfString([string]$raw) {
    $sb = New-Object System.Text.StringBuilder
    $i = 0
    while ($i -lt $raw.Length) {
        $c = $raw[$i]
        if ($c -eq '\') {
            $i++
            if ($i -ge $raw.Length) { break }
            $e = $raw[$i]
            switch ($e) {
                'n' { [void]$sb.Append("`n"); $i++ }
                'r' { [void]$sb.Append("`r"); $i++ }
                't' { [void]$sb.Append("`t"); $i++ }
                'b' { $i++ }
                'f' { $i++ }
                '(' { [void]$sb.Append('('); $i++ }
                ')' { [void]$sb.Append(')'); $i++ }
                '\' { [void]$sb.Append('\'); $i++ }
                default {
                    if ($e -match '[0-7]') {
                        $oct = ''
                        while ($i -lt $raw.Length -and $raw[$i] -match '[0-7]' -and $oct.Length -lt 3) { $oct += $raw[$i]; $i++ }
                        [void]$sb.Append([char][Convert]::ToInt32($oct, 8))
                    } else { [void]$sb.Append($e); $i++ }
                }
            }
        } else {
            [void]$sb.Append($c); $i++
        }
    }
    return $sb.ToString()
}

$outLines = New-Object System.Collections.Generic.List[string]
$pageNo = 0
foreach ($p in $pages) {
    $pageNo++
    $outLines.Add("########## PAGE $pageNo ##########")

    $i = 0
    $line = New-Object System.Text.StringBuilder
    $L = $p.Length
    while ($i -lt $L) {
        $c = $p[$i]
        if ($c -eq '(') {
            # read balanced literal string
            $depth = 1
            $i++
            $start = $i
            $sb2 = New-Object System.Text.StringBuilder
            while ($i -lt $L -and $depth -gt 0) {
                $ch = $p[$i]
                if ($ch -eq '\') { [void]$sb2.Append($ch); $i++; if ($i -lt $L) { [void]$sb2.Append($p[$i]); $i++ }; continue }
                if ($ch -eq '(') { $depth++ }
                elseif ($ch -eq ')') { $depth--; if ($depth -eq 0) { $i++; break } }
                [void]$sb2.Append($ch); $i++
            }
            [void]$line.Append((Unescape-PdfString $sb2.ToString()))
            continue
        }
        if ($c -eq '<' -and ($i + 1) -lt $L -and $p[$i+1] -ne '<') {
            $close = $p.IndexOf('>', $i)
            if ($close -gt $i) {
                $hex = ($p.Substring($i + 1, $close - $i - 1) -replace '[^0-9A-Fa-f]', '')
                if ($hex.Length % 2 -eq 1) { $hex += '0' }
                $sb3 = New-Object System.Text.StringBuilder
                for ($k = 0; $k -lt $hex.Length; $k += 2) {
                    [void]$sb3.Append([char][Convert]::ToInt32($hex.Substring($k,2), 16))
                }
                [void]$line.Append("<HEX:" + $sb3.ToString() + ">")
                $i = $close + 1
                continue
            }
        }
        # operators that end a text line
        if ($c -eq 'T') {
            $op = $p.Substring($i, [Math]::Min(2, $L - $i))
            if ($op -eq 'Td' -or $op -eq 'TD' -or $op -eq 'T*' -or $op -eq 'TJ' -or $op -eq 'Tj') {
                if ($op -eq 'Td' -or $op -eq 'TD' -or $op -eq 'T*') {
                    if ($line.Length -gt 0) { $outLines.Add($line.ToString()); [void]$line.Clear() }
                }
                $i += 2
                continue
            }
        }
        if ($c -eq 'E' -and $p.Substring($i, [Math]::Min(2, $L - $i)) -eq 'ET') {
            if ($line.Length -gt 0) { $outLines.Add($line.ToString()); [void]$line.Clear() }
            $i += 2
            continue
        }
        $i++
    }
    if ($line.Length -gt 0) { $outLines.Add($line.ToString()) }
}

$outFile = 'c:\Users\SOC-USER-PC-04\Desktop\Portfolio\_tmp_cv_text.txt'
[System.IO.File]::WriteAllLines($outFile, $outLines, [System.Text.Encoding]::UTF8)
"LINES: $($outLines.Count)  ->  $outFile"
