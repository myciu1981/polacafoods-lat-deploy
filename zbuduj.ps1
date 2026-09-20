# Buduje polacafoods.lat ze źródeł i przekłada wynik do site/.
#
# Uruchamiać z PowerShella, nie z Git Basha — MSYS zamienia BASE_PATH="/" na
# ścieżkę C:/Program Files/Git/ i wszystkie odnośniki w index.html wychodzą
# wtedy jako /Program Files/Git/assets/...
#
#   .\zbuduj.ps1
#   git add -A; git commit -m "opis zmiany"; git push
#
# Potem w cPanelu: Git Version Control -> Manage -> Pull or Deploy ->
# Update from Remote, a następnie Deploy HEAD Commit. Oba kroki, w tej kolejności.

$ErrorActionPreference = 'Stop'

$zrodla = 'C:\Users\USER\OneDrive\Dokumenty\Claude code\Polaca-Foods-Mexico\artifacts\polaca-foods'
$site   = Join-Path $PSScriptRoot 'site'

if (-not (Test-Path $zrodla)) {
  throw "Nie widzę repo ze źródłami: $zrodla"
}

Write-Host "==> Pobieram najnowszy main ze źródeł" -ForegroundColor Cyan
Push-Location (Split-Path $zrodla -Parent | Split-Path -Parent)
try {
  git fetch origin
  $za = (git rev-list --count HEAD..origin/main)
  if ($za -ne '0') {
    Write-Host "    lokalne repo jest $za commitów w tyle — robię fast-forward" -ForegroundColor Yellow
    git merge --ff-only origin/main
  } else {
    Write-Host "    już aktualne"
  }
} finally { Pop-Location }

Write-Host "==> Buduję" -ForegroundColor Cyan
Push-Location $zrodla
try {
  $env:BASE_PATH = '/'
  $env:PORT      = '8080'
  $env:NODE_ENV  = 'production'
  & node '.\node_modules\vite\bin\vite.js' build --config vite.config.ts
  if ($LASTEXITCODE -ne 0) { throw "vite build zwrócił $LASTEXITCODE" }
} finally { Pop-Location }

$dist = Join-Path $zrodla 'dist\public'
if (-not (Test-Path (Join-Path $dist 'index.html'))) {
  throw "Build nie zostawił index.html w $dist"
}

# Kontrola, czy ścieżki wyszły z ukośnikiem, a nie z podmienioną przez MSYS
# ścieżką do Gita — to najczęstszy sposób, w jaki ten build cicho się psuje.
$html = Get-Content (Join-Path $dist 'index.html') -Raw
if ($html -notmatch 'src="/assets/') {
  throw "index.html nie ma odnośników zaczynających się od /assets/ — sprawdź BASE_PATH"
}

Write-Host "==> Przekładam do site/" -ForegroundColor Cyan
if (Test-Path $site) { Remove-Item $site -Recurse -Force }
New-Item -ItemType Directory -Path $site | Out-Null
Copy-Item (Join-Path $dist '*') $site -Recurse -Force
# Copy-Item z maską pomija pliki zaczynające się od kropki
Copy-Item (Join-Path $dist '.htaccess') $site -Force

if (-not (Test-Path (Join-Path $site '.htaccess'))) {
  throw "Brakuje .htaccess w site/ — bez niego nie ma HTTPS, przekierowań ani cache"
}

$ile = (Get-ChildItem $site -Recurse -File -Force).Count
$mb  = [math]::Round(((Get-ChildItem $site -Recurse -File -Force | Measure-Object Length -Sum).Sum / 1MB), 1)
Write-Host "==> Gotowe: $ile plików, $mb MB w site/" -ForegroundColor Green
Write-Host "    Teraz: git add -A; git commit -m '...'; git push" -ForegroundColor Green
