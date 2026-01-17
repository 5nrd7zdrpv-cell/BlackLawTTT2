BL = BL or {}
BL.UI = BL.UI or {}

local PANEL = {}

function PANEL:Init()
  self.Message = ""
  self.Kind = "info"
  self.Duration = 4
  self.CreatedAt = CurTime()
  self.Alpha = 0
  self:SetAlpha(0)
  self:SetTall(BL.UI.bl_ui_scale(48))
  self:DockPadding(BL.UI.Style.Spacing.md, BL.UI.Style.Spacing.sm, BL.UI.Style.Spacing.md, BL.UI.Style.Spacing.sm)
end

function PANEL:SetMessage(text)
  self.Message = text or ""
end

function PANEL:SetKind(kind)
  self.Kind = kind or "info"
end

function PANEL:SetDuration(seconds)
  self.Duration = seconds or self.Duration
end

function PANEL:GetKindColor()
  local colors = BL.UI.Style.Colors
  if self.Kind == "success" then
    return colors.ToastSuccess
  end
  if self.Kind == "error" then
    return colors.ToastError
  end
  return colors.ToastInfo
end

function PANEL:Paint(w, h)
  local style = BL.UI.Style
  draw.RoundedBox(style.Radii.md, 0, 0, w, h, self:GetKindColor())
  surface.SetDrawColor(style.Colors.CardBorder)
  surface.DrawOutlinedRect(0, 0, w, h, 1)
  draw.SimpleText(self.Message, style.Fonts.Body, style.Spacing.sm, h * 0.5, style.Colors.Text, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)

  return true
end

function PANEL:Think()
  local elapsed = CurTime() - self.CreatedAt
  local fade_out_time = math.max(self.Duration - 0.6, 0)

  if elapsed >= self.Duration then
    self:Remove()
    return
  end

  if elapsed < 0.25 then
    self.Alpha = Lerp(elapsed / 0.25, 0, 255)
  elseif elapsed > fade_out_time then
    local fade = math.Clamp((self.Duration - elapsed) / 0.6, 0, 1)
    self.Alpha = Lerp(fade, 0, 255)
  else
    self.Alpha = 255
  end

  self:SetAlpha(self.Alpha)
end

vgui.Register("BLToast", PANEL, "DPanel")
