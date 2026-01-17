local function blt_boot_log(message)
  if GM and GM.BLTTT_BootLog then
    GM:BLTTT_BootLog(message)
    return
  end
  MsgC(Color(80, 200, 255), "[BLACKLAW_TTT] ", color_white, message .. "\n")
end

GM.BLTTT = GM.BLTTT or {}
GM.BLTTT.Config = GM.BLTTT.Config or { Server = {}, Client = {} }
GM.BLTTT.ConVars = GM.BLTTT.ConVars or {}

local function register_server_convar(name, defaultValue, helpText, options)
  if not SERVER then
    return
  end

  local flags = FCVAR_ARCHIVE + FCVAR_NOTIFY
  if options and options.flags then
    flags = options.flags
  end

  local cvar = CreateConVar(
    name,
    tostring(defaultValue),
    flags,
    helpText,
    options and options.min or nil,
    options and options.max or nil
  )

  GM.BLTTT.ConVars[name] = cvar
  GM.BLTTT.Config.Server[name] = {
    ConVar = cvar,
    Default = defaultValue,
    Help = helpText,
    Type = options and options.type or "string",
    Min = options and options.min or nil,
    Max = options and options.max or nil
  }
end

local function register_client_convar(name, defaultValue, helpText, options)
  if not CLIENT then
    return
  end

  local flags = FCVAR_ARCHIVE
  if options and options.flags then
    flags = options.flags
  end

  local cvar = CreateClientConVar(
    name,
    tostring(defaultValue),
    true,
    false,
    helpText,
    options and options.min or nil,
    options and options.max or nil
  )

  GM.BLTTT.ConVars[name] = cvar
  GM.BLTTT.Config.Client[name] = {
    ConVar = cvar,
    Default = defaultValue,
    Help = helpText,
    Type = options and options.type or "string",
    Min = options and options.min or nil,
    Max = options and options.max or nil
  }
end

function GM.BLTTT.GetConfigValue(scope, name)
  local group = GM.BLTTT.Config[scope]
  if not group then
    return nil
  end

  local entry = group[name]
  if not entry or not entry.ConVar then
    return nil
  end

  if entry.Type == "bool" then
    return entry.ConVar:GetBool()
  end

  if entry.Type == "int" then
    return entry.ConVar:GetInt()
  end

  if entry.Type == "float" then
    return entry.ConVar:GetFloat()
  end

  return entry.ConVar:GetString()
end

register_server_convar("bl_round_time", 600, "Round duration in seconds.", { type = "int", min = 60, max = 3600 })
register_server_convar("bl_prep_time", 30, "Preparation time before the round starts.", { type = "int", min = 5, max = 300 })
register_server_convar("bl_post_time", 15, "Post-round time after a round ends.", { type = "int", min = 5, max = 120 })
register_server_convar("bl_min_players", 4, "Minimum players required to start a round.", { type = "int", min = 1, max = 64 })
register_server_convar("bl_traitor_ratio", 0.25, "Ratio of traitors per player count.", { type = "float", min = 0.05, max = 0.75 })
register_server_convar("bl_shop_enabled", 1, "Enable the equipment shop.", { type = "bool", min = 0, max = 1 })
register_server_convar("bl_karma_enabled", 1, "Enable the karma system.", { type = "bool", min = 0, max = 1 })
register_server_convar("bl_ff_scale", 0.5, "Friendly fire damage scale.", { type = "float", min = 0, max = 1 })
register_server_convar("bl_credits_start_traitor", 2, "Starting credits for traitors.", { type = "int", min = 0, max = 10 })
register_server_convar("bl_credits_kill", 1, "Credits awarded per kill.", { type = "int", min = 0, max = 5 })
register_server_convar("bl_admin_debug", 0, "Enable admin debug logging.", { type = "bool", min = 0, max = 1 })
register_server_convar("bl_workshop_collection_id", "", "Steam Workshop collection ID to mount.", { type = "string" })
register_server_convar("bl_workshop_ids_csv", "", "Comma-separated Workshop item IDs to mount.", { type = "string" })

register_client_convar("bl_ui_scale", 1, "UI scale multiplier.", { type = "float", min = 0.5, max = 2 })
register_client_convar("bl_ui_compact", 0, "Use compact UI layout.", { type = "bool", min = 0, max = 1 })
register_client_convar("bl_show_eventlog", 1, "Show the event log panel.", { type = "bool", min = 0, max = 1 })

blt_boot_log("Config + ConVars initialized")
