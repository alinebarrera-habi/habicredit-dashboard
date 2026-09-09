# check_render.ps1 - abre el tablero ARMADO (sin cifrar, _build\dashboard_full.html) en Chrome headless
# y comprueba que los datos embebidos cargan: que no salga el mensaje de error de carga y que haya
# KPIs con numeros. Tambien abre index.html (cifrado) y confirma que muestra el formulario. ASCII puro.
param([string]$Chrome = 'C:\Program Files\Google\Chrome\Application\chrome.exe')
function Dump([string]$page) {
  $stamp = [Guid]::NewGuid().ToString('N').Substring(0,6)
  $udd = Join-Path $env:TEMP ("udd_hc_$stamp"); $dom = Join-Path $env:TEMP ("dom_hc_$stamp.html")
  $cargs = @('--headless=new','--disable-gpu','--no-sandbox','--virtual-time-budget=8000',"--user-data-dir=$udd",'--dump-dom',('file:///' + ($page -replace '\\','/')))
  & $Chrome @cargs 2>$null | Out-File -FilePath $dom -Encoding utf8
  $t = [IO.File]::ReadAllText($dom)
  Remove-Item -LiteralPath $udd -Recurse -Force -ErrorAction SilentlyContinue
  Remove-Item -LiteralPath $dom -Force -ErrorAction SilentlyContinue
  $t
}
$full = Join-Path $PSScriptRoot '_build\dashboard_full.html'
$t = Dump $full
$body = [regex]::Replace($t, '(?s)<script.*?</script>', '')
"=== dashboard_full.html (sin cifrar) ==="
"dom {0:n0} chars" -f $t.Length
"error de carga visible: {0}" -f ($body -match '(?i)error (de|al) carg|No se pudo|Failed to fetch')
"NaN/undefined en pantalla: {0}/{1}" -f ([regex]::Matches($body,'NaN').Count), ([regex]::Matches($body,'undefined').Count)
$nums = [regex]::Matches($body, '[\$]?-?\d{1,3}(\.\d{3})+(,\d+)?|\d+[.,]\d+%')
"cifras en pantalla: {0}" -f $nums.Count
"titulos: " + (([regex]::Matches($body, '<h[1-3][^>]*>(.*?)</h[1-3]>') | ForEach-Object { ($_.Groups[1].Value -replace '<[^>]+>','').Trim() } | Where-Object { $_ } | Select-Object -First 8) -join ' | ')
$t2 = Dump (Join-Path $PSScriptRoot 'index.html')
"=== index.html (cifrado) ==="
"formulario visible: {0} | titulo: {1}" -f ($t2 -match 'class="card" id="f"'), ([regex]::Match($t2,'<title>(.*?)</title>').Groups[1].Value)
