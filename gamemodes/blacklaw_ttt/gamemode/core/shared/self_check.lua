BL = BL or {}
BL.SelfCheck = BL.SelfCheck or {}

local function blt_log(message, color)
  MsgC(color or Color(80, 200, 255), "[BLACKLAW_TTT] ", color_white, message .. "\n")
end

local function log_error(message)
  blt_log("SELF-CHECK ERROR: " .. message, Color(255, 80, 80))
end

local function log_ok(message)
  blt_log("SELF-CHECK: " .. message, Color(80, 200, 255))
end

local function check_required_files(required)
  local errors = {}
  local gamemode_name = engine.ActiveGamemode and engine.ActiveGamemode() or (GM and GM.FolderName) or "blacklaw_ttt"
  if gamemode_name == "" then
    gamemode_name = "blacklaw_ttt"
  end
  local base_path = "gamemodes/" .. gamemode_name .. "/gamemode/"
  for _, path in ipairs(required) do
    local resolved_path = base_path .. path
    if not file.Exists(resolved_path, "LUA") then
      errors[#errors + 1] = "Missing file: " .. resolved_path
    end
  end
  return errors
end

local function check_net_messages()
  local errors = {}
  local expected = {
    "Snapshot",
    "Event",
    "ClientEvent",
    "Notice",
    "ShopBuy",
    "ShopRadarPing",
    "AdminRequest",
    "AdminSnapshot",
    "AdminAction",
  }
  if not BL.Net or type(BL.Net.Messages) ~= "table" then
    errors[#errors + 1] = "BL.Net.Messages missing or invalid"
    return errors
  end

  for _, key in ipairs(expected) do
    local value = BL.Net.Messages[key]
    if type(value) ~= "string" or value == "" then
      errors[#errors + 1] = "Net message missing: " .. key
    end
  end
  return errors
end

local function check_convars()
  local errors = {}
  if not GM or not GM.BLTTT or not GM.BLTTT.Config then
    errors[#errors + 1] = "GM.BLTTT.Config missing"
    return errors
  end

  if SERVER then
    for name, entry in pairs(GM.BLTTT.Config.Server or {}) do
      if not entry or not entry.ConVar then
        errors[#errors + 1] = "Server ConVar missing: " .. tostring(name)
      end
    end
  end

  if CLIENT then
    for name, entry in pairs(GM.BLTTT.Config.Client or {}) do
      if not entry or not entry.ConVar then
        errors[#errors + 1] = "Client ConVar missing: " .. tostring(name)
      end
    end
  end

  return errors
end

function BL.SelfCheck.Run()
  local errors = {}
  local required = {
    "shared.lua",
    "net/shared/messages.lua",
    "net/shared/codec.lua",
    "core/shared/config.lua",
    "core/shared/assets.lua",
  }

  if SERVER then
    required[#required + 1] = "init.lua"
    required[#required + 1] = "core/server/state.lua"
    required[#required + 1] = "core/server/round_manager.lua"
  end

  if CLIENT then
    required[#required + 1] = "cl_init.lua"
    required[#required + 1] = "ui/40_bl_toast.lua"
    required[#required + 1] = "ui/70_bl_hud.lua"
  end

  for _, issue in ipairs(check_required_files(required)) do
    errors[#errors + 1] = issue
  end
  for _, issue in ipairs(check_net_messages()) do
    errors[#errors + 1] = issue
  end
  for _, issue in ipairs(check_convars()) do
    errors[#errors + 1] = issue
  end

  if #errors == 0 then
    log_ok("passed")
    return
  end

  for _, issue in ipairs(errors) do
    log_error(issue)
  end
  log_error(("Self-check failed with %d issue(s)."):format(#errors))
end

timer.Simple(0, function()
  if BL.SelfCheck and BL.SelfCheck.Run then
    BL.SelfCheck.Run()
  end
end)
