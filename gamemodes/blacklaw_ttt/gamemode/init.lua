print("[BLACKLAW_TTT] init.lua loaded (SERVER)")

local function blt_safe(name, fn)
  local ok, err = xpcall(fn, debug.traceback)
  if not ok then
    print("[BLACKLAW_TTT][ERROR] " .. name)
    print(err)
  end
  return ok, err
end

blt_safe("AddCSLuaFile cl_init.lua", function()
  AddCSLuaFile("cl_init.lua")
end)
blt_safe("AddCSLuaFile shared.lua", function()
  AddCSLuaFile("shared.lua")
end)

blt_safe("include shared.lua", function()
  include("shared.lua")
end)

local function blt_boot_log(message)
  if GM and GM.BLTTT_BootLog then
    GM.BLTTT_BootLog(message)
    return
  end
  MsgC(Color(80, 200, 255), "[BLACKLAW_TTT] ", color_white, message .. "\n")
end

blt_boot_log("Server init start")

local function blt_addcs_dir(dir)
  local files, _ = file.Find(dir .. "/*.lua", "LUA")
  for _, fileName in ipairs(files) do
    local relative_path = dir .. "/" .. fileName
    blt_safe("AddCSLuaFile " .. relative_path, function()
      AddCSLuaFile(relative_path)
    end)
  end
end

local function blt_include_dir(dir)
  local files, _ = file.Find(dir .. "/*.lua", "LUA")
  for _, fileName in ipairs(files) do
    local relative_path = dir .. "/" .. fileName
    blt_safe("include " .. relative_path, function()
      include(relative_path)
    end)
  end
end

blt_addcs_dir("core/client")
blt_addcs_dir("net/client")
blt_addcs_dir("ui")

blt_include_dir("core/server")
blt_include_dir("net/server")
blt_include_dir("admin")
blt_include_dir("persistence")
blt_include_dir("workshop")

blt_boot_log("Server init complete")
