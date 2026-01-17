local function blt_boot_log(message)
  if GM and GM.BLTTT_BootLog then
    GM.BLTTT_BootLog(message)
    return
  end
  MsgC(Color(80, 200, 255), "[BLACKLAW_TTT] ", color_white, message .. "\n")
end

BL = BL or {}
BL.Roles = BL.Roles or {}

BL.Roles.IDS = BL.Roles.IDS or {
  INNOCENT = 1,
  TRAITOR = 2,
}

BL.Roles.Teams = BL.Roles.Teams or {
  TEAM_INNO = 1,
  TEAM_TRAITOR = 2,
}

BL.Roles.Registry = BL.Roles.Registry or {
  by_id = {},
  by_key = {},
  order = {},
}

local function normalize_role_key(key)
  if type(key) ~= "string" or key == "" then
    return nil
  end
  return string.upper(key)
end

function BL.Roles.Register(role)
  if type(role) ~= "table" then
    return false
  end

  local id = role.id
  local key = normalize_role_key(role.key)
  if type(id) ~= "number" or id <= 0 then
    return false
  end
  if not key then
    return false
  end

  role.key = key
  BL.Roles.Registry.by_id[id] = role
  BL.Roles.Registry.by_key[key] = role
  BL.Roles.Registry.order[#BL.Roles.Registry.order + 1] = role
  return true
end

function BL.Roles.GetRoleById(id)
  if type(id) ~= "number" then
    return nil
  end
  return BL.Roles.Registry.by_id[id]
end

function BL.Roles.GetRoleByKey(key)
  local normalized = normalize_role_key(key)
  if not normalized then
    return nil
  end
  return BL.Roles.Registry.by_key[normalized]
end

function BL.Roles.GetRoleKey(id)
  local role = BL.Roles.GetRoleById(id)
  return role and role.key or ""
end

function BL.Roles.GetRoleName(id)
  local role = BL.Roles.GetRoleById(id)
  return role and role.name or ""
end

function BL.Roles.GetRoleTeam(id)
  local role = BL.Roles.GetRoleById(id)
  return role and role.team or nil
end

function BL.Roles.GetLoadout(id)
  local role = BL.Roles.GetRoleById(id)
  if not role then
    return nil
  end
  return role.default_loadout
end

function BL.Roles.GetCreditRules(id)
  local role = BL.Roles.GetRoleById(id)
  if not role then
    return nil
  end
  return role.credit_rules
end

BL.Roles.Register({
  id = BL.Roles.IDS.INNOCENT,
  key = "INNOCENT",
  name = "Innocent",
  description = "Find the traitors and survive.",
  team = BL.Roles.Teams.TEAM_INNO,
  default_loadout = {
    "weapon_crowbar",
    "weapon_pistol",
  },
  credit_rules = {
    start = 0,
    kill = 0,
  },
})

BL.Roles.Register({
  id = BL.Roles.IDS.TRAITOR,
  key = "TRAITOR",
  name = "Traitor",
  description = "Eliminate the innocents without being caught.",
  team = BL.Roles.Teams.TEAM_TRAITOR,
  default_loadout = {
    "weapon_crowbar",
    "weapon_pistol",
  },
  credit_rules = {
    start = 2,
    kill = 1,
  },
})

blt_boot_log("Roles registry ready")
