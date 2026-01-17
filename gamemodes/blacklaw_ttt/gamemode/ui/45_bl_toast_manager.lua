BL = BL or {}
BL.UI = BL.UI or {}

BL.UI.Toast = BL.UI.Toast or {}
BL.UI.Toast.Pending = BL.UI.Toast.Pending or {}

local STACK = {}

function STACK:Init()
  self:SetSize(ScrW(), ScrH())
  self:SetPos(0, 0)
  self:SetMouseInputEnabled(false)
  self:SetKeyboardInputEnabled(false)
end

function STACK:Think()
  local w, h = ScrW(), ScrH()
  if self:GetWide() ~= w or self:GetTall() ~= h then
    self:SetSize(w, h)
    self:InvalidateLayout(true)
  end
end

function STACK:PerformLayout()
  local style = BL.UI and BL.UI.Style or nil
  if not style or not style.Spacing then
    return
  end

  local padding = style.Spacing.lg
  local spacing = style.Spacing.sm
  local toast_width = BL.UI.bl_ui_scale(360)
  local x = self:GetWide() - padding - toast_width
  local y = padding

  for _, child in ipairs(self:GetChildren()) do
    if IsValid(child) then
      child:SetWide(toast_width)
      child:SetPos(x, y)
      y = y + child:GetTall() + spacing
    end
  end
end

vgui.Register("BLToastStack", STACK, "DPanel")

function BL.UI.Toast.CreateRoot()
  if IsValid(BL.UI.Toast.Root) then
    return BL.UI.Toast.Root
  end

  BL.UI.Toast.Root = vgui.Create("BLToastStack")
  for _, entry in ipairs(BL.UI.Toast.Pending) do
    if entry then
      BL.UI.Toast.Show(entry.message, entry.kind, entry.duration)
    end
  end
  BL.UI.Toast.Pending = {}
  return BL.UI.Toast.Root
end

function BL.UI.Toast.Show(message, kind, duration)
  if type(message) ~= "string" or message == "" then
    return
  end

  local root = IsValid(BL.UI.Toast.Root) and BL.UI.Toast.Root or nil
  if not IsValid(root) then
    BL.UI.Toast.Pending[#BL.UI.Toast.Pending + 1] = {
      message = message,
      kind = kind,
      duration = duration,
    }
    return
  end

  local toast = vgui.Create("BLToast", root)
  toast:SetMessage(message)
  toast:SetKind(kind or "info")
  toast:SetDuration(duration or 4)
  root:InvalidateLayout(true)
end

hook.Add("InitPostEntity", "BL.UI.Toast.Init", function()
  BL.UI.Toast.CreateRoot()
end)
