BL = BL or {}
BL.State = BL.State or {}

local STATE_PHASES = {
  LOBBY = true,
  PREP = true,
  ACTIVE = true,
  POST = true,
}

local MAX_EVENTS = 200
local MAX_ADMIN_ACTIONS = 200

BL.State.Data = BL.State.Data or {
  phase = "LOBBY",
  round_id = 0,
  phase_start = os.time(),
  event_log = {},
  admin_action_log = {},
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
  if not IsValid(target) then
    return false
  end
  if get_role_flag(target, "RoleRevealed") or get_role_flag(target, "RolePublic") then
    return true
  end
  if not IsValid(viewer) then
    return false
  end
  if viewer == target then
    return true
  end
  if BL.Inspect and BL.Inspect.CanReveal and BL.Inspect.CanReveal(viewer, target) then
    return true
  end
  return false
end

local function get_round_stat(ply, field)
  if not IsValid(ply) then
    return 0
  end
  local value = ply[field]
  if type(value) ~= "number" then
    return 0
  end
  return math.max(0, math.floor(value))
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
      ping = ply:Ping() or 0,
      alive = is_player_alive(ply),
      round_kills = get_round_stat(ply, "BLTTT_RoundKills"),
      round_deaths = get_round_stat(ply, "BLTTT_RoundDeaths"),
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

local function copy_admin_action_log()
  local copy = {}
  for index, entry in ipairs(BL.State.Data.admin_action_log) do
    copy[index] = {
      time = entry.time,
      actor = entry.actor,
      target = entry.target,
      action = entry.action,
      reason = entry.reason,
      detail = entry.detail,
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
  local shop_snapshot = nil
  if BL.Shop and BL.Shop.BuildClientSnapshot then
    shop_snapshot = BL.Shop.BuildClientSnapshot(ply)
  end
  return {
    phase = phase,
    round_id = BL.State.Data.round_id,
    phase_start = BL.State.Data.phase_start,
    players_summary = build_players_summary(ply, phase),
    role_counts = build_role_counts(),
    alive_counts = build_alive_counts(),
    event_log = copy_event_log(),
    post_round_summary = copy_post_round_summary(),
    credits = BL.Credits and BL.Credits.Get and BL.Credits.Get(ply) or 0,
    shop = shop_snapshot,
  }
end

function BL.State.GetAdminActionLog(ply)
  if IsValid(ply) and (not BL.Perm or not BL.Perm.Has or not BL.Perm.Has(ply, "logs.view")) then
    return nil
  end
  return copy_admin_action_log()
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

function BL.State.PushAdminAction(entry)
  if type(entry) ~= "table" then
    return
  end

  local action = entry.action
  if type(action) ~= "string" or action == "" then
    return
  end

  local log_entry = {
    time = entry.time or os.time(),
    actor = entry.actor,
    target = entry.target,
    action = action,
    reason = entry.reason,
    detail = entry.detail,
  }

  local log = BL.State.Data.admin_action_log
  log[#log + 1] = log_entry
  if #log > MAX_ADMIN_ACTIONS then
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
  if IsValid(ply) and (not BL.Perm or not BL.Perm.Has or not BL.Perm.Has(ply, "logs.view")) then
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
