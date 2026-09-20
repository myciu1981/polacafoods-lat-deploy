# polacafoods.lat — pliki wdrożeniowe

To repo **nie zawiera źródeł strony**. Leżą w nich gotowe, zbudowane pliki, które
cPanel kopiuje pod `polacafoods.lat`. Źródła są w prywatnym repo
[`Polaca-Foods-Mexico`](https://github.com/myciu1981/Polaca-Foods-Mexico),
w katalogu `artifacts/polaca-foods` (Vite + React, dwujęzyczna ES/PL).

## Po co osobne repo

cPanelowy Git Version Control potrafi tylko sklonować repo i przekopiować pliki
według `.cpanel.yml`. Nie uruchomi `pnpm` ani `vite`, więc wdrożenie źródeł
położyłoby pod domeną TypeScript, którego przeglądarka nie przeczyta. Do tego
repo ze źródłami jest prywatne, a bez shell access cPanel nie skonfiguruje
klucza SSH — nie sklonowałby go.

Stąd podział: źródła zostają prywatne, a to repo jest publiczne i trzyma wyłącznie
to, co i tak jest publiczne, bo stanowi zawartość strony.

## Wdrożenie

```powershell
.\zbuduj.ps1
git add -A
git commit -m "opis zmiany"
git push
```

Potem w cPanelu: **Git™ Version Control → Manage → Pull or Deploy**:

1. **Update from Remote** — ściąga commit z GitHuba
2. **Deploy HEAD Commit** — wykonuje `.cpanel.yml`

Oba kroki, w tej kolejności. Samo `git push` niczego nie wdraża.

## Na co uważać

**Buduj z PowerShella, nie z Git Basha.** MSYS zamienia `BASE_PATH=/` na ścieżkę
`C:/Program Files/Git/` i odnośniki w `index.html` wychodzą jako
`/Program Files/Git/assets/...`. `zbuduj.ps1` sprawdza to na końcu i przerywa,
gdyby się zdarzyło.

**cPanel przy wdrożeniu tylko kopiuje, nigdy nie usuwa.** Dlatego `.cpanel.yml`
kasuje przed kopiowaniem `assets/`, `images/`, `logos/`, `flags/` i `partners/` —
w całości pochodzą z builda. Najważniejsze jest `assets/`, gdzie nazwy plików
mają hash treści: bez czyszczenia zbierałyby się tam wszystkie stare wersje
`index-*.js` z każdego wdrożenia. Pliki luzem w korzeniu są nadpisywane; gdyby
któryś zniknął z repo, trzeba go skasować na serwerze ręcznie.

**`.htaccess` musi być w `site/`.** Niesie wymuszenie HTTPS, `www` → bez www,
kompresję, cache, `Options -Indexes` oraz `Require all granted`, bez którego
nethero oddaje 403 crawlerom AI. `zbuduj.ps1` przerywa, jeśli go nie znajdzie.
Plik źródłowy jest w repo ze źródłami, w `artifacts/polaca-foods/public/.htaccess` —
poprawki wprowadza się tam, nie tutaj.

**Zmiany treści robi się w repo ze źródłami.** Ręczna edycja plików w `site/`
zostanie skasowana przy najbliższym `zbuduj.ps1`.

## Co gdzie leży

| | |
|---|---|
| `site/` | zbudowana strona, dokładna kopia `dist/public` ze źródeł |
| `.cpanel.yml` | co i dokąd cPanel kopiuje przy wdrożeniu |
| `zbuduj.ps1` | build ze źródeł + przełożenie do `site/` |
| `.gitattributes` | `* -text`, żeby Git nie ruszał końców linii |

Document root na serwerze: `/home/myciu/public_html/polacafoods.lat`
