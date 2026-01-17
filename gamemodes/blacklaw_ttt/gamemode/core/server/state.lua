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
  post_round_summary = nil,
}

local function get_role_for_player(ply)
  if ply.BLTTT_RoleId ~= nil then
    return ply.BLTTT_RoleId
  end
  return 0
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

local function is_player_alive(ply)
  if not IsValid(ply) then
    return false
  end
  if ply.BLTTT_Alive ~= nil then
    return ply.BLTTT_Alive
  end
  if ply.GetNWBool then
    return ply:GetNWBool("blttt_alive", ply:Alive())
  end
  return ply:Alive()
end

local function should_reveal_role(viewer, target, phase)
  if phase == "POST" then
    return true
  end
  if not IsValid(viewer) or not IsValid(target) then
    return false
  end
  return viewer == target
end

local function build_players_summary(viewer, phase)
  local summary = {}
  for _, ply in ipairs(player.GetAll()) do
    local reveal = should_reveal_role(viewer, ply, phase)
    local role_id = reveal and get_role_for_player(ply) or 0
    local role_key = reveal and (BL.Roles and BL.Roles.GetRoleKey and BL.Roles.GetRoleKey(role_id) or "") or ""
    local role_name = reveal and (BL.Roles and BL.Roles.GetRoleName and BL.Roles.GetRoleName(role_id) or "") or ""
    summary[#summary + 1] = {
      steamid64 = ply:SteamID64(),
      name = ply:Nick(),
      alive = is_player_alive(ply),
      role_revealed = get_role_flag(ply, "RoleRevealed"),
      role_public = get_role_flag(ply, "RolePublic"),
      role_id = role_id,
      role_key = role_key,
      role_name = role_name,
    }
  end
  return summary
end

local function build_role_counts()
  local counts = {}
  for _, ply in ipairs(player.GetAll()) do
    local role = get_role_for_player(ply)
    local key = BL.Roles and BL.Roles.GetRoleKey and BL.Roles.GetRoleKey(role) or ""
    if key == "" then
      key = "UNKNOWN"
    end
    counts[key] = (counts[key] or 0) + 1
  end
  return counts
end

local function build_alive_counts()
  local total = 0
  local alive = 0
  for _, ply in ipairs(player.GetAll()) do
    total = total + 1
    if is_player_alive(ply) then
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

local function copy_post_round_summary()
  local summary = BL.State.Data.post_round_summary
  if type(summary) ~= "table" then
    return nil
  end
  return {
    reason = summary.reason,
    winner = summary.winner,
    round_id = summary.round_id,
    role_counts = table.Copy(summary.role_counts or {}),
    alive_counts = table.Copy(summary.alive_counts or {}),
  }
end

function BL.State.GetSnapshot(ply)
  local phase = BL.State.Data.phase
  return {
    phase = phase,
    round_id = BL.State.Data.round_id,
    phase_start = BL.State.Data.phase_start,
    players_summary = build_players_summary(ply, phase),
    role_counts = build_role_counts(),
    alive_counts = build_alive_counts(),
    event_log = copy_event_log(),
    post_round_summary = copy_post_round_summary(),
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
