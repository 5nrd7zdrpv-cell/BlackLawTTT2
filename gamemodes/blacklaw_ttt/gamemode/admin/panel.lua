BL = BL or {}
BL.Admin = BL.Admin or {}

local ACTION_LIMIT = 6
local ACTION_INTERVAL = 1

local PHASES = {
  LOBBY = true,
  PREP = true,
  ACTIVE = true,
  POST = true,
}

local function has_perm(ply, perm)
  return BL.Perm and BL.Perm.Has and BL.Perm.Has(ply, perm)
end

local function has_any_admin_perm(ply)
  return has_perm(ply, "round.control")
    or has_perm(ply, "player.action")
    or has_perm(ply, "logs.view")
    or has_perm(ply, "settings.edit")
end

local function sanitize_string(value, max_len)
  if type(value) ~= "string" then
    return ""
  end
  local trimmed = string.Trim(value)
  if max_len and #trimmed > max_len then
    return string.sub(trimmed, 1, max_len)
  end
  return trimmed
end

local function sanitize_reason(value)
  return sanitize_string(value, 140)
end

local function build_actor(ply)
  if not IsValid(ply) then
    return { name = "console", steamid64 = "" }
  end
  return { name = ply:Nick(), steamid64 = ply:SteamID64() }
end

local function build_target(ply)
  if not IsValid(ply) then
    return nil
  end
  return { name = ply:Nick(), steamid64 = ply:SteamID64() }
end

local function find_player_by_steamid64(steamid64)
  if BL.Net and BL.Net.IsSteamID64 and not BL.Net.IsSteamID64(steamid64) then
    return nil
  end
  if type(steamid64) ~= "string" or steamid64 == "" then
    return nil
  end
  for _, ply in ipairs(player.GetAll()) do
    if IsValid(ply) and ply:SteamID64() == steamid64 then
      return ply
    end
  end
  return nil
end

local function is_admin_debug_enabled()
  if GM and GM.BLTTT and GM.BLTTT.GetConfigValue then
    return GM.BLTTT.GetConfigValue("Server", "bl_admin_debug") == true
  end
  return false
end

local function log_admin_action(actor, target, action, reason, detail)
  if not BL.State or not BL.State.PushAdminAction then
    return
  end
  BL.State.PushAdminAction({
    time = os.time(),
    actor = build_actor(actor),
    target = build_target(target) or target,
    action = action,
    reason = reason,
    detail = detail,
  })
end

local function broadcast_event(event_type, payload)
  if BL.State and BL.State.PushEvent then
    BL.State.PushEvent(event_type, payload)
  end
  if BL.Net and BL.Net.SendEvent then
    BL.Net.SendEvent({
      time = os.time(),
      type = event_type,
      payload = payload,
    })
  end
end

local function send_admin_snapshot(ply)
  if not IsValid(ply) then
    return
  end
  if not BL.Admin.BuildSnapshot then
    return
  end
  local snapshot = BL.Admin.BuildSnapshot(ply)
  net.Start(BL.Net.Messages.AdminSnapshot)
  if BL.Net and BL.Net.WriteCompressedTable then
    BL.Net.WriteCompressedTable(snapshot)
  else
    net.WriteTable(snapshot)
  end
  net.Send(ply)
end

local function finalize_admin_action(ply)
  send_admin_snapshot(ply)
end

local function build_permissions_snapshot(ply)
  return {
    round_control = has_perm(ply, "round.control"),
    player_action = has_perm(ply, "player.action"),
    logs_view = has_perm(ply, "logs.view"),
    settings_edit = has_perm(ply, "settings.edit"),
  }
end

local function build_roles_snapshot()
  local roles = {}
  if not BL.Roles or not BL.Roles.Registry or not BL.Roles.Registry.order then
    return roles
  end
  for _, role in ipairs(BL.Roles.Registry.order) do
    roles[#roles + 1] = {
      id = role.id,
      key = role.key,
      name = role.name,
    }
  end
  return roles
end

local function build_settings_snapshot()
  local settings = {}
  if not GM or not GM.BLTTT or not GM.BLTTT.Config then
    return settings
  end

  for name, entry in pairs(GM.BLTTT.Config.Server or {}) do
    if entry and entry.ConVar then
      local value = GM.BLTTT.GetConfigValue("Server", name)
      settings[#settings + 1] = {
        name = name,
        value = value,
        default = entry.Default,
        help = entry.Help,
        type = entry.Type,
        min = entry.Min,
        max = entry.Max,
      }
    end
  end

  table.sort(settings, function(a, b)
    return tostring(a.name) < tostring(b.name)
  end)

  return settings
end

function BL.Admin.BuildSnapshot(ply)
  local snapshot = BL.State and BL.State.GetSnapshot and BL.State.GetSnapshot(ply) or {}
  local admin_log = BL.State and BL.State.GetAdminActionLog and BL.State.GetAdminActionLog(ply) or nil
  local permissions = build_permissions_snapshot(ply)
  local settings = nil

  if permissions.settings_edit then
    settings = build_settings_snapshot()
  end

  return {
    snapshot = snapshot,
    admin_actions = admin_log,
    permissions = permissions,
    settings = settings,
    roles = build_roles_snapshot(),
    admin_debug = is_admin_debug_enabled(),
    server_time = os.time(),
  }
end

local function parse_bool(value)
  if type(value) == "boolean" then
    return value
  end
  if type(value) == "number" then
    return value ~= 0
  end
  if type(value) == "string" then
    local lowered = string.lower(string.Trim(value))
    return lowered == "1" or lowered == "true" or lowered == "yes" or lowered == "on"
  end
  return false
end

local function clamp_number(value, min_value, max_value)
  if min_value ~= nil then
    value = math.max(min_value, value)
  end
  if max_value ~= nil then
    value = math.min(max_value, value)
  end
  return value
end

local function apply_setting(name, raw_value)
  if not GM or not GM.BLTTT or not GM.BLTTT.Config then
    return false
  end

  local entry = (GM.BLTTT.Config.Server or {})[name]
  if not entry or not entry.ConVar then
    return false
  end

  local setting_type = entry.Type or "string"
  local parsed = nil

  if setting_type == "bool" then
    parsed = parse_bool(raw_value) and 1 or 0
  elseif setting_type == "int" then
    local numeric = tonumber(raw_value)
    if not numeric then
      return false
    end
    parsed = math.floor(clamp_number(numeric, entry.Min, entry.Max))
  elseif setting_type == "float" then
    local numeric = tonumber(raw_value)
    if not numeric then
      return false
    end
    parsed = clamp_number(numeric, entry.Min, entry.Max)
  else
    parsed = sanitize_string(tostring(raw_value or ""), 200)
  end

  entry.ConVar:SetString(tostring(parsed))
  return true
end

BL.Net.Receive(BL.Net.Messages.AdminRequest, { limit = 3, interval = 2 }, function(_len, ply)
  if not IsValid(ply) then
    return
  end
  if not has_any_admin_perm(ply) then
    return
  end

  send_admin_snapshot(ply)
end)

BL.Net.Receive(BL.Net.Messages.AdminAction, { limit = ACTION_LIMIT, interval = ACTION_INTERVAL }, function(_len, ply)
  if not IsValid(ply) then
    return
  end

  local payload = net.ReadTable()
  if type(payload) ~= "table" then
    return
  end

  local action = sanitize_string(payload.action, 64)
  if action == "" then
    return
  end

  local reason = sanitize_reason(payload.reason)
  local target_id = payload.target
  local target = nil
  if target_id ~= nil then
    if BL.Net and BL.Net.IsSteamID64 and not BL.Net.IsSteamID64(target_id) then
      return
    end
    target = find_player_by_steamid64(target_id)
  end

  if action == "round_start" then
    if not has_perm(ply, "round.control") then
      return
    end
    if BL.RoundManager and BL.RoundManager.ForceRoundStart and BL.RoundManager.ForceRoundStart() then
      broadcast_event("admin_force_start", { by = ply:Nick() })
      log_admin_action(ply, nil, action, reason)
      if BL.Net and BL.Net.BroadcastSnapshot then
        BL.Net.BroadcastSnapshot()
      end
      finalize_admin_action(ply)
    end
    return
  end

  if action == "round_end" then
    if not has_perm(ply, "round.control") then
      return
    end
    if BL.RoundManager and BL.RoundManager.ForceRoundEnd and BL.RoundManager.ForceRoundEnd() then
      broadcast_event("admin_force_end", { by = ply:Nick() })
      log_admin_action(ply, nil, action, reason)
      if BL.Net and BL.Net.BroadcastSnapshot then
        BL.Net.BroadcastSnapshot()
      end
      finalize_admin_action(ply)
    end
    return
  end

  if action == "round_restart" then
    if not has_perm(ply, "round.control") then
      return
    end
    if BL.RoundManager and BL.RoundManager.AdminRestartRound then
      BL.RoundManager.AdminRestartRound()
      broadcast_event("admin_restart_round", { by = ply:Nick() })
      log_admin_action(ply, nil, action, reason)
      if BL.Net and BL.Net.BroadcastSnapshot then
        BL.Net.BroadcastSnapshot()
      end
      finalize_admin_action(ply)
    end
    return
  end

  if action == "round_set_phase" then
    if not has_perm(ply, "round.control") then
      return
    end
    local phase = sanitize_string(payload.phase, 16)
    if not PHASES[phase] then
      return
    end
    if BL.RoundManager and BL.RoundManager.SetPhase then
      BL.RoundManager.SetPhase(phase)
      broadcast_event("admin_set_phase", { by = ply:Nick(), phase = phase })
      log_admin_action(ply, nil, action, reason, { phase = phase })
      if BL.Net and BL.Net.BroadcastSnapshot then
        BL.Net.BroadcastSnapshot()
      end
      finalize_admin_action(ply)
    end
    return
  end

  if action == "round_force_role" then
    if not has_perm(ply, "round.control") then
      return
    end
    if not is_admin_debug_enabled() then
      return
    end
    if not IsValid(target) then
      return
    end
    local role_id = tonumber(payload.role_id)
    if not role_id then
      return
    end
    if BL.RoundManager and BL.RoundManager.AdminSetRole and BL.RoundManager.AdminSetRole(target, role_id) then
      log_admin_action(ply, target, action, reason, { role_id = math.floor(role_id) })
      if BL.Net and BL.Net.BroadcastSnapshot then
        BL.Net.BroadcastSnapshot()
      end
      finalize_admin_action(ply)
    end
    return
  end

  if action == "player_bring" then
    if not has_perm(ply, "player.action") then
      return
    end
    if not IsValid(target) then
      return
    end
    target:SetPos(ply:GetPos())
    log_admin_action(ply, target, action, reason)
    finalize_admin_action(ply)
    return
  end

  if action == "player_goto" then
    if not has_perm(ply, "player.action") then
      return
    end
    if not IsValid(target) then
      return
    end
    ply:SetPos(target:GetPos())
    log_admin_action(ply, target, action, reason)
    finalize_admin_action(ply)
    return
  end

  if action == "player_freeze" then
    if not has_perm(ply, "player.action") then
      return
    end
    if not IsValid(target) then
      return
    end
    target:Freeze(true)
    log_admin_action(ply, target, action, reason)
    finalize_admin_action(ply)
    return
  end

  if action == "player_unfreeze" then
    if not has_perm(ply, "player.action") then
      return
    end
    if not IsValid(target) then
      return
    end
    target:Freeze(false)
    log_admin_action(ply, target, action, reason)
    finalize_admin_action(ply)
    return
  end

  if action == "player_respawn" then
    if not has_perm(ply, "player.action") then
      return
    end
    if not IsValid(target) then
      return
    end
    if BL.RoundManager and BL.RoundManager.AdminRespawn then
      BL.RoundManager.AdminRespawn(target, false)
    else
      target:Spawn()
    end
    log_admin_action(ply, target, action, reason)
    if BL.Net and BL.Net.BroadcastSnapshot then
      BL.Net.BroadcastSnapshot()
    end
    finalize_admin_action(ply)
    return
  end

  if action == "player_slay" then
    if not has_perm(ply, "player.action") then
      return
    end
    if not IsValid(target) then
      return
    end
    target:Kill()
    log_admin_action(ply, target, action, reason)
    if BL.Net and BL.Net.BroadcastSnapshot then
      BL.Net.BroadcastSnapshot()
    end
    finalize_admin_action(ply)
    return
  end

  if action == "player_set_health" then
    if not has_perm(ply, "player.action") then
      return
    end
    if not IsValid(target) then
      return
    end
    local value = tonumber(payload.value)
    if not value then
      return
    end
    local clamped = math.max(1, math.min(200, math.floor(value)))
    target:SetHealth(clamped)
    log_admin_action(ply, target, action, reason, { value = clamped })
    finalize_admin_action(ply)
    return
  end

  if action == "player_set_armor" then
    if not has_perm(ply, "player.action") then
      return
    end
    if not IsValid(target) then
      return
    end
    local value = tonumber(payload.value)
    if not value then
      return
    end
    local clamped = math.max(0, math.min(200, math.floor(value)))
    target:SetArmor(clamped)
    log_admin_action(ply, target, action, reason, { value = clamped })
    finalize_admin_action(ply)
    return
  end

  if action == "player_give_credits" then
    if not has_perm(ply, "player.action") then
      return
    end
    if not IsValid(target) then
      return
    end
    local value = tonumber(payload.value)
    if not value then
      return
    end
    local clamped = math.max(0, math.min(50, math.floor(value)))
    if BL.Credits and BL.Credits.Add then
      BL.Credits.Add(target, clamped)
    end
    log_admin_action(ply, target, action, reason, { value = clamped })
    if BL.Net and BL.Net.BroadcastSnapshot then
      BL.Net.BroadcastSnapshot()
    end
    finalize_admin_action(ply)
    return
  end

  if action == "player_make_admin" then
    if not has_perm(ply, "player.action") then
      return
    end
    if not IsValid(target) then
      return
    end
    BL.ACL = BL.ACL or {}
    BL.ACL.Users = BL.ACL.Users or {}
    BL.ACL.Users[target:SteamID64()] = "admin"
    log_admin_action(ply, target, action, reason)
    finalize_admin_action(ply)
    return
  end

  if action == "settings_set" then
    if not has_perm(ply, "settings.edit") then
      return
    end
    local name = sanitize_string(payload.name, 80)
    if name == "" then
      return
    end
    if apply_setting(name, payload.value) then
      log_admin_action(ply, { name = name }, action, reason, { value = payload.value })
      send_admin_snapshot(ply)
    end
  end
end)
