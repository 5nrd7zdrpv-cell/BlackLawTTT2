GM = GM or {}
GM.Name = "Blacklaw TTT"
GM.Author = "blacklaw_ttt"
GM.Email = ""
GM.Website = ""
GM.Base = "sandbox"

DeriveGamemode("sandbox")

local side_label = SERVER and "SERVER" or "CLIENT"
print("[BLACKLAW_TTT] shared.lua loaded (" .. side_label .. ")")

local function blt_safe(name, fn)
  local ok, err = xpcall(fn, debug.traceback)
  if not ok then
    print("[BLACKLAW_TTT][ERROR] " .. name)
    print(err)
  end
  return ok, err
end

local function blt_include(path)
  if SERVER then
    blt_safe("AddCSLuaFile " .. path, function()
      AddCSLuaFile(path)
    end)
  end
  blt_safe("include " .. path, function()
    include(path)
  end)
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

blt_include_dir("core/shared")
blt_include_dir("net/shared")

if SERVER then
  blt_boot_log("Shared ready (server)")
else
  blt_boot_log("Shared ready (client)")
end

GM.BLTTT_BootLog = blt_boot_log
