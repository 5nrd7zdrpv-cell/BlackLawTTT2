BL = BL or {}
BL.RoundManager = BL.RoundManager or {}

local PHASES = {
  LOBBY = "LOBBY",
  PREP = "PREP",
  ACTIVE = "ACTIVE",
  POST = "POST",
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

local function is_admin_debug_enabled()
  local value = get_config("bl_admin_debug", false)
  return value == true
end

local function should_allow_free_roam(ply)
  if not is_admin_debug_enabled() then
    return false
  end
  if not IsValid(ply) then
    return false
  end
  return BL.Perm and BL.Perm.Has and BL.Perm.Has(ply, "round.control")
end

local function is_player_alive(ply)
  if not IsValid(ply) then
    return false
  end
  if ply.BLTTT_Alive ~= nil then
    return ply.BLTTT_Alive
  end
  return ply:Alive()
end

local function set_player_alive(ply, is_alive)
  if not IsValid(ply) then
    return
  end
  ply.BLTTT_Alive = is_alive and true or false
  if ply.SetNWBool then
    ply:SetNWBool("blttt_alive", ply.BLTTT_Alive)
  end
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
  ply.BLTTT_RoleId = role or 0
  set_role_flags(ply, false, false)
end

local function clear_role(ply)
  ply.BLTTT_RoleId = 0
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
  set_player_alive(ply, false)
  if BL and BL.TEAMS and BL.TEAMS.SPECTATOR then
    ply:SetTeam(BL.TEAMS.SPECTATOR)
  end

  local spectate_target = nil
  for _, target in ipairs(player.GetAll()) do
    if IsValid(target) and target ~= ply and is_player_alive(target) then
      spectate_target = target
      break
    end
  end

  if should_allow_free_roam(ply) or not IsValid(spectate_target) then
    ply:Spectate(OBS_MODE_ROAMING)
    ply:SpectateEntity(nil)
  else
    ply:Spectate(OBS_MODE_CHASE)
    ply:SpectateEntity(spectate_target)
  end
  ply:Freeze(false)
end

local function apply_role_loadout(ply, role_id_override)
  if not IsValid(ply) then
    return
  end

  local role_id = role_id_override or ply.BLTTT_RoleId or 0
  if role_id == 0 and BL.Roles and BL.Roles.IDS then
    role_id = BL.Roles.IDS.INNOCENT
  end
  local loadout = BL.Roles and BL.Roles.GetLoadout and BL.Roles.GetLoadout(role_id) or {}
  if type(loadout) ~= "table" then
    return
  end

  ply:StripWeapons()
  ply:StripAmmo()
  for _, weapon in ipairs(loadout) do
    ply:Give(weapon)
  end
  ply:GiveAmmo(60, "Pistol", true)
end

local function spawn_player(ply, freeze)
  if not IsValid(ply) then
    return
  end
  ply:UnSpectate()
  ply:Spawn()
  set_player_alive(ply, true)
  if BL and BL.TEAMS and BL.TEAMS.ALIVE then
    ply:SetTeam(BL.TEAMS.ALIVE)
  end
  apply_role_loadout(ply, ply.BLTTT_RoleId)
  ply:Freeze(freeze or false)
end

local function create_corpse_for_player(ply)
  if not IsValid(ply) then
    return
  end

  local corpse = ents.Create("prop_ragdoll")
  if not IsValid(corpse) then
    return
  end

  corpse:SetModel(ply:GetModel())
  corpse:SetPos(ply:GetPos())
  corpse:SetAngles(ply:GetAngles())
  corpse:Spawn()
  corpse:Activate()

  corpse.BLTTT_VictimSteamID64 = ply:SteamID64()
  corpse.BLTTT_VictimRoleId = ply.BLTTT_RoleId or 0
  corpse.BLTTT_VictimRoleKey = BL.Roles and BL.Roles.GetRoleKey and BL.Roles.GetRoleKey(corpse.BLTTT_VictimRoleId) or ""
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
      set_role(ply, BL.Roles.IDS.TRAITOR)
    else
      set_role(ply, BL.Roles.IDS.INNOCENT)
    end
    apply_role_loadout(ply, ply.BLTTT_RoleId)
  end
end

local function reveal_roles()
  for _, ply in ipairs(player.GetAll()) do
    if IsValid(ply) then
      set_role_flags(ply, true, true)
      push_event("role_reveal", {
        steamid64 = ply:SteamID64(),
        name = ply:Nick(),
        role_id = ply.BLTTT_RoleId or 0,
        role_key = BL.Roles and BL.Roles.GetRoleKey and BL.Roles.GetRoleKey(ply.BLTTT_RoleId or 0) or "",
        role_name = BL.Roles and BL.Roles.GetRoleName and BL.Roles.GetRoleName(ply.BLTTT_RoleId or 0) or "",
      })
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

local function count_alive_roles()
  local traitors_alive = 0
  local innocents_alive = 0
  for _, ply in ipairs(player.GetAll()) do
    if IsValid(ply) and is_player_alive(ply) and not ply.BLTTT_LateJoiner then
      if ply.BLTTT_RoleId == BL.Roles.IDS.TRAITOR then
        traitors_alive = traitors_alive + 1
      elseif ply.BLTTT_RoleId == BL.Roles.IDS.INNOCENT then
        innocents_alive = innocents_alive + 1
      end
    end
  end
  return traitors_alive, innocents_alive
end

local function end_round(reason, winner)
  BL.RoundManager.State.last_summary = build_round_summary(reason, winner)
  if BL.State and BL.State.Data then
    BL.State.Data.post_round_summary = BL.RoundManager.State.last_summary
  end
  push_event("round_win", {
    winner = winner,
    reason = reason,
    round_id = BL.RoundManager.State.last_summary.round_id,
  })
  reveal_roles()
  BL.RoundManager.SetPhase(PHASES.POST)
  push_event("round_summary", BL.RoundManager.State.last_summary)
end

local function check_win_condition()
  local traitors_alive, innocents_alive = count_alive_roles()

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

local function handle_timeout()
  local traitors_alive, innocents_alive = count_alive_roles()
  if innocents_alive > 0 then
    if get_config("bl_timeout_innocents_win", true) == true then
      end_round("timeout", "innocents")
      return
    end
  end

  if traitors_alive <= 0 and innocents_alive <= 0 then
    end_round("timeout", "none")
    return
  end

  if innocents_alive <= 0 and traitors_alive > 0 then
    end_round("timeout", "traitors")
    return
  end

  end_round("timeout", "none")
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
    if BL.Karma and BL.Karma.ResetAll then
      BL.Karma.ResetAll()
    end
    if BL.RoundStats and BL.RoundStats.ResetAll then
      BL.RoundStats.ResetAll()
    end
    if BL.Credits and BL.Credits.ResetAll then
      BL.Credits.ResetAll()
    end
    for _, ply in ipairs(player.GetAll()) do
      if IsValid(ply) then
        ply.BLTTT_LateJoiner = false
        spawn_player(ply, true)
      end
    end
    assign_roles()
    if BL.Credits and BL.Credits.GrantStartingCredits then
      BL.Credits.GrantStartingCredits()
    end
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

  if BL.Shop and BL.Shop.OnPhaseChanged then
    BL.Shop.OnPhaseChanged(phase)
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
      handle_timeout()
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

function BL.RoundManager.AdminRestartRound()
  BL.RoundManager.SetPhase(PHASES.PREP)
end

function BL.RoundManager.AdminRespawn(ply, freeze)
  if not IsValid(ply) then
    return false
  end
  spawn_player(ply, freeze or false)
  return true
end

function BL.RoundManager.AdminSetRole(ply, role_id)
  if not IsValid(ply) then
    return false
  end
  if type(role_id) ~= "number" or role_id <= 0 then
    return false
  end
  set_role(ply, math.floor(role_id))
  if is_player_alive(ply) then
    apply_role_loadout(ply, ply.BLTTT_RoleId)
  end
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

  local phase = BL.State and BL.State.Data and BL.State.Data.phase or PHASES.LOBBY
  if phase == PHASES.ACTIVE and ply.BLTTT_Alive == false then
    timer.Simple(0, function()
      if IsValid(ply) then
        make_spectator(ply)
      end
    end)
  elseif ply.BLTTT_LateJoiner then
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

hook.Add("PlayerDeath", "BL.RoundManager.PlayerDeath", function(ply)
  if not IsValid(ply) then
    return
  end

  local phase = BL.State and BL.State.Data and BL.State.Data.phase or PHASES.LOBBY
  set_player_alive(ply, false)
  if BL and BL.TEAMS and BL.TEAMS.SPECTATOR then
    ply:SetTeam(BL.TEAMS.SPECTATOR)
  end
  local payload = {
    steamid64 = ply:SteamID64(),
    name = ply:Nick(),
    role_revealed = ply.BLTTT_RoleRevealed == true,
    role_public = ply.BLTTT_RolePublic == true,
  }
  if phase == PHASES.POST or payload.role_public then
    payload.role_id = ply.BLTTT_RoleId or 0
    payload.role_key = BL.Roles and BL.Roles.GetRoleKey and BL.Roles.GetRoleKey(payload.role_id) or ""
    payload.role_name = BL.Roles and BL.Roles.GetRoleName and BL.Roles.GetRoleName(payload.role_id) or ""
  end
  push_event("player_death", payload)

  if phase == PHASES.ACTIVE then
    timer.Simple(0, function()
      if IsValid(ply) then
        make_spectator(ply)
      end
    end)
    create_corpse_for_player(ply)
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
  if IsValid(ply) and (not BL.Perm or not BL.Perm.Has or not BL.Perm.Has(ply, "round.control")) then
    return
  end
  if not BL.RoundManager.ForceRoundStart() then
    return
  end
  push_event("admin_force_start", { by = IsValid(ply) and ply:Nick() or "console" })
end)

concommand.Add("bl_forceroundend", function(ply)
  if IsValid(ply) and (not BL.Perm or not BL.Perm.Has or not BL.Perm.Has(ply, "round.control")) then
    return
  end
  if not BL.RoundManager.ForceRoundEnd() then
    return
  end
  push_event("admin_force_end", { by = IsValid(ply) and ply:Nick() or "console" })
end)
