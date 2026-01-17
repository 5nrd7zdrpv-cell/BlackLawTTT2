BL = BL or {}
BL.State = BL.State or {}

local STATE_PHASES = {
  LOBBY = true,
  PREP = true,
  ACTIVE = true,
  POST = true,
}

local MAX_EVENTS = 200

BL.State.Data = BL.State.Data or {
  phase = "LOBBY",
  round_id = 0,
  phase_start = os.time(),
  event_log = {},
}

local function get_role_for_player(ply)
  if ply.BLTTT_Role ~= nil then
    return ply.BLTTT_Role
  end
  if ply.GetNWString then
    return ply:GetNWString("blttt_role", "")
  end
  return ""
end

local function get_role_flag(ply, key)
  local field = "BLTTT_" .. key
  if ply[field] ~= nil then
    return ply[field]
  end
  if ply.GetNWBool then
    return ply:GetNWBool("blttt_" .. string.lower(key), false)
  end
  return false
end

local function build_players_summary()
  local summary = {}
  for _, ply in ipairs(player.GetAll()) do
    summary[#summary + 1] = {
      steamid64 = ply:SteamID64(),
      name = ply:Nick(),
      alive = ply:Alive(),
      role_revealed = get_role_flag(ply, "RoleRevealed"),
      role_public = get_role_flag(ply, "RolePublic"),
    }
  end
  return summary
end

local function build_role_counts()
  local counts = {}
  for _, ply in ipairs(player.GetAll()) do
    local role = get_role_for_player(ply)
    if role == nil or role == "" then
      role = "unknown"
    end
    counts[role] = (counts[role] or 0) + 1
  end
  return counts
end

local function build_alive_counts()
  local total = 0
  local alive = 0
  for _, ply in ipairs(player.GetAll()) do
    total = total + 1
    if ply:Alive() then
      alive = alive + 1
    end
  end
  return {
    total = total,
    alive = alive,
    dead = total - alive,
  }
end

local function copy_event_log()
  local copy = {}
  for index, entry in ipairs(BL.State.Data.event_log) do
    copy[index] = {
      time = entry.time,
      type = entry.type,
      payload = entry.payload,
    }
  end
  return copy
end

function BL.State.GetSnapshot(_ply)
  return {
    phase = BL.State.Data.phase,
    round_id = BL.State.Data.round_id,
    phase_start = BL.State.Data.phase_start,
    players_summary = build_players_summary(),
    role_counts = build_role_counts(),
    alive_counts = build_alive_counts(),
    event_log = copy_event_log(),
  }
end

function BL.State.PushEvent(event_type, payload)
  if not event_type or event_type == "" then
    return
  end

  local entry = {
    time = os.time(),
    type = event_type,
    payload = payload,
  }

  local log = BL.State.Data.event_log
  log[#log + 1] = entry
  if #log > MAX_EVENTS then
    table.remove(log, 1)
  end
end

function BL.State.SetPhase(phase)
  if not STATE_PHASES[phase] then
    return false
  end

  if BL.State.Data.phase ~= phase then
    if phase == "PREP" then
      BL.State.Data.round_id = BL.State.Data.round_id + 1
    end
    BL.State.Data.phase = phase
    BL.State.Data.phase_start = os.time()
  end

  return true
end

concommand.Add("bl_debug_state", function(ply)
  if IsValid(ply) and not ply:IsAdmin() then
    return
  end

  local snapshot = BL.State.GetSnapshot(ply)
  local json = util.TableToJSON(snapshot, true)
  if IsValid(ply) then
    ply:PrintMessage(HUD_PRINTCONSOLE, "BL.State Snapshot:\n" .. json .. "\n")
  else
    print("BL.State Snapshot:")
    print(json)
  end
end)
