BL = BL or {}
BL.UI = BL.UI or {}

local PANEL = {}

function PANEL:Init()
  self.IsActive = false
  self:SetFont(BL.UI.Style.Fonts.Body)
  self:SetTextColor(BL.UI.Style.Colors.Text)
  self:SetTall(BL.UI.bl_ui_scale(36))
  self:SetCursor("hand")
  self:SetContentAlignment(4)
  self:SetTextInset(BL.UI.Style.Spacing.md, 0)
end

function PANEL:SetActive(active)
  self.IsActive = active and true or false
end

function PANEL:Paint(w, h)
  local style = BL.UI.Style
  local background = self.IsActive and style.Colors.RowActive or style.Colors.Row
  local border_color = self.IsActive and style.Colors.CardBorder or style.Colors.Border

  if self:IsHovered() then
    background = style.Colors.RowActive
  end

  draw.RoundedBox(style.Radii.md, 0, 0, w, h, background)
  surface.SetDrawColor(border_color)
  surface.DrawOutlinedRect(0, 0, w, h, 1)

  return true
end

vgui.Register("BLListRow", PANEL, "DButton")
