BL = BL or {}
BL.Credits = BL.Credits or {}

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
  return math.max(0, math.floor(value))
end

function BL.Credits.Get(ply)
  if not IsValid(ply) then
    return 0
  end
  local value = ply.BLTTT_Credits
  if type(value) ~= "number" then
    return 0
  end
  return math.max(0, math.floor(value))
end

function BL.Credits.Set(ply, amount)
  if not IsValid(ply) then
    return
  end
  local value = tonumber(amount) or 0
  ply.BLTTT_Credits = math.max(0, math.floor(value))
end

function BL.Credits.Add(ply, amount)
  if not IsValid(ply) then
    return
  end
  local delta = tonumber(amount) or 0
  if delta == 0 then
    return
  end
  local current = BL.Credits.Get(ply)
  BL.Credits.Set(ply, current + delta)
end

function BL.Credits.Reset(ply)
  BL.Credits.Set(ply, 0)
end

function BL.Credits.ResetAll()
  for _, ply in ipairs(player.GetAll()) do
    if IsValid(ply) then
      BL.Credits.Reset(ply)
    end
  end
end

function BL.Credits.GrantStartingCredits()
  local traitor_start = get_int("bl_credits_start_traitor", 2)
  for _, ply in ipairs(player.GetAll()) do
    if IsValid(ply) and not ply.BLTTT_LateJoiner then
      if ply.BLTTT_RoleId == (BL.Roles and BL.Roles.IDS and BL.Roles.IDS.TRAITOR) then
        BL.Credits.Set(ply, traitor_start)
      else
        BL.Credits.Reset(ply)
      end
    end
  end
end

local function get_phase()
  return BL.State and BL.State.Data and BL.State.Data.phase or "LOBBY"
end

local function get_team_for_player(ply)
  if not IsValid(ply) then
    return nil
  end
  local role_id = ply.BLTTT_RoleId or 0
  if BL.Roles and BL.Roles.GetRoleTeam then
    return BL.Roles.GetRoleTeam(role_id)
  end
  return nil
end

hook.Add("PlayerInitialSpawn", "BL.Credits.PlayerInitialSpawn", function(ply)
  if IsValid(ply) then
    BL.Credits.Reset(ply)
  end
end)

hook.Add("PlayerDeath", "BL.Credits.PlayerDeath", function(victim, _inflictor, attacker)
  if not IsValid(victim) then
    return
  end

  if get_phase() ~= "ACTIVE" then
    return
  end

  if not IsValid(attacker) or attacker == victim or not attacker:IsPlayer() then
    return
  end

  if attacker.BLTTT_LateJoiner then
    return
  end

  local attacker_team = get_team_for_player(attacker)
  local victim_team = get_team_for_player(victim)
  if not attacker_team or not victim_team or attacker_team == victim_team then
    return
  end

  local reward = get_int("bl_credits_kill", 1)
  if reward <= 0 then
    return
  end

  BL.Credits.Add(attacker, reward)
end)
