BL = BL or {}
BL.TTT2 = BL.TTT2 or {}
BL.TTT2.Net = BL.TTT2.Net or {}

BL.TTT2.Net.Cache = BL.TTT2.Net.Cache or {
  snapshot = nil,
  last_snapshot_at = 0,
}

local function sanitize_self(value)
  if type(value) ~= "table" then
    return nil
  end
  local cleaned = {
    health = math.max(0, math.floor(tonumber(value.health) or 0)),
    armor = math.max(0, math.floor(tonumber(value.armor) or 0)),
    credits = math.max(0, math.floor(tonumber(value.credits) or 0)),
    alive = value.alive == true,
    role_id = math.max(0, math.floor(tonumber(value.role_id) or 0)),
    role_key = type(value.role_key) == "string" and value.role_key or "UNKNOWN",
    role_name = type(value.role_name) == "string" and value.role_name or "Unbekannt",
  }
  return cleaned
end

local function sanitize_players(value)
  if type(value) ~= "table" then
    return {}
  end

  local cleaned = {}
  local count = 0
  for _, entry in ipairs(value) do
    if type(entry) == "table" then
      cleaned[#cleaned + 1] = {
        steamid64 = type(entry.steamid64) == "string" and entry.steamid64 or "",
        name = type(entry.name) == "string" and entry.name or "Unbekannt",
        ping = math.max(0, math.floor(tonumber(entry.ping) or 0)),
        alive = entry.alive == true,
        role_id = math.max(0, math.floor(tonumber(entry.role_id) or 0)),
        role_key = type(entry.role_key) == "string" and entry.role_key or "UNKNOWN",
        role_name = type(entry.role_name) == "string" and entry.role_name or "Unbekannt",
      }
      count = count + 1
      if count >= 64 then
        break
      end
    end
  end
  return cleaned
end

local function sanitize_snapshot(snapshot)
  if type(snapshot) ~= "table" then
    return nil
  end

  local cleaned = {
    phase = type(snapshot.phase) == "string" and snapshot.phase or "LOBBY",
    round_id = math.max(0, math.floor(tonumber(snapshot.round_id) or 0)),
    phase_end = type(snapshot.phase_end) == "number" and snapshot.phase_end or nil,
    self = sanitize_self(snapshot.self),
    players = sanitize_players(snapshot.players),
    event_log = type(snapshot.event_log) == "table" and snapshot.event_log or {},
  }
  return cleaned
end

net.Receive(BL.TTT2.Net.Messages.Snapshot, function()
  local snapshot = net.ReadTable()
  local cleaned = sanitize_snapshot(snapshot)
  if not cleaned then
    return
  end

  BL.TTT2.Net.Cache.snapshot = cleaned
  BL.TTT2.Net.Cache.last_snapshot_at = CurTime()
end)

function BL.TTT2.Net.GetSnapshot()
  return BL.TTT2.Net.Cache.snapshot
end
