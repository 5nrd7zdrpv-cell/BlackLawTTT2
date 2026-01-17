BL = BL or {}
BL.PlayerStats = BL.PlayerStats or {}

local TABLE_NAME = "player_stats"

local function ensure_table()
  if sql and sql.Query then
    sql.Query([[CREATE TABLE IF NOT EXISTS player_stats (
      steamid64 TEXT PRIMARY KEY,
      kills INTEGER,
      deaths INTEGER,
      rounds INTEGER,
      wins_inno INTEGER,
      wins_traitor INTEGER,
      last_seen INTEGER
    )]])
  end
end

local function normalize_int(value)
  return math.max(0, math.floor(tonumber(value) or 0))
end

local function default_stats(steamid64)
  return {
    steamid64 = steamid64 or "",
    kills = 0,
    deaths = 0,
    rounds = 0,
    wins_inno = 0,
    wins_traitor = 0,
    last_seen = 0,
  }
end

local function normalize_row(row, steamid64)
  local stats = default_stats(steamid64)
  if type(row) ~= "table" then
    return stats
  end
  stats.kills = normalize_int(row.kills)
  stats.deaths = normalize_int(row.deaths)
  stats.rounds = normalize_int(row.rounds)
  stats.wins_inno = normalize_int(row.wins_inno)
  stats.wins_traitor = normalize_int(row.wins_traitor)
  stats.last_seen = normalize_int(row.last_seen)
  return stats
end

local function is_valid_steamid64(steamid64)
  return type(steamid64) == "string" and steamid64 ~= "" and steamid64 ~= "0"
end

local function save_stats(stats)
  if not sql or not sql.Query or type(stats) ~= "table" then
    return
  end

  if not is_valid_steamid64(stats.steamid64) then
    return
  end

  local query = string.format(
    "INSERT OR REPLACE INTO %s (steamid64, kills, deaths, rounds, wins_inno, wins_traitor, last_seen) VALUES (%s, %d, %d, %d, %d, %d, %d)",
    TABLE_NAME,
    sql.SQLStr(stats.steamid64),
    normalize_int(stats.kills),
    normalize_int(stats.deaths),
    normalize_int(stats.rounds),
    normalize_int(stats.wins_inno),
    normalize_int(stats.wins_traitor),
    normalize_int(stats.last_seen)
  )
  sql.Query(query)
end

function BL.PlayerStats.Load(ply)
  if not IsValid(ply) or not ply:IsPlayer() or ply:IsBot() then
    return
  end

  ensure_table()

  local steamid64 = ply:SteamID64()
  if not is_valid_steamid64(steamid64) then
    return
  end

  local query = string.format(
    "SELECT steamid64, kills, deaths, rounds, wins_inno, wins_traitor, last_seen FROM %s WHERE steamid64 = %s LIMIT 1",
    TABLE_NAME,
    sql.SQLStr(steamid64)
  )

  local row = sql.QueryRow(query)
  if not row then
    row = default_stats(steamid64)
    save_stats(row)
  end

  ply.BLTTT_PlayerStats = normalize_row(row, steamid64)
end

function BL.PlayerStats.Get(ply)
  if not IsValid(ply) then
    return default_stats("")
  end
  if type(ply.BLTTT_PlayerStats) ~= "table" then
    ply.BLTTT_PlayerStats = default_stats(ply:SteamID64())
  end
  return ply.BLTTT_PlayerStats
end

function BL.PlayerStats.Save(ply)
  if not IsValid(ply) then
    return
  end

  local stats = BL.PlayerStats.Get(ply)
  stats.steamid64 = ply:SteamID64()
  ply.BLTTT_PlayerStats = stats
  save_stats(stats)
end

function BL.PlayerStats.UpdateLastSeen(ply)
  if not IsValid(ply) then
    return
  end

  local stats = BL.PlayerStats.Get(ply)
  stats.last_seen = os.time()
  ply.BLTTT_PlayerStats = stats
  save_stats(stats)
end

function BL.PlayerStats.RecordRoundEnd(winner)
  if type(winner) ~= "string" then
    winner = ""
  end

  for _, ply in ipairs(player.GetAll()) do
    if IsValid(ply) and ply:IsPlayer() and not ply:IsBot() then
      local stats = BL.PlayerStats.Get(ply)
      stats.kills = normalize_int(stats.kills) + normalize_int(ply.BLTTT_RoundKills)
      stats.deaths = normalize_int(stats.deaths) + normalize_int(ply.BLTTT_RoundDeaths)
      stats.rounds = normalize_int(stats.rounds) + 1

      if BL.Roles and BL.Roles.IDS then
        if winner == "innocents" and ply.BLTTT_RoleId == BL.Roles.IDS.INNOCENT then
          stats.wins_inno = normalize_int(stats.wins_inno) + 1
        elseif winner == "traitors" and ply.BLTTT_RoleId == BL.Roles.IDS.TRAITOR then
          stats.wins_traitor = normalize_int(stats.wins_traitor) + 1
        end
      end

      stats.last_seen = os.time()
      stats.steamid64 = ply:SteamID64()
      ply.BLTTT_PlayerStats = stats
      save_stats(stats)
    end
  end
end

ensure_table()

hook.Add("PlayerInitialSpawn", "BL.PlayerStats.Load", function(ply)
  BL.PlayerStats.Load(ply)
end)

hook.Add("PlayerDisconnected", "BL.PlayerStats.UpdateLastSeen", function(ply)
  BL.PlayerStats.UpdateLastSeen(ply)
end)
