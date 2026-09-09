# publish.ps1 - arma, cifra y publica el dashboard P&L de HabiCredit en GitHub Pages.
#
#   Fuente: repo P-L-Habicredit (dashboard.html + datos.json)  -> build_page.ps1 -> _build\dashboard_full.html
#   Salida (cifrada, lo unico que va al repo): .\index.html
#   Contrasena: .\config.local.ps1 ($HABICREDIT_PASSWORD) - gitignored.
#
# Uso:  powershell -NoProfile -ExecutionPolicy Bypass -File publish.ps1            # build + cifrar + commit + push
#       powershell -NoProfile -ExecutionPolicy Bypass -File publish.ps1 -NoPush
# ASCII puro.
param(
  [switch]$NoPush,
  [string]$Mensaje = ''
)
$ErrorActionPreference = 'Stop'
[Console]::OutputEncoding = [Text.Encoding]::UTF8
$repo = $PSScriptRoot
$cfg = Join-Path $repo 'config.local.ps1'
if (-not (Test-Path $cfg)) { throw "Falta $cfg con `$HABICREDIT_PASSWORD = '...'" }
. $cfg
if (-not $HABICREDIT_PASSWORD -or $HABICREDIT_PASSWORD.Length -lt 12) { throw 'HABICREDIT_PASSWORD vacia o muy corta (min 12)' }

& (Join-Path $repo 'build_page.ps1')
$Source = Join-Path $repo '_build\dashboard_full.html'
$out = Join-Path $repo 'index.html'
"-> cifrando ({0:n1} MB)" -f ((Get-Item $Source).Length / 1MB)
python (Join-Path $repo 'encrypt_page.py') $Source $out $HABICREDIT_PASSWORD
if ($LASTEXITCODE -ne 0) { throw 'fallo el cifrado' }

$chk = @"
import sys, json, base64, re
from cryptography.hazmat.primitives.ciphers.aead import AESGCM
from cryptography.hazmat.primitives.kdf.pbkdf2 import PBKDF2HMAC
from cryptography.hazmat.primitives import hashes
page = open(sys.argv[1], encoding='utf-8').read()
blob = json.loads(re.search(r'const BLOB = (\{.*?\});', page).group(1))
b = lambda s: base64.b64decode(s)
key = PBKDF2HMAC(algorithm=hashes.SHA256(), length=32, salt=b(blob['salt']), iterations=blob['iter']).derive(sys.argv[2].encode())
html = AESGCM(key).decrypt(b(blob['nonce']), b(blob['ct']), None)
src = open(sys.argv[3], 'rb').read()
print('roundtrip OK (%d bytes)' % len(html) if html == src else 'ROUNDTRIP MISMATCH'); sys.exit(0 if html == src else 1)
"@
$chkFile = Join-Path $env:TEMP 'habicredit_chk.py'
[IO.File]::WriteAllText($chkFile, $chk, (New-Object Text.UTF8Encoding($false)))
python $chkFile $out $HABICREDIT_PASSWORD $Source
if ($LASTEXITCODE -ne 0) { throw 'la pagina cifrada NO abre con la contrasena configurada' }
Remove-Item $chkFile -Force -ErrorAction SilentlyContinue

$meta = [regex]::Match((Get-Content $Source -Raw -Encoding UTF8), '"generado_en":"([^"]+)"').Groups[1].Value
if ($Mensaje -eq '') { $Mensaje = "Publicar dashboard HabiCredit (cifrado) - datos $meta - $(Get-Date -Format 'yyyy-MM-dd HH:mm')" }
git -C $repo add index.html
$st = git -C $repo status --porcelain index.html
if (-not $st) { "-> nada que publicar (index.html identico)"; exit 0 }
git -C $repo commit -q -m $Mensaje
"-> commit: $Mensaje"
if ($NoPush) { "-> sin push (-NoPush)"; exit 0 }
git -C $repo push origin main
""
"OK publicado. Link: https://alinebarrera-habi.github.io/habicredit-dashboard/"
