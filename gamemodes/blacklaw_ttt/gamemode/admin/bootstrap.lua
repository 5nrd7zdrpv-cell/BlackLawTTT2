local function blt_boot_log(message)
  if GM and GM.BLTTT_BootLog then
    GM:BLTTT_BootLog(message)
    return
  end
  MsgC(Color(80, 200, 255), "[BLACKLAW_TTT] ", color_white, message .. "\n")
end

blt_boot_log("Admin module loaded")
