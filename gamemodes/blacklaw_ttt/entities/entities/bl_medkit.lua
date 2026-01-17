AddCSLuaFile()

ENT.Type = "anim"
ENT.Base = "base_anim"
ENT.PrintName = "BL Medkit"
ENT.Spawnable = false
ENT.RenderGroup = RENDERGROUP_BOTH

local HEAL_AMOUNT = 35

function ENT:Initialize()
  if SERVER then
    self:SetModel("models/items/healthkit.mdl")
    self:PhysicsInit(SOLID_VPHYSICS)
    self:SetMoveType(MOVETYPE_VPHYSICS)
    self:SetSolid(SOLID_VPHYSICS)
    local phys = self:GetPhysicsObject()
    if IsValid(phys) then
      phys:Wake()
    end
    self:SetUseType(SIMPLE_USE)
  end
end

function ENT:Use(activator)
  if not SERVER then
    return
  end
  if not IsValid(activator) or not activator:IsPlayer() then
    return
  end
  local health = activator:Health()
  local max_health = activator:GetMaxHealth()
  if health >= max_health then
    return
  end
  activator:SetHealth(math.min(health + HEAL_AMOUNT, max_health))
  self:Remove()
end
