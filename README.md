# BlackLawTTT2

Dieses Repository enthält ein funktionsfähiges Grundgerüst für Trouble in Terrorist Town 2.
Das UI erlaubt das Hinzufügen von Spielern, das Starten einer Runde, das Zuweisen einfacher Rollen
sowie das Umschalten zwischen Tag- und Nachtphase.

## Installation (Garry's Mod)

1. Kopiere den Ordner `blacklaw_ttt` nach `garrysmod/gamemodes/`.
2. Starte den Server mit `+gamemode blacklaw_ttt` oder setze `gamemode blacklaw_ttt` in der
   `server.cfg`.
3. Lege gewünschte ConVars in der `server.cfg` fest (Beispiele unten).
4. Optional: Hinterlege Workshop-IDs über `bl_workshop_collection_id` oder `bl_workshop_ids_csv`.

## Lokaler UI-Start

```bash
# im Repository ausführen
python3 -m http.server 8000
```

Danach im Browser `http://localhost:8000` öffnen.

## Konfiguration (ConVars)

Server-ConVars (in `server.cfg`):

| ConVar | Default | Beschreibung |
| --- | --- | --- |
| `bl_round_time` | `600` | Rundendauer in Sekunden. |
| `bl_prep_time` | `30` | Vorbereitungszeit vor Rundenstart. |
| `bl_post_time` | `15` | Nachrunden-Zeit nach Rundenende. |
| `bl_min_players` | `4` | Mindestspieleranzahl für Rundenstart. |
| `bl_traitor_ratio` | `0.25` | Anteil an Verrätern pro Spieleranzahl. |
| `bl_shop_enabled` | `1` | Shop aktivieren. |
| `bl_karma_enabled` | `1` | Karma-System aktivieren. |
| `bl_ff_scale` | `0.5` | Friendly-Fire-Damage-Skalierung. |
| `bl_credits_start_traitor` | `2` | Start-Credits für Verräter. |
| `bl_credits_kill` | `1` | Credits pro Kill. |
| `bl_admin_debug` | `0` | Admin-Debug-Logging aktivieren. |
| `bl_workshop_collection_id` | `""` | Workshop-Collection-ID zum Mounten. |
| `bl_workshop_ids_csv` | `""` | Kommagetrennte Workshop-Item-IDs. |

Client-ConVars (in der Client-Konsole):

| ConVar | Default | Beschreibung |
| --- | --- | --- |
| `bl_ui_scale` | `1` | UI-Skalierungsfaktor. |
| `bl_ui_compact` | `0` | Kompakte UI-Ansicht aktivieren. |
| `bl_show_eventlog` | `1` | Eventlog-Panel anzeigen. |

Optional stehen die Werte im Code über `GM.BLTTT.GetConfigValue("Server", "bl_round_time")` bzw.
`GM.BLTTT.GetConfigValue("Client", "bl_ui_scale")` zur Verfügung.

## Nächste Schritte (Ideen)

- Rollenlogik erweitern (z. B. spezielle Rollen, Team-Balancing).
- Spiel-Events in eine Datenstruktur auslagern.
- UI-Ansicht für einzelne Spieler hinzufügen.
