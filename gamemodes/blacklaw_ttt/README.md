# blacklaw_ttt Gamemode

## Start
1. Kopiere den Ordner `blacklaw_ttt` nach `garrysmod/gamemodes/`.
2. Starte den Server mit `+gamemode blacklaw_ttt`.
3. Achte auf das Boot-Log `[BLACKLAW_TTT]` in der Konsole.

## Struktur
- `gamemode/shared.lua` (shared Einstiegspunkt)
- `gamemode/init.lua` (Server)
- `gamemode/cl_init.lua` (Client)
- `gamemode/core/` (Basislogik)
- `gamemode/modules/` (optionale Module)
- `gamemode/ui/` (Client UI)
- `gamemode/admin/` (Admin Panel + Permissions)
- `gamemode/persistence/` (Datenbank)
- `gamemode/workshop/` (Workshop Loader)

## Workshop Setup
Der Server mountet Workshop-Content über `resource.AddWorkshop`, damit Clients automatisch laden.

- `bl_workshop_collection_id`: Steam Workshop Collection ID (optional).
  - Wenn gesetzt, lädt der Server alle Items aus der Collection.
  - **Wichtig:** Alle Items müssen public sein, sonst können Clients sie nicht herunterladen.
- `bl_workshop_ids_csv`: zusätzliche Item-IDs als CSV (z. B. `123456,7891011`).

Beim Serverstart läuft ein Self-Check, der für nicht-public Items Hinweise in der Konsole loggt.

## TTT2 Addon (UI + HUD)
Dieses Repo enthält zusätzlich ein TTT2-Addon, das die 2026-UI als VGUI-HUD/Scoreboard verwendet.

1. Kopiere den Ordner `blacklaw_ttt` nach `garrysmod/gamemodes/` (wie oben).
2. Starte den Server mit TTT2 (`+gamemode terrortown`).
3. Die Addon-Dateien liegen unter `gamemodes/blacklaw_ttt/lua/blacklaw_ttt2/` und werden automatisch per `lua/autorun/bl_ttt2_autorun.lua` geladen.

Die UI nutzt serverseitig gesendete Snapshots (server authoritative) und blendet das Standard-HUD aus.
