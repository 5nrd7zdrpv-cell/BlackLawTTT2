BL = BL or {}
BL.ACL = BL.ACL or {}
BL.ACL.Users = BL.ACL.Users or {}
BL.Perm = BL.Perm or {}

local ROLE_OWNER = "owner"
local ROLE_ADMIN = "admin"
local ROLE_MOD = "mod"

local ALL_PERMS = {
  ["round.control"] = true,
  ["player.action"] = true,
  ["logs.view"] = true,
  ["settings.edit"] = true,
  ["give.item"] = true,
}

local function clone_table(source)
  local copy = {}
  for key, value in pairs(source) do
    copy[key] = value
  end
  return copy
end

BL.Perm.RolePermissions = BL.Perm.RolePermissions or {
  [ROLE_OWNER] = clone_table(ALL_PERMS),
  [ROLE_ADMIN] = {
    ["round.control"] = true,
    ["player.action"] = true,
    ["logs.view"] = true,
    ["settings.edit"] = true,
    ["give.item"] = true,
  },
  [ROLE_MOD] = {
    ["player.action"] = true,
    ["logs.view"] = true,
  },
}

local function normalize_role(role)
  if type(role) ~= "string" then
    return nil
  end
  local trimmed = string.Trim(role)
  if trimmed == "" then
    return nil
  end
  return trimmed
end

function BL.Perm.GetRole(ply)
  if not IsValid(ply) then
    return ROLE_OWNER
  end

  local steamid64 = ply:SteamID64()
  local configured_role = BL.ACL.Users[steamid64]
  local normalized = normalize_role(configured_role)
  if normalized then
    return normalized
  end

  if ply.IsSuperAdmin and ply:IsSuperAdmin() then
    return ROLE_ADMIN
  end
  if ply.IsAdmin and ply:IsAdmin() then
    return ROLE_MOD
  end

  return nil
end

function BL.Perm.Has(ply, perm)
  if type(perm) ~= "string" or perm == "" then
    return false
  end
  if not IsValid(ply) then
    return true
  end

  local role = BL.Perm.GetRole(ply)
  if not role then
    return false
  end

  local perms = BL.Perm.RolePermissions[role]
  if type(perms) ~= "table" then
    return false
  end

  return perms[perm] == true
end
