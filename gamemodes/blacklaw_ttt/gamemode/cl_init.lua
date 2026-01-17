print("[BLACKLAW_TTT] cl_init.lua loaded (CLIENT)")

local function blt_safe(name, fn)
  local ok, err = xpcall(fn, debug.traceback)
  if not ok then
    print("[BLACKLAW_TTT][ERROR] " .. name)
    print(err)
  end
  return ok, err
end

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

blt_boot_log("Client init start")

local function blt_include_dir(dir)
  local gamemode_name = engine.ActiveGamemode and engine.ActiveGamemode() or (GM and GM.FolderName) or "blacklaw_ttt"
  if gamemode_name == "" then
    gamemode_name = "blacklaw_ttt"
  end
  local search_root = "gamemodes/" .. gamemode_name .. "/gamemode/"
  local files, _ = file.Find(search_root .. dir .. "/*.lua", "LUA")
  for _, fileName in ipairs(files) do
    local relative_path = dir .. "/" .. fileName
    blt_safe("include " .. relative_path, function()
      include(relative_path)
    end)
  end
end

blt_include_dir("core/client")
blt_include_dir("net/client")
blt_include_dir("ui")

blt_boot_log("Client init complete")
