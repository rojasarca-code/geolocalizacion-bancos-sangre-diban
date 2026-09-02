# Regenera datos/convenios.json y el bloque <script id="conv"> de index.html a partir de
# datos/convenios_semaforo_agosto2026_verificado.xlsx, enlazando por codigo RENIPRESS contra
# el registro de bancos embebido en index.html (#data). Windows PowerShell 5.1+.
#   powershell -ExecutionPolicy Bypass -File scripts\build_conv.ps1
$ErrorActionPreference = 'Stop'
$repo = Split-Path $PSScriptRoot -Parent
$xlsx = Join-Path $repo 'datos\convenios_semaforo_agosto2026_verificado.xlsx'
$app  = Join-Path $repo 'index.html'

# --- desempacar el xlsx a una carpeta temporal ---
$xl = Join-Path ([System.IO.Path]::GetTempPath()) ('conv_' + [guid]::NewGuid().ToString('N'))
Add-Type -AssemblyName System.IO.Compression.FileSystem
[System.IO.Compression.ZipFile]::ExtractToDirectory($xlsx, $xl)

# --- RAW (#data) y destino de #conv salen del propio index.html ---
$html = [System.IO.File]::ReadAllText($app, [System.Text.UTF8Encoding]::new($false))
if ($html -notmatch '(?s)<script id="data" type="application/json">(.*?)</script>') { throw 'no #data' }
$rawJson = $Matches[1]

[xml]$ss = Get-Content -Raw -Encoding UTF8 (Join-Path $xl 'xl\sharedStrings.xml')
$S = @()
foreach ($si in $ss.sst.si) {
  if ($si.t -is [string]) { $S += [string]$si.t }
  elseif ($si.t.'#text') { $S += [string]$si.t.'#text' }
  elseif ($si.r) { $S += ( ($si.r | ForEach-Object { if ($_.t.'#text') { $_.t.'#text' } else { [string]$_.t } }) -join '' ) }
  else { $S += '' }
}
Write-Host "shared strings: $($S.Count)"

[xml]$sh = Get-Content -Raw -Encoding UTF8 (Join-Path $xl 'xl\worksheets\sheet2.xml')
function CellVal($c) {
  if ($null -eq $c) { return '' }
  $v = $c.v
  if ($null -eq $v) { return '' }
  if ($c.t -eq 's') { return $S[[int]$v] }
  return [string]$v
}
function G($h, $k) { $v = $h[$k]; if ($null -eq $v) { return '' } return ([string]$v).Trim() }
$rows = @()
foreach ($r in $sh.worksheet.sheetData.row) {
  $rn = [int]$r.r
  if ($rn -lt 3 -or $rn -gt 292) { continue }
  $cells = @{}
  foreach ($c in $r.c) { $cells[($c.r -replace '\d','')] = (CellVal $c) }
  $rows += [pscustomobject]@{
    prod = (G $cells 'A'); prodRen = (G $cells 'B'); prodReg = (G $cells 'C')
    rec  = (G $cells 'D'); recRen  = (G $cells 'E'); recReg  = (G $cells 'F'); recTipo = (G $cells 'G')
  }
}
Write-Host "convenio rows: $($rows.Count)"

$raw = $rawJson | ConvertFrom-Json
Write-Host "RAW banks: $($raw.Count)"

function NormRen($x) {
  if ($null -eq $x) { return '' }
  $d = ([string]$x) -replace '[^\d]',''
  if ($d -eq '') { return '' }
  return ([string]([int64]$d))
}
function NormName($x) {
  if ($null -eq $x) { return '' }
  $n = ([string]$x).Normalize([Text.NormalizationForm]::FormD)
  $sb = New-Object System.Text.StringBuilder
  foreach ($ch in $n.ToCharArray()) {
    if ([Globalization.CharUnicodeInfo]::GetUnicodeCategory($ch) -ne [Globalization.UnicodeCategory]::NonSpacingMark) { [void]$sb.Append($ch) }
  }
  $t = $sb.ToString().ToUpperInvariant()
  $t = $t -replace '[^A-Z0-9]',' '
  $t = $t -replace '\s+',' '
  return $t.Trim()
}
$TIPO = @{ 'IA'='I A'; 'IB'='I B'; 'IC'='I C'; 'II'='II' }

$byRen = @{}; $byName = @{}; $idx = 0
foreach ($b in $raw) {
  $b | Add-Member -NotePropertyName _i -NotePropertyValue $idx -Force
  $rk = NormRen $b.ren
  if ($rk -ne '' -and -not $byRen.ContainsKey($rk)) { $byRen[$rk] = $b }
  $nk = NormName $b.name
  if ($nk -ne '' -and -not $byName.ContainsKey($nk)) { $byName[$nk] = $b }
  $idx++
}

function ResolveBank($name, $ren) {
  $rk = NormRen $ren
  if ($rk -ne '' -and $byRen.ContainsKey($rk)) { return @{ b=$byRen[$rk]; mm='ren' } }
  $nk = NormName $name
  if ($nk -ne '' -and $byName.ContainsKey($nk)) { return @{ b=$byName[$nk]; mm='nombre' } }
  return @{ b=$null; mm='no' }
}

$groups = [ordered]@{}
foreach ($row in $rows) {
  if ($row.prod -eq '' -and $row.rec -eq '') { continue }
  $gk = NormRen $row.prodRen
  if ($gk -eq '') { $gk = 'N:' + (NormName $row.prod) }
  if (-not $groups.Contains($gk)) { $groups[$gk] = [System.Collections.ArrayList]::new() }
  [void]$groups[$gk].Add($row)
}
Write-Host "producer groups: $($groups.Count)"

$CONV = @()
$stat = @{ pRen=0; pName=0; pNo=0; kRen=0; kName=0; kNo=0; kGeo=0; kTot=0 }
foreach ($gk in $groups.Keys) {
  $grp = $groups[$gk]
  $pr = ResolveBank $grp[0].prod $grp[0].prodRen
  $pb = $pr.b
  if ($pr.mm -eq 'ren') { $stat.pRen++ } elseif ($pr.mm -eq 'nombre') { $stat.pName++ } else { $stat.pNo++ }

  $partners = @()
  $seen = @{}
  foreach ($row in $grp) {
    $rn = ($row.rec -replace '^-+$','').Trim()
    if ($rn -eq '' -and (NormRen $row.recRen) -eq '') { continue }   # fila sin hospital receptor
    $pkey = (NormRen $row.recRen); if ($pkey -eq '') { $pkey = 'N:' + (NormName $row.rec) }
    if ($seen.ContainsKey($pkey)) { continue }
    $seen[$pkey] = 1
    $kr = ResolveBank $row.rec $row.recRen
    $kb = $kr.b
    $stat.kTot++
    if ($kr.mm -eq 'ren') { $stat.kRen++ } elseif ($kr.mm -eq 'nombre') { $stat.kName++ } else { $stat.kNo++ }
    $lat = $null; $lng = $null; $bid = $null
    if ($kb) { if ($null -ne $kb.lat) { $lat = [double]$kb.lat }; if ($null -ne $kb.lng) { $lng = [double]$kb.lng }; $bid = [int]$kb._i }
    $p = [ordered]@{
      n   = $(if ($kb) { [string]$kb.name } else { $row.rec })
      ren = (NormRen $row.recRen)
      t   = $(if ($kb) { $TIPO[[string]$kb.tipo] } elseif ($row.recTipo) { $row.recTipo } else { '' })
      s   = $(if ($kb) { [string]$kb.sub } else { '' })
      dist= $(if ($kb) { [string]$kb.dist } else { '' })
      prov= $(if ($kb) { [string]$kb.prov } else { '' })
      reg = $(if ($kb) { [string]$kb.reg } else { $row.recReg })
      lat = $lat; lng = $lng; bid = $bid
      mm  = $kr.mm
      prec= $(if ($kb) { 'registro' } else { '' })
    }
    if ($null -ne $lat) { $stat.kGeo++ }
    $partners += [pscustomobject]$p
  }

  $plat = $null; $plng = $null; $pbid = $null
  if ($pb) { if ($null -ne $pb.lat) { $plat = [double]$pb.lat }; if ($null -ne $pb.lng) { $plng = [double]$pb.lng }; $pbid = [int]$pb._i }
  $c = [ordered]@{
    name = $(if ($pb) { [string]$pb.name } else { $grp[0].prod })
    ren  = (NormRen $grp[0].prodRen)
    reg  = $(if ($pb) { [string]$pb.reg } else { $grp[0].prodReg })
    prov = $(if ($pb) { [string]$pb.prov } else { '' })
    dist = $(if ($pb) { [string]$pb.dist } else { '' })
    lat  = $plat; lng = $plng; bid = $pbid
    mm   = $pr.mm
    geo  = ($partners | Where-Object { $null -ne $_.lat }).Count
    partners = $partners
  }
  if ($partners.Count -gt 0) { $CONV += [pscustomobject]$c }
}

$CONV = $CONV | Sort-Object @{e={ if ($null -eq $_.lat) {1} else {0} }}, reg, name

$json = $CONV | ConvertTo-Json -Depth 6 -Compress
$enc = New-Object System.Text.UTF8Encoding($false)
[System.IO.File]::WriteAllText((Join-Path $repo 'datos\convenios.json'), $json, $enc)
foreach ($f in 'index.html','mapa-bancos-sangre.html') {
  $p = Join-Path $repo $f
  $h = [System.IO.File]::ReadAllText($p, $enc)
  $h = [regex]::Replace($h, '(?s)(<script id="conv" type="application/json">).*?(</script>)', { param($m) $m.Groups[1].Value + $json + $m.Groups[2].Value }, 1)
  [System.IO.File]::WriteAllText($p, $h, $enc)
}
Remove-Item -Recurse -Force $xl
Write-Host "actualizado: datos/convenios.json, index.html, mapa-bancos-sangre.html"

Write-Host ""
Write-Host "=== RESULTADO ==="
Write-Host ("productores: {0}  (RENIPRESS {1}, nombre {2}, sin resolver {3})" -f $CONV.Count,$stat.pRen,$stat.pName,$stat.pNo)
Write-Host ("convenios unicos: {0}  (RENIPRESS {1}, nombre {2}, sin resolver {3})" -f $stat.kTot,$stat.kRen,$stat.kName,$stat.kNo)
Write-Host ("partners con coordenadas: {0}" -f $stat.kGeo)
Write-Host ("bytes new_conv.json: {0}" -f $json.Length)
Write-Host ""
Write-Host "--- productores sin resolver ---"
$CONV | Where-Object { $_.mm -eq 'no' } | Select-Object name,reg | Format-Table -AutoSize
Write-Host "--- partners sin resolver (muestra 30) ---"
$CONV | ForEach-Object { $_.partners } | Where-Object { $_.mm -eq 'no' } | Select-Object -First 30 n,reg,ren | Format-Table -AutoSize
