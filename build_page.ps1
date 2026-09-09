# build_page.ps1 - arma el dashboard de HabiCredit como UN SOLO HTML autocontenido.
#
# El dashboard.html del repo P-L-Habicredit carga sus datos con fetch('datos.json') (o, dentro de
# Apps Script, con window.__DATOS__ inyectado). Para publicarlo cifrado en GitHub Pages hay que
# embeber el JSON en la pagina, porque un datos.json aparte quedaria SIN cifrar en el repo publico.
# Aqui se inyecta <script>window.__DATOS__ = {...json...};</script> en el <head>, que es exactamente
# la ruta que el propio dashboard ya prevee ("window.__DATOS__ (inyectado por Apps Script)").
#
# Salida: .\_build\dashboard_full.html  (gitignored: es el tablero SIN cifrar)
# ASCII puro.
param(
  [string]$SrcDir = 'C:\Users\alinebarrera_habi\Documents\GitHub\P-L-Habicredit',
  [string]$Out = ''
)
$ErrorActionPreference = 'Stop'
[Console]::OutputEncoding = [Text.Encoding]::UTF8
if ($Out -eq '') { $Out = Join-Path $PSScriptRoot '_build\dashboard_full.html' }
$html = [IO.File]::ReadAllText((Join-Path $SrcDir 'dashboard.html'), [Text.Encoding]::UTF8)
$json = [IO.File]::ReadAllText((Join-Path $SrcDir 'datos.json'), [Text.Encoding]::UTF8).Trim()
# validar que el JSON parsea (si no, el tablero mostraria "error de carga")
$null = $json | ConvertFrom-Json
$meta = [regex]::Match($json, '"generado_en":"([^"]+)"').Groups[1].Value
if ($html -match 'window\.__DATOS__\s*=') { throw 'dashboard.html ya trae window.__DATOS__; revisar antes de inyectar' }
# </script> dentro del JSON romperia el <script>; no deberia haber, pero se escapa por si acaso
$json = $json.Replace('</', '<\/')
$inject = "<script>window.__DATOS__ = $json;</script>`n"
$i = $html.IndexOf('<head>', [StringComparison]::OrdinalIgnoreCase)
if ($i -lt 0) { throw 'dashboard.html sin <head>' }
$i += 6
$full = $html.Substring(0, $i) + "`n" + $inject + $html.Substring($i)
$dir = Split-Path $Out -Parent
if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Force $dir | Out-Null }
[IO.File]::WriteAllText($Out, $full, (New-Object Text.UTF8Encoding($false)))
"-> {0}  ({1:n1} MB)  datos generados en: {2}" -f $Out, ((Get-Item $Out).Length / 1MB), $meta
