if SERVER then
  AddCSLuaFile()
  AddCSLuaFile("blacklaw_ttt2/shared/bootstrap.lua")
end

if engine.ActiveGamemode and engine.ActiveGamemode() ~= "terrortown" then
  return
end

BL = BL or {}
BL.TTT2 = BL.TTT2 or {}

include("blacklaw_ttt2/shared/bootstrap.lua")
