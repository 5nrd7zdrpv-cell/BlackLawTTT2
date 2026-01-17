AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")

include("shared.lua")

local function blt_boot_log(message)
  if GM and GM.BLTTT_BootLog then
    GM.BLTTT_BootLog(message)
    return
  end
  MsgC(Color(80, 200, 255), "[BLACKLAW_TTT] ", color_white, message .. "\n")
end

blt_boot_log("Server init start")

local function blt_include_dir(dir)
  local files, _ = file.Find(dir .. "/*.lua", "LUA")
  for _, fileName in ipairs(files) do
    include(dir .. "/" .. fileName)
  end
end

blt_include_dir("core/server")
blt_include_dir("net/server")
blt_include_dir("admin")
blt_include_dir("persistence")
blt_include_dir("workshop")

blt_boot_log("Server init complete")
