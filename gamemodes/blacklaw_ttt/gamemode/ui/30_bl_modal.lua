BL = BL or {}
BL.UI = BL.UI or {}

local PANEL = {}

function PANEL:Init()
  self:SetSize(BL.UI.bl_ui_scale(520), BL.UI.bl_ui_scale(320))
  self:Center()
  self:SetTitle("")
  self:ShowCloseButton(false)
  self:SetDraggable(false)
  self.TitleText = ""

  self.Backdrop = vgui.Create("DPanel")
  self.Backdrop:SetSize(ScrW(), ScrH())
  self.Backdrop:SetPos(0, 0)
  self.Backdrop:SetZPos(-1)
  self.Backdrop:SetMouseInputEnabled(true)
  self.Backdrop.Paint = function(_, w, h)
    draw.RoundedBox(0, 0, 0, w, h, BL.UI.Style.Colors.Overlay)
  end
  self.Backdrop.OnMousePressed = function()
    if self.AllowBackdropClose then
      self:Close()
    end
  end

  self:SetParent(self.Backdrop)
  self:MakePopup()
  self:Center()
end

function PANEL:SetModalTitle(text)
  self.TitleText = text or ""
end

function PANEL:SetBackdropClosable(can_close)
  self.AllowBackdropClose = can_close and true or false
end

function PANEL:PerformLayout()
  self:Center()
end

function PANEL:Paint(w, h)
  local style = BL.UI.Style
  draw.RoundedBox(style.Radii.lg, 0, 0, w, h, style.Colors.Surface)
  surface.SetDrawColor(style.Colors.CardBorder)
  surface.DrawOutlinedRect(0, 0, w, h, 1)

  if self.TitleText ~= "" then
    draw.SimpleText(self.TitleText, style.Fonts.Heading, style.Spacing.lg, style.Spacing.lg, style.Colors.Text)
  end

  return true
end

function PANEL:OnRemove()
  if IsValid(self.Backdrop) then
    self.Backdrop:Remove()
  end
end

vgui.Register("BLModal", PANEL, "DFrame")
