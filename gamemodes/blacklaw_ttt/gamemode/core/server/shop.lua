BL = BL or {}
BL.Shop = BL.Shop or {}

BL.Shop.Registry = BL.Shop.Registry or {
  by_id = {},
  order = {},
}

BL.Shop.State = BL.Shop.State or {
  round_counts = {},
  player_counts = {},
}

local DEFAULT_RADAR_INTERVAL = 8

local function normalize_id(value)
  if type(value) ~= "string" then
    return nil
  end
  local trimmed = string.Trim(value)
  if trimmed == "" then
    return nil
  end
  local lowered = string.lower(trimmed)
  if not string.match(lowered, "^[a-z0-9_]+$") then
    return nil
  end
  return lowered
end

local function get_role_id(ply)
  if not IsValid(ply) then
    return 0
  end
  return ply.BLTTT_RoleId or 0
end

local function get_round_phase()
  if BL.State and BL.State.Data then
    return BL.State.Data.phase
  end
  return nil
end

function BL.Shop.Register(item)
  if type(item) ~= "table" then
    return false
  end

  local id = normalize_id(item.id)
  if not id then
    return false
  end
  if BL.Shop.Registry.by_id[id] then
    return false
  end

  local entry = {
    id = id,
    name = item.name or id,
    price = math.max(0, math.floor(tonumber(item.price) or 0)),
    role_allow = item.role_allow or {},
    per_round_limit = math.max(0, math.floor(tonumber(item.per_round_limit) or 0)),
    per_player_limit = math.max(0, math.floor(tonumber(item.per_player_limit) or 0)),
    grant_fn = item.grant_fn,
  }

  BL.Shop.Registry.by_id[id] = entry
  BL.Shop.Registry.order[#BL.Shop.Registry.order + 1] = entry
  return true
end

function BL.Shop.GetItem(id)
  local normalized = normalize_id(id)
  if not normalized then
    return nil
  end
  return BL.Shop.Registry.by_id[normalized]
end

function BL.Shop.ResetRoundLimits()
  BL.Shop.State.round_counts = {}
  BL.Shop.State.player_counts = {}

  for _, ply in ipairs(player.GetAll()) do
    if IsValid(ply) then
      ply.BLTTT_RadarActive = false
      ply.BLTTT_RadarNextPing = nil
    end
  end
end

function BL.Shop.ClearDisguises()
  for _, ply in ipairs(player.GetAll()) do
    if IsValid(ply) and ply.BLTTT_DisguiserOriginalModel then
      ply:SetModel(ply.BLTTT_DisguiserOriginalModel)
      ply:SetMaterial(ply.BLTTT_DisguiserOriginalMaterial or "")
    end
    if IsValid(ply) then
      ply.BLTTT_DisguiserOriginalModel = nil
      ply.BLTTT_DisguiserOriginalMaterial = nil
      ply.BLTTT_Disguised = false
    end
  end
end

function BL.Shop.OnPhaseChanged(phase)
  if phase == "PREP" then
    BL.Shop.ResetRoundLimits()
    BL.Shop.ClearDisguises()
  elseif phase == "POST" then
    BL.Shop.ClearDisguises()
  end
end

local function can_afford(ply, price)
  if not BL.Credits or not BL.Credits.Get then
    return false
  end
  return BL.Credits.Get(ply) >= price
end

local function role_allowed(item, role_id)
  if type(item.role_allow) ~= "table" then
    return true
  end
  if next(item.role_allow) == nil then
    return true
  end
  return item.role_allow[role_id] == true
end

local function get_round_count(item_id)
  return BL.Shop.State.round_counts[item_id] or 0
end

local function increment_round_count(item_id)
  BL.Shop.State.round_counts[item_id] = get_round_count(item_id) + 1
end

local function get_player_count(ply, item_id)
  if not IsValid(ply) then
    return 0
  end
  local steamid = ply:SteamID64() or ""
  if steamid == "" then
    return 0
  end
  local entry = BL.Shop.State.player_counts[steamid]
  if not entry then
    return 0
  end
  return entry[item_id] or 0
end

local function increment_player_count(ply, item_id)
  if not IsValid(ply) then
    return
  end
  local steamid = ply:SteamID64() or ""
  if steamid == "" then
    return
  end
  local entry = BL.Shop.State.player_counts[steamid]
  if not entry then
    entry = {}
    BL.Shop.State.player_counts[steamid] = entry
  end
  entry[item_id] = (entry[item_id] or 0) + 1
end

function BL.Shop.TryPurchase(ply, item_id)
  if not IsValid(ply) then
    return false
  end

  local item = BL.Shop.GetItem(item_id)
  if not item then
    return false
  end

  local phase = get_round_phase()
  if phase ~= "PREP" and phase ~= "ACTIVE" then
    return false
  end

  if not ply:Alive() then
    return false
  end

  local role_id = get_role_id(ply)
  if not role_allowed(item, role_id) then
    return false
  end

  if item.per_round_limit > 0 and get_round_count(item.id) >= item.per_round_limit then
    return false
  end

  if item.per_player_limit > 0 and get_player_count(ply, item.id) >= item.per_player_limit then
    return false
  end

  if not can_afford(ply, item.price) then
    return false
  end

  if type(item.grant_fn) ~= "function" then
    return false
  end

  local granted = item.grant_fn(ply, item)
  if granted ~= true then
    return false
  end

  if BL.Credits and BL.Credits.Add then
    BL.Credits.Add(ply, -item.price)
  end

  increment_round_count(item.id)
  increment_player_count(ply, item.id)
  return true
end

local function apply_armor(ply, amount, max)
  if not IsValid(ply) then
    return false
  end
  local current = ply:Armor()
  local cap = max or 100
  local next_value = math.min(current + amount, cap)
  ply:SetArmor(next_value)
  return true
end

local function grant_radar(ply)
  if not IsValid(ply) then
    return false
  end
  ply.BLTTT_RadarActive = true
  ply.BLTTT_RadarNextPing = 0
  return true
end

local function grant_silenced_pistol(ply)
  if not IsValid(ply) then
    return false
  end
  local weapon = ply:GetWeapon("weapon_pistol")
  if not IsValid(weapon) then
    weapon = ply:Give("weapon_pistol")
  end
  if not IsValid(weapon) then
    return false
  end

  weapon.Primary = weapon.Primary or {}
  weapon.Primary.Recoil = 0.4
  weapon.Primary.Sound = "Weapon_USP.SilencedShot"
  weapon.BLTTT_Silenced = true
  return true
end

local function grant_disguiser(ply)
  if not IsValid(ply) then
    return false
  end

  if not ply.BLTTT_DisguiserOriginalModel then
    ply.BLTTT_DisguiserOriginalModel = ply:GetModel()
    ply.BLTTT_DisguiserOriginalMaterial = ply:GetMaterial()
  end

  local models = player_manager.AllValidModels()
  local model_list = {}
  for _, model in pairs(models) do
    model_list[#model_list + 1] = model
  end

  if #model_list == 0 then
    return false
  end

  local selection = model_list[math.random(#model_list)]
  ply:SetModel(selection)
  ply:SetMaterial("models/shiny")
  ply.BLTTT_Disguised = true
  return true
end

local function grant_medkit(ply)
  if not IsValid(ply) then
    return false
  end
  local medkit = ents.Create("bl_medkit")
  if not IsValid(medkit) then
    return false
  end
  local forward = ply:GetForward()
  medkit:SetPos(ply:GetPos() + forward * 30 + Vector(0, 0, 20))
  medkit:SetAngles(Angle(0, ply:EyeAngles().y, 0))
  medkit:SetOwner(ply)
  medkit:Spawn()
  return true
end

BL.Shop.Register({
  id = "traitor_armor",
  name = "Traitor-Rüstung",
  price = 2,
  role_allow = {
    [BL.Roles and BL.Roles.IDS and BL.Roles.IDS.TRAITOR or 0] = true,
  },
  per_round_limit = 6,
  per_player_limit = 1,
  grant_fn = function(ply)
    return apply_armor(ply, 60, 100)
  end,
})

BL.Shop.Register({
  id = "traitor_radar",
  name = "Traitor-Radar",
  price = 2,
  role_allow = {
    [BL.Roles and BL.Roles.IDS and BL.Roles.IDS.TRAITOR or 0] = true,
  },
  per_round_limit = 3,
  per_player_limit = 1,
  grant_fn = function(ply)
    return grant_radar(ply)
  end,
})

BL.Shop.Register({
  id = "traitor_silenced_pistol",
  name = "Schallgedämpfte Pistole",
  price = 1,
  role_allow = {
    [BL.Roles and BL.Roles.IDS and BL.Roles.IDS.TRAITOR or 0] = true,
  },
  per_round_limit = 6,
  per_player_limit = 1,
  grant_fn = function(ply)
    return grant_silenced_pistol(ply)
  end,
})

BL.Shop.Register({
  id = "traitor_disguiser",
  name = "Disguiser",
  price = 1,
  role_allow = {
    [BL.Roles and BL.Roles.IDS and BL.Roles.IDS.TRAITOR or 0] = true,
  },
  per_round_limit = 4,
  per_player_limit = 1,
  grant_fn = function(ply)
    return grant_disguiser(ply)
  end,
})

BL.Shop.Register({
  id = "inno_medkit",
  name = "Medkit",
  price = 1,
  role_allow = {
    [BL.Roles and BL.Roles.IDS and BL.Roles.IDS.INNOCENT or 0] = true,
  },
  per_round_limit = 6,
  per_player_limit = 1,
  grant_fn = function(ply)
    return grant_medkit(ply)
  end,
})

BL.Shop.Register({
  id = "inno_kevlar",
  name = "Kevlar",
  price = 1,
  role_allow = {
    [BL.Roles and BL.Roles.IDS and BL.Roles.IDS.INNOCENT or 0] = true,
  },
  per_round_limit = 8,
  per_player_limit = 1,
  grant_fn = function(ply)
    return apply_armor(ply, 25, 50)
  end,
})

hook.Add("Think", "BL.Shop.RadarThink", function()
  if not BL.Net or not BL.Net.Messages or not BL.Net.Messages.ShopRadarPing then
    return
  end

  for _, ply in ipairs(player.GetAll()) do
    if IsValid(ply) and ply.BLTTT_RadarActive and ply:Alive() then
      local role_id = ply.BLTTT_RoleId or 0
      if BL.Roles and BL.Roles.IDS and role_id ~= BL.Roles.IDS.TRAITOR then
        ply.BLTTT_RadarActive = false
        ply.BLTTT_RadarNextPing = nil
      else
        local next_ping = ply.BLTTT_RadarNextPing or 0
        if CurTime() >= next_ping then
          ply.BLTTT_RadarNextPing = CurTime() + DEFAULT_RADAR_INTERVAL
          local targets = {}
          for _, target in ipairs(player.GetAll()) do
            if IsValid(target) and target ~= ply and target:Alive() then
              targets[#targets + 1] = {
                pos = target:GetPos(),
                name = target:Nick(),
              }
            end
          end

          net.Start(BL.Net.Messages.ShopRadarPing)
          net.WriteUInt(#targets, 6)
          for _, entry in ipairs(targets) do
            net.WriteVector(entry.pos)
            net.WriteString(entry.name)
          end
          net.Send(ply)
        end
      end
    end
  end
end)
