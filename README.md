# YubiEnroll GUI

Ett svenskt WPF-gränssnitt i PowerShell 7 för Yubicos `yubienroll.exe`.

## Starta

Dubbelklicka på `Start-YubiEnroll-GUI.cmd`, eller kör:

```powershell
pwsh.exe -NoProfile -STA -File .\YubiEnroll-GUI.ps1
```

Standardsökvägen är:

```text
C:\Program Files\Yubico\YubiEnroll\yubienroll.exe
```

Den kan ändras under fliken **Inställningar**.

## Funktioner

- statusdashboard för aktiv provider, inloggning, kortläsare och vald användare
- stegvis registrering av säkerhetsnycklar
- tabeller med valbara användare och credentials
- master/detail-vyer för enrollment-profiler och provider-konfigurationer
- registrering, listning och säker radering av FIDO-credentials
- skapa, redigera, lista och radera enrollment-profiler
- skapa, redigera, aktivera, visa, lista och radera provider-konfigurationer
- avancerade FIDO-inställningar som kan fällas in och ut
- valfri loggnivå och loggfil
- infällbar teknisk logg som öppnas automatiskt vid fel
- sparad exe-sökväg, loggkonfiguration, fönsterstorlek och senaste provider
- kommandoöversikt, kopierbar utdata och möjlighet att avbryta bakgrundskommandon

Kommandon som kan behöva PIN, fysisk beröring, OAuth-uppgifter eller andra interaktiva svar öppnas i ett separat PowerShell-fönster. Icke-interaktiva kommandon körs i bakgrunden och visar resultatet i appen.

Inställningarna sparas i `%LOCALAPPDATA%\YubiEnrollGUI\settings.json`.

## Säkerhet

GUI:t visar alltid en extra bekräftelse före radering. Alternativet `--force` hoppar över YubiEnrolls egen bekräftelse, men inte GUI:ts bekräftelse.

Dokumentation: [YubiEnroll Commands](https://docs.yubico.com/software/yubikey/tools/yubienroll/commands.html)
