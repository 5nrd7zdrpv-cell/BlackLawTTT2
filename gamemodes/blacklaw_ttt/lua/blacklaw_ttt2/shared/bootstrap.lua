BL = BL or {}
BL.TTT2 = BL.TTT2 or {}
BL.TTT2.Version = "0.1.0"

local base_path = "blacklaw_ttt2/"

local shared_files = {
  "shared/validation.lua",
  "shared/net_messages.lua",
}

local client_files = {
  "client/net.lua",
  "client/ui/style.lua",
  "client/ui/hud.lua",
  "client/ui/scoreboard.lua",
}

local server_files = {
  "server/state.lua",
  "server/net.lua",
}

if SERVER then
  for _, file in ipairs(shared_files) do
    AddCSLuaFile(base_path .. file)
  end
  for _, file in ipairs(client_files) do
    AddCSLuaFile(base_path .. file)
  end
end

for _, file in ipairs(shared_files) do
  include(base_path .. file)
end

if SERVER then
  for _, file in ipairs(server_files) do
    include(base_path .. file)
  end
else
  for _, file in ipairs(client_files) do
    include(base_path .. file)
  end
end
