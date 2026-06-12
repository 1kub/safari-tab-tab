# TabTab

Ľahké Safari rozšírenie pre **MRU prepínanie tabov** cez `Control+Tab` (správanie podobné Firefoxu / Alt+Tab).

- macOS 13+
- Natívny Swift, žiadna sieť, žiadna analytika
- Menu bar agent (bez ikony v Docku)
- Open source (MIT)

## Správanie

| Akcia | Výsledok |
|-------|----------|
| Krátke `Ctrl+Tab` | Prepne na predchádzajúci (MRU) tab |
| Drž `Ctrl+Tab` ~0,2 s | Zobrazí picker nedávnych tabov |
| `Ctrl+Tab` pri otvorenom pickeri | Posun v histórii dopredu |
| `Ctrl+Shift+Tab` | Posun v histórii dozadu |
| Pustenie `Ctrl` | Prepne na vybraný tab |

## Prvé spustenie (bezplatný Apple účet)

1. Otvor `TabTab.xcodeproj` v Xcode.
2. V oboch targetoch (`TabTab`, `TabTab Extension`) nastav **Signing & Capabilities** → tvoj Apple ID (Personal Team).
3. Zapni **App Groups** s ID `group.local.tabtab.shared` v oboch targetoch.
4. Spusti build:

```bash
chmod +x Scripts/reinstall.sh
./Scripts/reinstall.sh
```

5. Safari → **Nastavenia → Rozšírenia** → zapni **TabTab Extension** → „Povoliť na každej webovej stránke“.
6. Nechaj ikonu TabTab v Safari toolbare (je potrebná pre správne fungovanie).

## Obnova po 7 dňoch (free provisioning)

Bez plateného Developer účtu podpis vyprší približne po **7 dňoch**.

**Z menu bar ikony TabTab:** „Obnoviť podpis“ (alebo v Termináli):

```bash
./Scripts/reinstall.sh
```

Skript zbuildí appku, nainštaluje ju do `/Applications/TabTab.app` a spustí ju.

## Požiadavky na systém

- TabTab beží ako **menu bar agent** — spotrebuje minimum CPU (žiadne polling, len eventy z Safari).
- História tabov je uložená lokálne v App Group.

## Štruktúra

```
TabTab/                 — menu bar app + picker
TabTab Extension/       — Safari extension + content.js
Shared/                 — MRU store
Scripts/reinstall.sh    — build + inštalácia
```

## GitHub

Projekt je open source. Ak chceš verejný repozitár, nahraj obsah tohto priečinka na GitHub — credentials sem neukladaj.
