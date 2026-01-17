BL = BL or {}
BL.TTT2 = BL.TTT2 or {}
BL.TTT2.Scoreboard = BL.TTT2.Scoreboard or {}

local PANEL = {}

local function get_style()
  return BL.UI and BL.UI.Style or {}
end

local function apply_scroll_style(scroll)
  if not IsValid(scroll) then
    return
  end
  local style = get_style()
  local bar = scroll:GetVBar()
  if not IsValid(bar) then
    return
  end
  bar:SetWide(BL.UI.Scale(6))
  bar.Paint = function(_, w, h)
    draw.RoundedBox(style.Radii.md, 0, 0, w, h, style.Colors.Surface)
  end
  bar.btnGrip.Paint = function(_, w, h)
    draw.RoundedBox(style.Radii.md, 0, 0, w, h, style.Colors.CardBorder)
  end
  bar.btnUp.Paint = function() end
  bar.btnDown.Paint = function() end
end

function PANEL:Init()
  local style = get_style()
  self:SetSize(ScrW() * 0.6, ScrH() * 0.7)
  self:Center()
  self:SetVisible(false)
  self:SetMouseInputEnabled(true)
  self:SetKeyboardInputEnabled(false)

  self.Header = vgui.Create("DPanel", self)
  self.Header:SetTall(BL.UI.Scale(52))
  self.Header.Paint = function(_, w, h)
    draw.RoundedBox(style.Radii.lg, 0, 0, w, h, style.Colors.Surface)
    surface.SetDrawColor(style.Colors.CardBorder)
    surface.DrawOutlinedRect(0, 0, w, h, 1)

    draw.SimpleText("Blacklaw TTT2", style.Fonts.Heading, style.Spacing.lg, h * 0.5, style.Colors.Text, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
    draw.SimpleText("Scoreboard", style.Fonts.Body, w - style.Spacing.lg, h * 0.5, style.Colors.TextMuted, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
  end

  self.List = vgui.Create("DScrollPanel", self)
  apply_scroll_style(self.List)
end

function PANEL:PerformLayout(w, h)
  local style = get_style()
  self:Center()
  self.Header:SetPos(0, 0)
  self.Header:SetWide(w)
  self.List:SetPos(0, self.Header:GetTall() + style.Spacing.sm)
  self.List:SetSize(w, h - self.Header:GetTall() - style.Spacing.sm)
end

function PANEL:RefreshRows()
  if not IsValid(self.List) then
    return
  end

  self.List:Clear()

  local snapshot = BL.TTT2.Net and BL.TTT2.Net.GetSnapshot and BL.TTT2.Net.GetSnapshot() or nil
  local players = snapshot and snapshot.players or {}
  local style = get_style()
  local row_height = BL.UI.Scale(46)

  for _, entry in ipairs(players) do
    local row = self.List:Add("DPanel")
    row:SetTall(row_height)
    row:Dock(TOP)
    row:DockMargin(0, 0, 0, style.Spacing.xs)
    row.Paint = function(_, w, h)
      draw.RoundedBox(style.Radii.md, 0, 0, w, h, style.Colors.Surface)
      surface.SetDrawColor(style.Colors.Border)
      surface.DrawOutlinedRect(0, 0, w, h, 1)

      local name_color = entry.alive and style.Colors.Text or style.Colors.TextMuted
      draw.SimpleText(entry.name or "Unbekannt", style.Fonts.Body, style.Spacing.lg, h * 0.5, name_color, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)

      local role_name = entry.role_name or "?"
      draw.SimpleText(role_name, style.Fonts.Label, w * 0.6, h * 0.5, style.Colors.TextMuted, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
      draw.SimpleText(tostring(entry.ping or 0), style.Fonts.Label, w - style.Spacing.lg, h * 0.5, style.Colors.TextMuted, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
    end
  end
end

vgui.Register("BLTTT2Scoreboard", PANEL, "DPanel")

local function ensure_scoreboard()
  if IsValid(BL.TTT2.Scoreboard.Panel) then
    return BL.TTT2.Scoreboard.Panel
  end
  BL.TTT2.Scoreboard.Panel = vgui.Create("BLTTT2Scoreboard", vgui.GetWorldPanel())
  return BL.TTT2.Scoreboard.Panel
end

hook.Add("ScoreboardShow", "BL.TTT2.Scoreboard.Show", function()
  local panel = ensure_scoreboard()
  if not IsValid(panel) then
    return
  end
  panel:SetVisible(true)
  panel:MakePopup()
  panel:RefreshRows()
  return false
end)

hook.Add("ScoreboardHide", "BL.TTT2.Scoreboard.Hide", function()
  if IsValid(BL.TTT2.Scoreboard.Panel) then
    BL.TTT2.Scoreboard.Panel:SetVisible(false)
  end
  return false
end)

hook.Add("Think", "BL.TTT2.Scoreboard.Refresh", function()
  if not IsValid(BL.TTT2.Scoreboard.Panel) then
    return
  end
  if not BL.TTT2.Scoreboard.Panel:IsVisible() then
    return
  end
  if not BL.TTT2.Scoreboard.NextRefresh or BL.TTT2.Scoreboard.NextRefresh < CurTime() then
    BL.TTT2.Scoreboard.NextRefresh = CurTime() + 1
    BL.TTT2.Scoreboard.Panel:RefreshRows()
  end
end)
