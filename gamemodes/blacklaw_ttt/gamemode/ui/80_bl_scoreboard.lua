BL = BL or {}
BL.UI = BL.UI or {}
BL.Scoreboard = BL.Scoreboard or {}

local TEXT_ALIGN_RIGHT = TEXT_ALIGN_RIGHT or 2

local function get_style()
  return BL.UI and BL.UI.Style or {}
end

local function role_display(entry, phase)
  if type(entry) ~= "table" then
    return "Rolle: -"
  end
  local role = entry.role_name
  if type(role) ~= "string" or role == "" then
    return "Rolle: -"
  end
  return "Rolle: " .. role
end

local function status_text(entry)
  if type(entry) ~= "table" then
    return "Unbekannt"
  end
  if entry.alive == true then
    return "Alive"
  end
  return "Dead"
end

local function status_color(entry)
  local style = get_style()
  if type(entry) == "table" and entry.alive == true then
    return style.Colors.Primary or color_white
  end
  return style.Colors.ToastError or color_white
end

local function normalize_ping(value)
  if type(value) ~= "number" then
    return 0
  end
  return math.max(0, math.floor(value))
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
  bar:SetWide(BL.UI.bl_ui_scale(6))
  bar.Paint = function(_, w, h)
    draw.RoundedBox(style.Radii.md, 0, 0, w, h, style.Colors.SurfaceStrong)
  end
  bar.btnGrip.Paint = function(_, w, h)
    draw.RoundedBox(style.Radii.md, 0, 0, w, h, style.Colors.CardBorder)
  end
  bar.btnUp.Paint = function() end
  bar.btnDown.Paint = function() end
end

local ROW = {}

function ROW:Init()
  self.Entry = nil
  self.IsActive = false
  self:SetTall(BL.UI.bl_ui_scale(60))
  self:SetCursor("hand")
end

function ROW:SetEntry(entry, phase)
  self.Entry = entry
  self.Phase = phase
end

function ROW:SetActive(active)
  self.IsActive = active and true or false
end

function ROW:Paint(w, h)
  local style = get_style()
  local entry = self.Entry or {}
  local background = self.IsActive and style.Colors.RowActive or style.Colors.Row
  if self:IsHovered() then
    background = style.Colors.RowActive
  end

  draw.RoundedBox(style.Radii.md, 0, 0, w, h, background)
  surface.SetDrawColor(style.Colors.CardBorder)
  surface.DrawOutlinedRect(0, 0, w, h, 1)

  local padding = style.Spacing.md
  local name = entry.name or "Unbekannt"
  local ping = normalize_ping(entry.ping)
  local ping_text = tostring(ping) .. " ms"
  local role_text = role_display(entry, self.Phase)
  local status = status_text(entry)

  draw.SimpleText(name, style.Fonts.Body, padding, padding, style.Colors.Text)
  draw.SimpleText(role_text, style.Fonts.Label, padding, h - padding - BL.UI.bl_ui_scale(14), style.Colors.TextMuted)
  draw.SimpleText(status, style.Fonts.Label, w - padding, padding, status_color(entry), TEXT_ALIGN_RIGHT)
  draw.SimpleText(ping_text, style.Fonts.Label, w - padding, h - padding - BL.UI.bl_ui_scale(14), style.Colors.TextMuted, TEXT_ALIGN_RIGHT)
end

vgui.Register("BLScoreboardRow", ROW, "DButton")

local SECTION = {}

function SECTION:Init()
  local style = get_style()
  self.Title = ""
  self.Padding = style.Spacing.lg
  self.HeaderHeight = style.Spacing.xl
  self:SetPaintBackground(false)

  self.Scroll = vgui.Create("DScrollPanel", self)
  self.Scroll:Dock(FILL)
  self.Scroll:DockMargin(self.Padding, self.HeaderHeight, self.Padding, self.Padding)
  apply_scroll_style(self.Scroll)

  self.List = vgui.Create("DIconLayout", self.Scroll)
  self.List:Dock(FILL)
  self.List:SetSpaceY(style.Spacing.sm)
end

function SECTION:SetTitle(title)
  self.Title = title or ""
end

function SECTION:Clear()
  if IsValid(self.List) then
    self.List:Clear()
  end
end

function SECTION:AddRow()
  if not IsValid(self.List) then
    return nil
  end
  return self.List:Add("BLScoreboardRow")
end

function SECTION:Paint(w, h)
  local style = get_style()
  draw.RoundedBox(style.Radii.lg, 0, 0, w, h, style.Colors.Surface)
  surface.SetDrawColor(style.Colors.CardBorder)
  surface.DrawOutlinedRect(0, 0, w, h, 1)

  if self.Title ~= "" then
    draw.SimpleText(self.Title, style.Fonts.Heading, self.Padding, self.Padding, style.Colors.Text)
  end
end

vgui.Register("BLScoreboardSection", SECTION, "DPanel")

local INSPECT = {}

function INSPECT:Init()
  local style = get_style()
  self.Entry = nil
  self.Phase = "LOBBY"
  self.Padding = style.Spacing.lg
  self.HeaderHeight = style.Spacing.xl
  self:SetPaintBackground(false)

  self.AvatarFallback = vgui.Create("DPanel", self)
  self.AvatarFallback:SetSize(BL.UI.bl_ui_scale(64), BL.UI.bl_ui_scale(64))
  self.AvatarFallback:SetPaintBackground(false)
  self.AvatarFallback.Paint = function(panel, w, h)
    local icon = BL.Assets and BL.Assets.GetIconMaterial and BL.Assets.GetIconMaterial(BL.Assets.DefaultIcon, "avatar_fallback") or nil
    if not icon then
      return
    end
    surface.SetDrawColor(color_white)
    surface.SetMaterial(icon)
    surface.DrawTexturedRect(0, 0, w, h)
  end

  self.Avatar = vgui.Create("AvatarImage", self)
  self.Avatar:SetSize(BL.UI.bl_ui_scale(64), BL.UI.bl_ui_scale(64))

  self.ActionBar = vgui.Create("DPanel", self)
  self.ActionBar:SetPaintBackground(false)
  self.ActionBar:SetTall(BL.UI.bl_ui_scale(44))
  self.ActionBarButtons = {}

  self.EmptyLabel = vgui.Create("DLabel", self)
  self.EmptyLabel:SetFont(style.Fonts.Body)
  self.EmptyLabel:SetTextColor(style.Colors.TextMuted)
  self.EmptyLabel:SetText("Keine Auswahl")
  self.EmptyLabel:SizeToContents()
end

function INSPECT:SetAvatarFallback(enabled)
  if IsValid(self.Avatar) then
    self.Avatar:SetVisible(not enabled)
  end
  if IsValid(self.AvatarFallback) then
    self.AvatarFallback:SetVisible(enabled)
  end
end

function INSPECT:SetEntry(entry, phase)
  self.Entry = entry
  self.Phase = phase or self.Phase

  if not IsValid(self.Avatar) then
    return
  end

  local has_valid_avatar = false
  if type(entry) == "table" then
    local steamid64 = entry.steamid64
    if type(steamid64) == "string" and steamid64 ~= "" and util and util.SteamIDFrom64 then
      local steamid = util.SteamIDFrom64(steamid64)
      if steamid and steamid ~= "" then
        self.Avatar:SetSteamID(steamid, 64)
        has_valid_avatar = true
      end
    end
  end

  if not has_valid_avatar and BL.Assets and BL.Assets.LogMissing then
    BL.Assets.LogMissing("avatar", "steam_avatar")
  end
  self:SetAvatarFallback(not has_valid_avatar)
  self:RefreshActions()
end

function INSPECT:RefreshActions()
  for _, button in ipairs(self.ActionBarButtons) do
    if IsValid(button) then
      button:Remove()
    end
  end
  self.ActionBarButtons = {}

  if not IsValid(self.ActionBar) then
    return
  end

  local is_admin = LocalPlayer and IsValid(LocalPlayer()) and LocalPlayer():IsAdmin()
  if not is_admin then
    return
  end

  local inspect_button = vgui.Create("BLButton", self.ActionBar)
  inspect_button:SetText("Rolle inspizieren")
  inspect_button:SetVariant("primary")
  inspect_button:Dock(LEFT)
  inspect_button:DockMargin(0, 0, BL.UI.bl_ui_scale(8), 0)
  inspect_button.DoClick = function()
    if not self.Entry or not self.Entry.steamid64 then
      return
    end
    net.Start(BL.Net.Messages.ClientEvent)
    net.WriteTable({
      type = "inspect_player",
      steamid64 = self.Entry.steamid64,
    })
    net.SendToServer()
  end
  self.ActionBarButtons[#self.ActionBarButtons + 1] = inspect_button

  local copy_button = vgui.Create("BLButton", self.ActionBar)
  copy_button:SetText("SteamID64 kopieren")
  copy_button:SetVariant("ghost")
  copy_button:Dock(LEFT)
  copy_button.DoClick = function()
    if not self.Entry or not self.Entry.steamid64 then
      return
    end
    if SetClipboardText then
      SetClipboardText(self.Entry.steamid64)
    end
  end
  self.ActionBarButtons[#self.ActionBarButtons + 1] = copy_button
end

function INSPECT:PerformLayout(w, h)
  local style = get_style()
  local padding = self.Padding
  self.Avatar:SetPos(padding, padding + style.Spacing.lg)
  if IsValid(self.AvatarFallback) then
    self.AvatarFallback:SetPos(padding, padding + style.Spacing.lg)
  end

  if IsValid(self.ActionBar) then
    self.ActionBar:SetWide(w - padding * 2)
    self.ActionBar:SetPos(padding, h - padding - self.ActionBar:GetTall())
  end

  if IsValid(self.EmptyLabel) then
    self.EmptyLabel:SetPos(padding, padding + self.HeaderHeight)
  end
end

function INSPECT:Paint(w, h)
  local style = get_style()
  draw.RoundedBox(style.Radii.lg, 0, 0, w, h, style.Colors.Surface)
  surface.SetDrawColor(style.Colors.CardBorder)
  surface.DrawOutlinedRect(0, 0, w, h, 1)

  draw.SimpleText("Player Inspect", style.Fonts.Heading, self.Padding, self.Padding, style.Colors.Text)

  if type(self.Entry) ~= "table" then
    if IsValid(self.EmptyLabel) then
      self.EmptyLabel:SetText("Keine Auswahl")
      self.EmptyLabel:SizeToContents()
      self.EmptyLabel:SetVisible(true)
    end
    return
  end

  if IsValid(self.EmptyLabel) then
    self.EmptyLabel:SetVisible(false)
  end

  local name = self.Entry.name or "Unbekannt"
  local role_text = role_display(self.Entry, self.Phase)
  local status = status_text(self.Entry)
  local status_color_value = status_color(self.Entry)
  local ping = normalize_ping(self.Entry.ping)
  local kills = normalize_ping(self.Entry.round_kills)
  local deaths = normalize_ping(self.Entry.round_deaths)
  local persistent = type(self.Entry.stats) == "table" and self.Entry.stats or nil

  local text_x = self.Padding + self.Avatar:GetWide() + self.Padding
  local text_y = self.Padding + BL.UI.bl_ui_scale(6)

  draw.SimpleText(name, style.Fonts.Heading, text_x, text_y, style.Colors.Text)
  draw.SimpleText(role_text, style.Fonts.Body, text_x, text_y + style.Spacing.lg + BL.UI.bl_ui_scale(4), style.Colors.TextMuted)
  draw.SimpleText(status, style.Fonts.Label, text_x, text_y + style.Spacing.xl + BL.UI.bl_ui_scale(6), status_color_value)

  local stats_y = self.Padding + self.HeaderHeight + self.Avatar:GetTall() + style.Spacing.lg
  draw.SimpleText("Stats", style.Fonts.Label, self.Padding, stats_y, style.Colors.TextMuted)
  draw.SimpleText("Kills (Runde): " .. tostring(kills), style.Fonts.Body, self.Padding, stats_y + style.Spacing.lg, style.Colors.Text)
  draw.SimpleText("Deaths (Runde): " .. tostring(deaths), style.Fonts.Body, self.Padding, stats_y + style.Spacing.lg * 2, style.Colors.Text)
  draw.SimpleText("Ping: " .. tostring(ping) .. " ms", style.Fonts.Body, self.Padding, stats_y + style.Spacing.lg * 3, style.Colors.Text)

  local persistent_y = stats_y + style.Spacing.lg * 5
  draw.SimpleText("Persistente Stats", style.Fonts.Label, self.Padding, persistent_y, style.Colors.TextMuted)
  if persistent then
    draw.SimpleText("Kills: " .. tostring(persistent.kills or 0), style.Fonts.Body, self.Padding, persistent_y + style.Spacing.lg, style.Colors.Text)
    draw.SimpleText("Deaths: " .. tostring(persistent.deaths or 0), style.Fonts.Body, self.Padding, persistent_y + style.Spacing.lg * 2, style.Colors.Text)
    draw.SimpleText("Runden: " .. tostring(persistent.rounds or 0), style.Fonts.Body, self.Padding, persistent_y + style.Spacing.lg * 3, style.Colors.Text)
    draw.SimpleText("Siege (Inno): " .. tostring(persistent.wins_inno or 0), style.Fonts.Body, self.Padding, persistent_y + style.Spacing.lg * 4, style.Colors.Text)
    draw.SimpleText("Siege (Traitor): " .. tostring(persistent.wins_traitor or 0), style.Fonts.Body, self.Padding, persistent_y + style.Spacing.lg * 5, style.Colors.Text)
    if (persistent.last_seen or 0) > 0 then
      local last_seen = os.date("%d.%m.%Y %H:%M", persistent.last_seen)
      draw.SimpleText("Zuletzt gesehen: " .. last_seen, style.Fonts.Body, self.Padding, persistent_y + style.Spacing.lg * 6, style.Colors.TextMuted)
    end
  else
    draw.SimpleText("Nur für dich oder Admins sichtbar.", style.Fonts.Body, self.Padding, persistent_y + style.Spacing.lg, style.Colors.TextMuted)
  end

  local is_admin = LocalPlayer and IsValid(LocalPlayer()) and LocalPlayer():IsAdmin()
  if not is_admin then
    draw.SimpleText("Admin-Aktionen nur für Admins.", style.Fonts.Label, self.Padding, h - self.Padding - BL.UI.bl_ui_scale(18), style.Colors.TextMuted)
  end
end

vgui.Register("BLScoreboardInspect", INSPECT, "DPanel")

local BOARD = {}

function BOARD:Init()
  self:SetSize(ScrW(), ScrH())
  self:SetPos(0, 0)
  self:SetMouseInputEnabled(true)
  self:SetKeyboardInputEnabled(false)
  self.LastRefresh = 0
  self.SelectedSteamID = nil

  self.Container = vgui.Create("DPanel", self)
  self.Container:SetPaintBackground(false)

  self.LeftColumn = vgui.Create("DPanel", self.Container)
  self.LeftColumn:SetPaintBackground(false)

  self.RightColumn = vgui.Create("DPanel", self.Container)
  self.RightColumn:SetPaintBackground(false)

  self.AliveSection = vgui.Create("BLScoreboardSection", self.LeftColumn)
  self.AliveSection:SetTitle("Alive")

  self.DeadSection = vgui.Create("BLScoreboardSection", self.LeftColumn)
  self.DeadSection:SetTitle("Dead")

  self.InspectPanel = vgui.Create("BLScoreboardInspect", self.RightColumn)
end

function BOARD:PerformLayout(w, h)
  local style = get_style()
  local card_width = BL.UI.bl_ui_scale(980)
  local card_height = BL.UI.bl_ui_scale(620)
  self.Container:SetSize(card_width, card_height)
  self.Container:SetPos((w - card_width) * 0.5, (h - card_height) * 0.5)

  local left_width = math.floor(card_width * 0.46)
  local gutter = style.Spacing.lg
  self.LeftColumn:SetSize(left_width, card_height)
  self.LeftColumn:SetPos(0, 0)

  self.RightColumn:SetSize(card_width - left_width - gutter, card_height)
  self.RightColumn:SetPos(left_width + gutter, 0)

  local section_height = math.floor((card_height - gutter) * 0.5)
  self.AliveSection:SetPos(0, 0)
  self.AliveSection:SetSize(left_width, section_height)

  self.DeadSection:SetPos(0, section_height + gutter)
  self.DeadSection:SetSize(left_width, card_height - section_height - gutter)

  if IsValid(self.InspectPanel) then
    self.InspectPanel:SetSize(self.RightColumn:GetWide(), card_height)
    self.InspectPanel:SetPos(0, 0)
  end
end

function BOARD:Paint(w, h)
  local style = get_style()
  draw.RoundedBox(0, 0, 0, w, h, style.Colors.Overlay)
end

function BOARD:Think()
  if CurTime() - self.LastRefresh < 0.5 then
    return
  end
  self.LastRefresh = CurTime()
  self:RefreshPlayers()
end

function BOARD:SelectEntry(entry, phase)
  if type(entry) ~= "table" then
    return
  end
  self.SelectedSteamID = entry.steamid64
  if IsValid(self.InspectPanel) then
    self.InspectPanel:SetEntry(entry, phase)
  end
end

function BOARD:RefreshPlayers()
  local snapshot = BL.Net and BL.Net.GetSnapshot and BL.Net.GetSnapshot() or nil
  if type(snapshot) ~= "table" then
    return
  end

  local phase = snapshot.phase or "LOBBY"
  local entries = snapshot.players_summary or {}
  if type(entries) ~= "table" then
    return
  end

  local alive = {}
  local dead = {}
  for _, entry in ipairs(entries) do
    if type(entry) == "table" then
      if entry.alive == true then
        alive[#alive + 1] = entry
      else
        dead[#dead + 1] = entry
      end
    end
  end

  table.sort(alive, function(a, b)
    return (a.name or "") < (b.name or "")
  end)
  table.sort(dead, function(a, b)
    return (a.name or "") < (b.name or "")
  end)

  self.AliveSection:Clear()
  self.DeadSection:Clear()

  local function populate(section, list)
    for _, entry in ipairs(list) do
      local row = section:AddRow()
      if IsValid(row) then
        row:SetEntry(entry, phase)
        row:SetActive(self.SelectedSteamID ~= nil and entry.steamid64 == self.SelectedSteamID)
        row.DoClick = function()
          self:SelectEntry(entry, phase)
        end
      end
    end
  end

  populate(self.AliveSection, alive)
  populate(self.DeadSection, dead)

  if not self.SelectedSteamID then
    local local_ply = LocalPlayer and LocalPlayer()
    local local_id = IsValid(local_ply) and local_ply:SteamID64() or nil
    local fallback = alive[1] or dead[1]
    for _, entry in ipairs(entries) do
      if local_id and entry.steamid64 == local_id then
        fallback = entry
        break
      end
    end
    if fallback then
      self:SelectEntry(fallback, phase)
    end
  end
end

vgui.Register("BLScoreboard", BOARD, "DPanel")

function BL.Scoreboard.Show()
  if IsValid(BL.Scoreboard.Panel) then
    return
  end
  BL.Scoreboard.Panel = vgui.Create("BLScoreboard")
  BL.Scoreboard.Panel:MakePopup()
  gui.EnableScreenClicker(true)
end

function BL.Scoreboard.Hide()
  if IsValid(BL.Scoreboard.Panel) then
    BL.Scoreboard.Panel:Remove()
  end
  BL.Scoreboard.Panel = nil
  gui.EnableScreenClicker(false)
end

hook.Add("ScoreboardShow", "BL.Scoreboard.Show", function()
  BL.Scoreboard.Show()
  return false
end)

hook.Add("ScoreboardHide", "BL.Scoreboard.Hide", function()
  BL.Scoreboard.Hide()
end)
