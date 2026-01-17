local function blt_boot_log(message)
  if GM and GM.BLTTT_BootLog then
    GM.BLTTT_BootLog(message)
    return
  end
  MsgC(Color(80, 200, 255), "[BLACKLAW_TTT] ", color_white, message .. "\n")
end

blt_boot_log("Core shared bootstrap loaded")

GM.BLTTT = GM.BLTTT or {}
GM.BLTTT.Version = "0.1.0"

BL = BL or {}
BL.TEAMS = BL.TEAMS or {
  ALIVE = 1,
  SPECTATOR = 2,
}

if team and team.SetUp then
  team.SetUp(BL.TEAMS.ALIVE, "Alive", Color(80, 200, 255))
  team.SetUp(BL.TEAMS.SPECTATOR, "Spectator", Color(180, 180, 180))
end
