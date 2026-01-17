GM = GM or {}
GM.Name = "Blacklaw TTT"
GM.Author = "blacklaw_ttt"
GM.Email = ""
GM.Website = ""

local function blt_include(path)
  if SERVER then
    AddCSLuaFile(path)
  end
  include(path)
end

local function blt_include_dir(dir)
  local files, _ = file.Find(dir .. "/*.lua", "LUA")
  for _, fileName in ipairs(files) do
    blt_include(dir .. "/" .. fileName)
  end
end

local function blt_boot_log(message)
  MsgC(Color(80, 200, 255), "[BLACKLAW_TTT] ", color_white, message .. "\n")
end

blt_boot_log("Booting shared core")

blt_include_dir("blacklaw_ttt/gamemode/core/shared")

if SERVER then
  blt_boot_log("Shared ready (server)")
else
  blt_boot_log("Shared ready (client)")
end

GM.BLTTT_BootLog = blt_boot_log
