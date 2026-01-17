BL = BL or {}
BL.Assets = BL.Assets or {}

BL.Assets.DefaultModel = BL.Assets.DefaultModel or "models/player/kleiner.mdl"
BL.Assets.DefaultMaterial = BL.Assets.DefaultMaterial or ""
BL.Assets.DefaultIcon = BL.Assets.DefaultIcon or "vgui/avatar_default"
BL.Assets.IconCache = BL.Assets.IconCache or {}
BL.Assets.MissingLogged = BL.Assets.MissingLogged or {}
BL.Assets.LogInterval = BL.Assets.LogInterval or 0.5
BL.Assets.LastLogTime = BL.Assets.LastLogTime or 0

local function log_missing_asset(kind, name)
  if type(kind) ~= "string" or kind == "" then
    return
  end
  local label = tostring(name or "unknown")
  local key = kind .. ":" .. label
  if BL.Assets.MissingLogged[key] then
    return
  end

  local now = CurTime and CurTime() or os.time()
  if now - (BL.Assets.LastLogTime or 0) < BL.Assets.LogInterval then
    return
  end

  BL.Assets.LastLogTime = now
  BL.Assets.MissingLogged[key] = true
  local message = string.format("Missing %s asset: %s", kind, label)

  if GM and GM.BLTTT_BootLog then
    GM.BLTTT_BootLog(message)
  else
    MsgC(Color(255, 120, 120), "[BLACKLAW_TTT] ", color_white, message .. "\n")
  end
end

function BL.Assets.LogMissing(kind, name)
  log_missing_asset(kind, name)
end

function BL.Assets.GetSafeModel(model, context)
  if type(model) == "string" and model ~= "" then
    if util and util.IsValidModel and util.IsValidModel(model) then
      return model
    end
    log_missing_asset("model", context or model)
  end
  return BL.Assets.DefaultModel
end

function BL.Assets.GetSafeMaterial(material_name, context)
  if type(material_name) == "string" and material_name ~= "" then
    if util and util.IsValidMaterial and util.IsValidMaterial(material_name) then
      return material_name
    end
    log_missing_asset("material", context or material_name)
  end
  return BL.Assets.DefaultMaterial
end

function BL.Assets.GetIconMaterial(path, context)
  if not CLIENT then
    return nil
  end
  local icon_path = path
  if type(icon_path) ~= "string" or icon_path == "" then
    icon_path = BL.Assets.DefaultIcon
  end

  if BL.Assets.IconCache[icon_path] then
    return BL.Assets.IconCache[icon_path]
  end

  if util and util.IsValidMaterial and not util.IsValidMaterial(icon_path) then
    log_missing_asset("icon", context or icon_path)
    icon_path = BL.Assets.DefaultIcon
  end

  local material = Material(icon_path, "smooth")
  BL.Assets.IconCache[icon_path] = material
  return material
end
