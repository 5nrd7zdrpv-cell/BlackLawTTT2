BL = BL or {}
BL.UI = BL.UI or {}

local PANEL = {}

function PANEL:Init()
  self.TitleText = ""
  self.SubtitleText = ""
  self:DockPadding(0, 0, 0, 0)
  self:SetPadding(BL.UI.Style.Spacing.lg)
end

function PANEL:SetPadding(amount)
  self:DockPadding(amount, amount, amount, amount)
end

function PANEL:SetTitle(text)
  self.TitleText = text or ""
end

function PANEL:SetSubtitle(text)
  self.SubtitleText = text or ""
end

function PANEL:Paint(w, h)
  local style = BL.UI.Style
  draw.RoundedBox(style.Radii.lg, 0, 0, w, h, style.Colors.Surface)
  surface.SetDrawColor(style.Colors.CardBorder)
  surface.DrawOutlinedRect(0, 0, w, h, 1)

  if self.TitleText ~= "" then
    draw.SimpleText(self.TitleText, style.Fonts.Heading, style.Spacing.lg, style.Spacing.lg, style.Colors.Text)
  end

  if self.SubtitleText ~= "" then
    local offset = style.Spacing.lg + BL.UI.bl_ui_scale(22)
    draw.SimpleText(self.SubtitleText, style.Fonts.Body, style.Spacing.lg, offset, style.Colors.TextMuted)
  end
end

vgui.Register("BLCard", PANEL, "DPanel")
