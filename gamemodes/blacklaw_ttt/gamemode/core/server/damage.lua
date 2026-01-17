BL = BL or {}
BL.Karma = BL.Karma or {}

local KARMA_DEFAULT = 1000
local KARMA_MIN = 1
local KARMA_MAX = 1000
local TEAMKILL_PENALTY = 400

local function get_config(name, fallback)
  if GM and GM.BLTTT and GM.BLTTT.GetConfigValue then
    local value = GM.BLTTT.GetConfigValue("Server", name)
    if value ~= nil then
      return value
    end
  end
  return fallback
end

local function is_karma_enabled()
  return get_config("bl_karma_enabled", true) == true
end

local function get_ff_scale()
  local value = get_config("bl_ff_scale", 0.5)
  if type(value) ~= "number" then
    return 0.5
  end
  return math.Clamp(value, 0, 1)
end

local function get_role_team(ply)
  if not IsValid(ply) then
    return nil
  end
  local role_id = ply.BLTTT_RoleId or 0
  if BL.Roles and BL.Roles.GetRoleTeam then
    return BL.Roles.GetRoleTeam(role_id)
  end
  return nil
end

local function is_same_team(attacker, target)
  if not IsValid(attacker) or not IsValid(target) then
    return false
  end
  if attacker == target then
    return false
  end
  local attacker_team = get_role_team(attacker)
  local target_team = get_role_team(target)
  return attacker_team ~= nil and attacker_team == target_team
end

local function clamp_karma(value)
  return math.Clamp(math.floor(value), KARMA_MIN, KARMA_MAX)
end

function BL.Karma.Get(ply)
  if not IsValid(ply) then
    return KARMA_DEFAULT
  end
  if type(ply.BLTTT_Karma) == "number" then
    return ply.BLTTT_Karma
  end
  return KARMA_DEFAULT
end

function BL.Karma.Set(ply, value)
  if not IsValid(ply) then
    return
  end
  local clamped = clamp_karma(value)
  ply.BLTTT_Karma = clamped
  if ply.SetNWInt then
    ply:SetNWInt("blttt_karma", clamped)
  end
end

function BL.Karma.Reset(ply)
  BL.Karma.Set(ply, KARMA_DEFAULT)
end

function BL.Karma.ResetAll()
  for _, ply in ipairs(player.GetAll()) do
    if IsValid(ply) then
      BL.Karma.Reset(ply)
    end
  end
end

function BL.Karma.ApplyPenalty(ply, amount)
  if not IsValid(ply) then
    return
  end
  if type(amount) ~= "number" then
    return
  end
  local current = BL.Karma.Get(ply)
  BL.Karma.Set(ply, current - amount)
end

local function get_karma_multiplier(attacker)
  if not is_karma_enabled() then
    return 1
  end
  if not IsValid(attacker) then
    return 1
  end
  local karma = BL.Karma.Get(attacker)
  return math.Clamp(karma / KARMA_MAX, 0.1, 1)
end

hook.Add("PlayerInitialSpawn", "BL.Karma.PlayerInitialSpawn", function(ply)
  if not IsValid(ply) then
    return
  end
  if not is_karma_enabled() then
    return
  end
  BL.Karma.Reset(ply)
end)

hook.Add("EntityTakeDamage", "BL.Damage.ApplyRules", function(target, dmginfo)
  if not IsValid(target) then
    return
  end
  if not dmginfo then
    return
  end

  local attacker = dmginfo:GetAttacker()
  if not IsValid(attacker) or not attacker:IsPlayer() then
    return
  end

  local is_player_target = target:IsPlayer()
  local friendly = is_player_target and is_same_team(attacker, target)
  local multiplier = 1

  multiplier = multiplier * get_karma_multiplier(attacker)

  if friendly then
    multiplier = multiplier * get_ff_scale()
  end

  if multiplier ~= 1 then
    dmginfo:ScaleDamage(multiplier)
  end

  if friendly and is_karma_enabled() then
    local damage = dmginfo:GetDamage()
    if damage > 0 then
      BL.Karma.ApplyPenalty(attacker, math.max(1, math.floor(damage * 1.5)))
    end
  end
end)

hook.Add("PlayerShouldTakeDamage", "BL.Damage.FriendlyFireGate", function(target, attacker)
  if not IsValid(target) or not IsValid(attacker) then
    return
  end
  if not attacker:IsPlayer() or not target:IsPlayer() then
    return
  end
  if not is_same_team(attacker, target) then
    return
  end
  if get_ff_scale() <= 0 then
    return false
  end
end)

hook.Add("PlayerDeath", "BL.Karma.TeamKillPenalty", function(victim, _inflictor, attacker)
  if not is_karma_enabled() then
    return
  end
  if not IsValid(victim) or not IsValid(attacker) then
    return
  end
  if not attacker:IsPlayer() then
    return
  end
  if not is_same_team(attacker, victim) then
    return
  end
  BL.Karma.ApplyPenalty(attacker, TEAMKILL_PENALTY)
end)
