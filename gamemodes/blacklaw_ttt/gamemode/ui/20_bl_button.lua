BL = BL or {}
BL.UI = BL.UI or {}

local PANEL = {}

function PANEL:Init()
  self.Variant = "accent"
  self:SetFont(BL.UI.Style.Fonts.Button)
  self:SetTextColor(BL.UI.Style.Colors.Text)
  self:SetTall(BL.UI.bl_ui_scale(36))
  self:SetCursor("hand")
end

function PANEL:SetVariant(variant)
  self.Variant = variant or "accent"
end

function PANEL:GetVariantColors()
  local colors = BL.UI.Style.Colors

  if self.Variant == "primary" then
    return colors.Primary, colors.PrimaryHover, colors.Text
  end

  if self.Variant == "ghost" then
    return colors.Ghost, colors.SurfaceStrong, colors.TextMuted
  end

  return colors.Accent, colors.AccentHover, colors.Text
end

function PANEL:Paint(w, h)
  local style = BL.UI.Style
  local base, hover, text = self:GetVariantColors()
  local is_hovered = self:IsHovered()
  local is_down = self.Depressed
  local background = is_down and hover or (is_hovered and hover or base)

  draw.RoundedBox(style.Radii.md, 0, 0, w, h, background)

  if self.Variant == "ghost" then
    surface.SetDrawColor(style.Colors.Border)
    surface.DrawOutlinedRect(0, 0, w, h, 1)
  end

  self:SetTextColor(is_hovered and style.Colors.Text or text)

  return true
end

vgui.Register("BLButton", PANEL, "DButton")
