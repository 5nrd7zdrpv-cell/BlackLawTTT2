BL = BL or {}
BL.RoundManager = BL.RoundManager or {}

local PHASES = {
  LOBBY = "LOBBY",
  PREP = "PREP",
  ACTIVE = "ACTIVE",
  POST = "POST",
}

local DEFAULT_LOADOUT = {
  "weapon_crowbar",
  "weapon_pistol",
}

local ROUND_TICK = "BL.RoundManager.Tick"
local ROUND_TICK_INTERVAL = 1

BL.RoundManager.State = BL.RoundManager.State or {
  next_phase_time = 0,
  last_summary = nil,
}

local function get_config(name, fallback)
  if GM and GM.BLTTT and GM.BLTTT.GetConfigValue then
    local value = GM.BLTTT.GetConfigValue("Server", name)
    if value ~= nil then
      return value
    end
  end
  return fallback
end

local function get_int(name, fallback)
  local value = get_config(name, fallback)
  if type(value) ~= "number" then
    return fallback
  end
  return math.floor(value)
end

local function get_float(name, fallback)
  local value = get_config(name, fallback)
  if type(value) ~= "number" then
    return fallback
  end
  return value
end

local function broadcast_snapshot()
  if BL.Net and BL.Net.BroadcastSnapshot then
    BL.Net.BroadcastSnapshot()
  end
end

local function push_event(event_type, payload)
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

local function set_role_flags(ply, revealed, public)
  ply.BLTTT_RoleRevealed = revealed
  ply.BLTTT_RolePublic = public
  if ply.SetNWBool then
    ply:SetNWBool("blttt_rolerevealed", revealed)
    ply:SetNWBool("blttt_rolepublic", public)
  end
end

local function set_role(ply, role)
  ply.BLTTT_Role = role
  if ply.SetNWString then
    ply:SetNWString("blttt_role", role or "")
  end
  set_role_flags(ply, false, false)
end

local function clear_role(ply)
  ply.BLTTT_Role = ""
  if ply.SetNWString then
    ply:SetNWString("blttt_role", "")
  end
  set_role_flags(ply, false, false)
end

local function make_spectator(ply)
  if not IsValid(ply) then
    return
  end

  if ply:Alive() then
    ply:KillSilent()
  end
  ply:StripWeapons()
  ply:StripAmmo()
  ply:Spectate(OBS_MODE_ROAMING)
  ply:SpectateEntity(nil)
  ply:Freeze(true)
end

local function spawn_player(ply, freeze)
  if not IsValid(ply) then
    return
  end
  ply:UnSpectate()
  ply:Spawn()
  ply:StripWeapons()
  ply:StripAmmo()
  for _, weapon in ipairs(DEFAULT_LOADOUT) do
    ply:Give(weapon)
  end
  ply:GiveAmmo(60, "Pistol", true)
  ply:Freeze(freeze or false)
end

local function eligible_players()
  local players = {}
  for _, ply in ipairs(player.GetAll()) do
    if IsValid(ply) and not ply.BLTTT_LateJoiner then
      players[#players + 1] = ply
    end
  end
  return players
end

local function assign_roles()
  local players = eligible_players()
  local total = #players
  if total == 0 then
    return
  end

  local ratio = get_float("bl_traitor_ratio", 0.25)
  local traitor_count = math.max(1, math.floor(total * ratio))
  if traitor_count > total then
    traitor_count = total
  end

  table.Shuffle(players)
  for index, ply in ipairs(players) do
    if index <= traitor_count then
      set_role(ply, "traitor")
    else
      set_role(ply, "innocent")
    end
  end
end

local function reveal_roles()
  for _, ply in ipairs(player.GetAll()) do
    if IsValid(ply) then
      set_role_flags(ply, true, true)
    end
  end
end

local function build_round_summary(reason, winner)
  local snapshot = BL.State and BL.State.GetSnapshot and BL.State.GetSnapshot(nil) or {}
  return {
    reason = reason,
    winner = winner,
    round_id = snapshot.round_id or 0,
    role_counts = snapshot.role_counts or {},
    alive_counts = snapshot.alive_counts or {},
  }
end

local function end_round(reason, winner)
  BL.RoundManager.State.last_summary = build_round_summary(reason, winner)
  reveal_roles()
  BL.RoundManager.SetPhase(PHASES.POST)
  push_event("round_summary", BL.RoundManager.State.last_summary)
end

local function check_win_condition()
  local traitors_alive = 0
  local innocents_alive = 0
  for _, ply in ipairs(player.GetAll()) do
    if IsValid(ply) and ply:Alive() and not ply.BLTTT_LateJoiner then
      if ply.BLTTT_Role == "traitor" then
        traitors_alive = traitors_alive + 1
      elseif ply.BLTTT_Role == "innocent" then
        innocents_alive = innocents_alive + 1
      end
    end
  end

  if traitors_alive <= 0 and innocents_alive > 0 then
    end_round("traitors_eliminated", "innocents")
    return true
  end

  if innocents_alive <= 0 and traitors_alive > 0 then
    end_round("traitors_domination", "traitors")
    return true
  end

  if traitors_alive <= 0 and innocents_alive <= 0 then
    end_round("no_survivors", "none")
    return true
  end

  return false
end

function BL.RoundManager.SetPhase(phase)
  if not BL.State or not BL.State.SetPhase then
    return false
  end

  if not BL.State.SetPhase(phase) then
    return false
  end

  if phase == PHASES.LOBBY then
    BL.RoundManager.State.next_phase_time = 0
    for _, ply in ipairs(player.GetAll()) do
      if IsValid(ply) then
        ply.BLTTT_LateJoiner = false
        clear_role(ply)
        spawn_player(ply, false)
      end
    end
    push_event("phase_lobby", {})
  elseif phase == PHASES.PREP then
    BL.RoundManager.State.next_phase_time = CurTime() + get_int("bl_prep_time", 30)
    game.CleanUpMap()
    for _, ply in ipairs(player.GetAll()) do
      if IsValid(ply) then
        ply.BLTTT_LateJoiner = false
        spawn_player(ply, true)
      end
    end
    assign_roles()
    push_event("phase_prep", { ends_at = BL.RoundManager.State.next_phase_time })
  elseif phase == PHASES.ACTIVE then
    BL.RoundManager.State.next_phase_time = CurTime() + get_int("bl_round_time", 600)
    for _, ply in ipairs(player.GetAll()) do
      if IsValid(ply) then
        if ply.BLTTT_LateJoiner then
          make_spectator(ply)
        else
          ply:Freeze(false)
        end
      end
    end
    push_event("phase_active", { ends_at = BL.RoundManager.State.next_phase_time })
  elseif phase == PHASES.POST then
    BL.RoundManager.State.next_phase_time = CurTime() + get_int("bl_post_time", 15)
    for _, ply in ipairs(player.GetAll()) do
      if IsValid(ply) then
        ply:Freeze(true)
      end
    end
    push_event("phase_post", { ends_at = BL.RoundManager.State.next_phase_time })
  end

  broadcast_snapshot()
  return true
end

function BL.RoundManager.Tick()
  if not BL.State or not BL.State.Data then
    return
  end

  local phase = BL.State.Data.phase
  if phase == PHASES.LOBBY then
    local min_players = get_int("bl_min_players", 4)
    if #player.GetAll() >= min_players then
      BL.RoundManager.SetPhase(PHASES.PREP)
    end
  elseif phase == PHASES.PREP then
    if CurTime() >= (BL.RoundManager.State.next_phase_time or 0) then
      BL.RoundManager.SetPhase(PHASES.ACTIVE)
    end
  elseif phase == PHASES.ACTIVE then
    if CurTime() >= (BL.RoundManager.State.next_phase_time or 0) then
      end_round("timeout", "none")
    else
      check_win_condition()
    end
  elseif phase == PHASES.POST then
    if CurTime() >= (BL.RoundManager.State.next_phase_time or 0) then
      BL.RoundManager.SetPhase(PHASES.LOBBY)
    end
  end
end

function BL.RoundManager.ForceRoundStart()
  local phase = BL.State and BL.State.Data and BL.State.Data.phase or PHASES.LOBBY
  if phase == PHASES.ACTIVE then
    return false
  end
  BL.RoundManager.SetPhase(PHASES.PREP)
  return true
end

function BL.RoundManager.ForceRoundEnd()
  local phase = BL.State and BL.State.Data and BL.State.Data.phase or PHASES.LOBBY
  if phase ~= PHASES.ACTIVE then
    return false
  end
  end_round("forced", "none")
  return true
end

local function handle_player_join(ply)
  if not IsValid(ply) then
    return
  end

  clear_role(ply)

  local phase = BL.State and BL.State.Data and BL.State.Data.phase or PHASES.LOBBY
  if phase == PHASES.LOBBY then
    ply.BLTTT_LateJoiner = false
    timer.Simple(0, function()
      if IsValid(ply) then
        spawn_player(ply, false)
      end
    end)
  else
    ply.BLTTT_LateJoiner = true
    timer.Simple(0, function()
      if IsValid(ply) then
        make_spectator(ply)
      end
    end)
  end

  if BL.Net and BL.Net.SendSnapshot then
    BL.Net.SendSnapshot(ply)
  end
end

hook.Add("PlayerInitialSpawn", "BL.RoundManager.PlayerInitialSpawn", handle_player_join)

hook.Add("PlayerSpawn", "BL.RoundManager.PlayerSpawn", function(ply)
  if not IsValid(ply) then
    return
  end

  if ply.BLTTT_LateJoiner then
    timer.Simple(0, function()
      if IsValid(ply) then
        make_spectator(ply)
      end
    end)
  end
end)

hook.Add("PlayerDisconnected", "BL.RoundManager.PlayerDisconnected", function(_ply)
  if BL.State and BL.State.Data and BL.State.Data.phase == PHASES.ACTIVE then
    check_win_condition()
  end
end)

hook.Add("PlayerDeath", "BL.RoundManager.PlayerDeath", function(_ply)
  if BL.State and BL.State.Data and BL.State.Data.phase == PHASES.ACTIVE then
    check_win_condition()
  end
end)

hook.Add("Initialize", "BL.RoundManager.Initialize", function()
  timer.Remove(ROUND_TICK)
  timer.Create(ROUND_TICK, ROUND_TICK_INTERVAL, 0, function()
    BL.RoundManager.Tick()
  end)
end)

concommand.Add("bl_forceroundstart", function(ply)
  if IsValid(ply) and not ply:IsAdmin() then
    return
  end
  if not BL.RoundManager.ForceRoundStart() then
    return
  end
  push_event("admin_force_start", { by = IsValid(ply) and ply:Nick() or "console" })
end)

concommand.Add("bl_forceroundend", function(ply)
  if IsValid(ply) and not ply:IsAdmin() then
    return
  end
  if not BL.RoundManager.ForceRoundEnd() then
    return
  end
  push_event("admin_force_end", { by = IsValid(ply) and ply:Nick() or "console" })
end)
