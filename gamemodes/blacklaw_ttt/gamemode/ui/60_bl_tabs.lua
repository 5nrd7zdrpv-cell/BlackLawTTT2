BL = BL or {}
BL.UI = BL.UI or {}

local PANEL = {}

function PANEL:Init()
  self.Tabs = {}
  self.ActiveTab = nil

  self.Header = vgui.Create("DPanel", self)
  self.Header:Dock(TOP)
  self.Header:SetTall(BL.UI.bl_ui_scale(44))
  self.Header:DockPadding(BL.UI.Style.Spacing.sm, BL.UI.Style.Spacing.sm, BL.UI.Style.Spacing.sm, BL.UI.Style.Spacing.sm)
  self.Header.Paint = function(_, w, h)
    draw.RoundedBox(BL.UI.Style.Radii.md, 0, 0, w, h, BL.UI.Style.Colors.SurfaceStrong)
  end

  self.Body = vgui.Create("DPanel", self)
  self.Body:Dock(FILL)
  self.Body.Paint = function() end
end

function PANEL:AddTab(label, panel)
  if not IsValid(panel) then
    panel = vgui.Create("DPanel", self.Body)
  else
    panel:SetParent(self.Body)
  end

  panel:Dock(FILL)
  panel:SetVisible(false)

  local button = vgui.Create("DButton", self.Header)
  button:SetText(label)
  button:SetFont(BL.UI.Style.Fonts.Label)
  button:SetTextColor(BL.UI.Style.Colors.TextMuted)
  button:SetTall(BL.UI.bl_ui_scale(28))
  button:Dock(LEFT)
  button:DockMargin(0, 0, BL.UI.Style.Spacing.sm, 0)
  button:SetCursor("hand")

  button.Paint = function(btn, w, h)
    local is_active = self.ActiveTab == panel
    local colors = BL.UI.Style.Colors
    local background = is_active and colors.RowActive or colors.Row

    if btn:IsHovered() then
      background = colors.RowActive
    end

    draw.RoundedBox(BL.UI.Style.Radii.md, 0, 0, w, h, background)
    surface.SetDrawColor(is_active and colors.CardBorder or colors.Border)
    surface.DrawOutlinedRect(0, 0, w, h, 1)
    btn:SetTextColor(is_active and colors.Text or colors.TextMuted)
  end

  button.DoClick = function()
    self:SetActiveTab(panel)
  end

  table.insert(self.Tabs, {button = button, panel = panel})

  if not self.ActiveTab then
    self:SetActiveTab(panel)
  end

  return panel
end

function PANEL:SetActiveTab(panel)
  if self.ActiveTab == panel then
    return
  end

  if IsValid(self.ActiveTab) then
    self.ActiveTab:SetVisible(false)
  end

  self.ActiveTab = panel

  if IsValid(self.ActiveTab) then
    self.ActiveTab:SetVisible(true)
  end
end

vgui.Register("BLTabs", PANEL, "DPanel")
