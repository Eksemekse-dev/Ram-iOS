# RAM Test

Aplikacja iOS do testowania, ile pamięci RAM uda się zająć zanim system ją wyłączy.

## Jak działa

1. Zakładka **Test** pokazuje, ile RAM-u aplikacja już zapchała.
2. Przycisk **Test** startuje ciągłe zapychanie pamięci.
3. Postęp zapisuje się co 1 sekundę do pliku w katalogu Documents.
4. Gdy iOS ubije aplikację po zapełnieniu RAM-u, po ponownym uruchomieniu widać ostatni zapisany wynik.

## IPA (GitHub Actions)

Workflow `.github/workflows/build-ipa.yml` buduje niepodpisane IPA na `macos-14`.

Po pushu na `main` (albo ręcznie przez **Actions → Build IPA → Run workflow**) pobierz artefakt `RAMTest.ipa`.

Niepodpisane IPA nie zainstaluje się na urządzeniu bez własnego podpisu (Apple Developer / AltStore / Sideloadly). Żeby podpisywać w CI, dodaj sekrety certyfikatu i profilu provisioning.
