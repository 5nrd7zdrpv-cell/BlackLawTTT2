BL = BL or {}
BL.TTT2 = BL.TTT2 or {}
BL.TTT2.HUD = BL.TTT2.HUD or {}

local PANEL = {}

local function get_style()
  return BL.UI and BL.UI.Style or {}
end

local function format_timer(end_time)
  if type(end_time) ~= "number" then
    return "--:--"
  end
  local remaining = math.max(0, math.floor(end_time - CurTime()))
  local mins = math.floor(remaining / 60)
  local secs = remaining % 60
  return string.format("%02d:%02d", mins, secs)
end

local function format_phase(phase)
  if phase == "PREP" then
    return "Vorbereitung"
  end
  if phase == "ACTIVE" then
    return "Runde aktiv"
  end
  if phase == "POST" then
    return "Auswertung"
  end
  return "Lobby"
end

function PANEL:Init()
  self:SetMouseInputEnabled(false)
  self:SetKeyboardInputEnabled(false)
  self:SetPaintBackground(false)
  self:DockPadding(0, 0, 0, 0)
end

function PANEL:PerformLayout()
  local scale = BL.UI.Scale or function(value) return value end
  self:SetSize(scale(320), scale(180))
  self:SetPos(scale(32), ScrH() - scale(220))
end

function PANEL:Paint(w, h)
  local style = get_style()
  if not style.Colors then
    return
  end

  local snapshot = BL.TTT2.Net and BL.TTT2.Net.GetSnapshot and BL.TTT2.Net.GetSnapshot() or nil
  local self_data = snapshot and snapshot.self or {}
  local role_name = self_data.role_name or "Unbekannt"
  local phase_text = snapshot and format_phase(snapshot.phase) or "Lobby"
  local timer_text = snapshot and format_timer(snapshot.phase_end) or "--:--"

  draw.RoundedBox(style.Radii.lg, 0, 0, w, h, style.Colors.Surface)
  surface.SetDrawColor(style.Colors.CardBorder)
  surface.DrawOutlinedRect(0, 0, w, h, 1)

  local padding = style.Spacing.lg
  local row_gap = style.Spacing.md

  draw.SimpleText("Blacklaw TTT2", style.Fonts.Heading, padding, padding, style.Colors.Text)
  draw.SimpleText(phase_text, style.Fonts.Label, padding, padding + style.Spacing.lg, style.Colors.TextMuted)
  draw.SimpleText(timer_text, style.Fonts.Value, w - padding, padding, style.Colors.Text, TEXT_ALIGN_RIGHT)

  local y = padding + style.Spacing.lg + style.Spacing.md

  draw.SimpleText("Rolle", style.Fonts.Label, padding, y, style.Colors.TextMuted)
  draw.SimpleText(role_name, style.Fonts.Body, padding, y + style.Spacing.sm, style.Colors.Text)

  y = y + row_gap + style.Spacing.md
  draw.SimpleText("Leben", style.Fonts.Label, padding, y, style.Colors.TextMuted)
  draw.SimpleText(tostring(self_data.health or 0), style.Fonts.Body, padding, y + style.Spacing.sm, style.Colors.Text)

  local middle_x = w * 0.5
  draw.SimpleText("Rüstung", style.Fonts.Label, middle_x, y, style.Colors.TextMuted, TEXT_ALIGN_CENTER)
  draw.SimpleText(tostring(self_data.armor or 0), style.Fonts.Body, middle_x, y + style.Spacing.sm, style.Colors.Text, TEXT_ALIGN_CENTER)

  draw.SimpleText("Credits", style.Fonts.Label, w - padding, y, style.Colors.TextMuted, TEXT_ALIGN_RIGHT)
  draw.SimpleText(tostring(self_data.credits or 0), style.Fonts.Body, w - padding, y + style.Spacing.sm, style.Colors.Text, TEXT_ALIGN_RIGHT)
end

vgui.Register("BLTTT2HUD", PANEL, "DPanel")

local function ensure_hud()
  if IsValid(BL.TTT2.HUD.Panel) then
    return
  end
  BL.TTT2.HUD.Panel = vgui.Create("BLTTT2HUD", vgui.GetWorldPanel())
end

hook.Add("InitPostEntity", "BL.TTT2.HUD.Init", function()
  ensure_hud()
end)

hook.Add("OnScreenSizeChanged", "BL.TTT2.HUD.Resize", function()
  if IsValid(BL.TTT2.HUD.Panel) then
    BL.TTT2.HUD.Panel:InvalidateLayout(true)
  end
end)

hook.Add("HUDPaint", "BL.TTT2.HUD.Ensure", function()
  ensure_hud()
end)

hook.Add("HUDShouldDraw", "BL.TTT2.HUD.HideDefault", function(name)
  local blocked = {
    CHudHealth = true,
    CHudBattery = true,
    CHudAmmo = true,
    CHudSecondaryAmmo = true,
  }

  if blocked[name] then
    return false
  end
end)
