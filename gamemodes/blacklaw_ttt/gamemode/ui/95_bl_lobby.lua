BL = BL or {}
BL.UI = BL.UI or {}
BL.LobbyUI = BL.LobbyUI or {}

local TEXT_ALIGN_LEFT = TEXT_ALIGN_LEFT or 0
local TEXT_ALIGN_CENTER = TEXT_ALIGN_CENTER or 1

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

local function create_text_entry(parent, placeholder)
  local entry = vgui.Create("DTextEntry", parent)
  entry:SetFont(BL.UI.Style.Fonts.Body)
  entry:SetTextColor(BL.UI.Style.Colors.Text)
  entry:SetPlaceholderText(placeholder or "")
  entry:SetUpdateOnType(true)
  entry.Paint = function(self, w, h)
    local style = get_style()
    draw.RoundedBox(style.Radii.md, 0, 0, w, h, style.Colors.SurfaceStrong)
    surface.SetDrawColor(style.Colors.Border)
    surface.DrawOutlinedRect(0, 0, w, h, 1)
    self:DrawTextEntryText(style.Colors.Text, style.Colors.Accent, style.Colors.TextMuted)
  end
  return entry
end

local function create_label(parent, text, font, color)
  local label = vgui.Create("DLabel", parent)
  label:SetFont(font or BL.UI.Style.Fonts.Body)
  label:SetText(text or "")
  label:SetTextColor(color or BL.UI.Style.Colors.Text)
  label:SetWrap(true)
  label:SetAutoStretchVertical(true)
  label:SetContentAlignment(TEXT_ALIGN_LEFT)
  return label
end

local function show_toast(message, kind)
  if BL.UI and BL.UI.Toast and BL.UI.Toast.Show then
    BL.UI.Toast.Show(message, kind or "info", 4)
  else
    chat.AddText(Color(255, 255, 255), message)
  end
end

local function send_admin_action(payload)
  if type(payload) ~= "table" then
    return
  end
  net.Start(BL.Net.Messages.AdminAction)
  net.WriteTable(payload)
  net.SendToServer()
end

local function send_client_event(payload)
  if type(payload) ~= "table" then
    return
  end
  net.Start(BL.Net.Messages.ClientEvent)
  net.WriteTable(payload)
  net.SendToServer()
end

local function format_phase_label(phase)
  local labels = {
    LOBBY = "Lobby",
    PREP = "Vorbereitung",
    ACTIVE = "Runde aktiv",
    POST = "Auswertung",
  }
  return labels[phase] or phase or "Unbekannt"
end

local function format_status_label(phase)
  if phase == "LOBBY" then
    return "Warte auf Spieler"
  end
  if phase == "PREP" then
    return "Vorbereitung"
  end
  if phase == "ACTIVE" then
    return "Runde läuft"
  end
  if phase == "POST" then
    return "Auswertung"
  end
  return "Status unbekannt"
end

local function get_initials(name)
  if type(name) ~= "string" then
    return "--"
  end
  local initials = {}
  for part in string.gmatch(name, "[^%s]+") do
    initials[#initials + 1] = string.sub(part, 1, 1):upper()
    if #initials >= 2 then
      break
    end
  end
  if #initials == 0 then
    return "--"
  end
  return table.concat(initials, "")
end

local function format_event_entry(entry)
  if type(entry) ~= "table" then
    return tostring(entry or "")
  end

  local event_type = entry.type
  if type(event_type) ~= "string" then
    return "Ereignis"
  end

  local payload = entry.payload
  if type(payload) ~= "table" then
    payload = {}
  end

  if event_type == "phase_lobby" then
    return "Phase: Lobby"
  end
  if event_type == "phase_prep" then
    return "Phase: Vorbereitung"
  end
  if event_type == "phase_active" then
    return "Phase: Runde aktiv"
  end
  if event_type == "phase_post" then
    return "Phase: Auswertung"
  end
  if event_type == "round_win" then
    local winner = payload.winner or "unbekannt"
    return "Runde entschieden: " .. winner
  end
  if event_type == "role_reveal" then
    local name = payload.name or "Spieler"
    local role_name = payload.role_name or "Unbekannt"
    return name .. " ist " .. role_name
  end
  if event_type == "player_death" then
    local name = payload.name or "Spieler"
    return name .. " ist gestorben"
  end
  if event_type == "admin_force_start" then
    return "Adminstart: " .. (payload.by or "unbekannt")
  end
  if event_type == "admin_force_end" then
    return "Adminende: " .. (payload.by or "unbekannt")
  end

  return event_type
end

local STAT_CARD = {}

function STAT_CARD:Init()
  self.Label = ""
  self.Value = "-"
end

function STAT_CARD:SetLabel(text)
  self.Label = text or ""
end

function STAT_CARD:SetValue(text)
  self.Value = text or "-"
end

function STAT_CARD:Paint(w, h)
  local style = get_style()
  draw.RoundedBox(style.Radii.md, 0, 0, w, h, style.Colors.SurfaceStrong)
  surface.SetDrawColor(style.Colors.CardBorder)
  surface.DrawOutlinedRect(0, 0, w, h, 1)

  draw.SimpleText(self.Label, style.Fonts.Label, style.Spacing.md, style.Spacing.sm, style.Colors.TextMuted)
  draw.SimpleText(self.Value, style.Fonts.Heading, style.Spacing.md, style.Spacing.md + BL.UI.bl_ui_scale(16), style.Colors.Text)
  return true
end

vgui.Register("BLLobbyStatCard", STAT_CARD, "DPanel")

local ROLE_CARD = {}

function ROLE_CARD:Init()
  self.Label = ""
  self.Count = 0
end

function ROLE_CARD:SetRole(label, count)
  self.Label = label or ""
  self.Count = tonumber(count) or 0
end

function ROLE_CARD:Paint(w, h)
  local style = get_style()
  draw.RoundedBox(style.Radii.md, 0, 0, w, h, style.Colors.Row)
  surface.SetDrawColor(style.Colors.CardBorder)
  surface.DrawOutlinedRect(0, 0, w, h, 1)

  draw.SimpleText(self.Label, style.Fonts.Body, style.Spacing.md, style.Spacing.sm, style.Colors.Text)
  draw.SimpleText(tostring(self.Count), style.Fonts.Heading, style.Spacing.md, style.Spacing.sm + BL.UI.bl_ui_scale(18), style.Colors.Text)
  return true
end

vgui.Register("BLLobbyRoleCard", ROLE_CARD, "DPanel")

local ROOT = {}

function ROOT:Init()
  local style = get_style()
  self:SetSize(ScrW(), ScrH())
  self:SetPos(0, 0)
  self:SetMouseInputEnabled(true)
  self:SetKeyboardInputEnabled(true)
  self.SelectedSteamId = nil
  self.LastSnapshot = nil
  self.LastEventCount = 0

  self.Frame = vgui.Create("DPanel", self)
  self.Frame.Paint = function(_, w, h)
    draw.RoundedBox(style.Radii.lg, 0, 0, w, h, style.Colors.Background)
    surface.SetDrawColor(style.Colors.Border)
    surface.DrawOutlinedRect(0, 0, w, h, 1)
  end

  self.Header = vgui.Create("DPanel", self.Frame)
  self.Header:SetPaintBackground(false)

  self.Kicker = create_label(self.Header, "TTT2", style.Fonts.Label, style.Colors.Accent)
  self.Kicker:SetContentAlignment(TEXT_ALIGN_LEFT)

  self.Title = create_label(self.Header, "Trouble in Terrorist Town 2", style.Fonts.Title, style.Colors.Text)
  self.Subtitle = create_label(self.Header, "Gerüst für den weiteren Ausbau", style.Fonts.Body, style.Colors.TextMuted)

  self.StatusCard = vgui.Create("DPanel", self.Header)
  self.StatusCard.Paint = function(_, w, h)
    draw.RoundedBox(style.Radii.md, 0, 0, w, h, style.Colors.ToastInfo)
  end

  self.StatusLabel = create_label(self.StatusCard, "Spielstatus", style.Fonts.Label, style.Colors.TextMuted)
  self.StatusValue = create_label(self.StatusCard, "Warte auf Spieler", style.Fonts.Body, style.Colors.Text)

  self.PlayerCard = vgui.Create("BLCard", self.Frame)
  self.PlayerCard:SetTitle("Spieler verwalten")

  self.PlayerBody = vgui.Create("DPanel", self.PlayerCard)
  self.PlayerBody:SetPaintBackground(false)
  self.PlayerBody:Dock(FILL)
  self.PlayerBody:DockMargin(0, BL.UI.bl_ui_scale(48), 0, 0)

  self.PlayerForm = vgui.Create("DPanel", self.PlayerBody)
  self.PlayerForm:SetPaintBackground(false)
  self.PlayerForm:Dock(TOP)
  self.PlayerForm:SetTall(BL.UI.bl_ui_scale(36))

  self.PlayerEntry = create_text_entry(self.PlayerForm, "Spielername")
  self.PlayerEntry:Dock(FILL)

  self.PlayerFocusButton = vgui.Create("BLButton", self.PlayerForm)
  self.PlayerFocusButton:SetText("Fokussieren")
  self.PlayerFocusButton:SetVariant("ghost")
  self.PlayerFocusButton:Dock(RIGHT)
  self.PlayerFocusButton:SetWide(BL.UI.bl_ui_scale(120))
  self.PlayerFocusButton:DockMargin(style.Spacing.sm, 0, 0, 0)

  self.PlayerList = vgui.Create("DScrollPanel", self.PlayerBody)
  self.PlayerList:Dock(FILL)
  self.PlayerList:DockMargin(0, style.Spacing.sm, 0, style.Spacing.sm)
  apply_scroll_style(self.PlayerList)

  self.PlayerActions = vgui.Create("DPanel", self.PlayerBody)
  self.PlayerActions:SetPaintBackground(false)
  self.PlayerActions:Dock(BOTTOM)
  self.PlayerActions:SetTall(BL.UI.bl_ui_scale(40))

  self.StartButton = vgui.Create("BLButton", self.PlayerActions)
  self.StartButton:SetText("Spiel starten")
  self.StartButton:SetVariant("primary")
  self.StartButton:Dock(LEFT)
  self.StartButton:DockMargin(0, 0, style.Spacing.sm, 0)
  self.StartButton.DoClick = function()
    send_admin_action({ action = "round_start", reason = "Lobby UI" })
  end

  self.ResetButton = vgui.Create("BLButton", self.PlayerActions)
  self.ResetButton:SetText("Spiel zurücksetzen")
  self.ResetButton:SetVariant("ghost")
  self.ResetButton:Dock(LEFT)
  self.ResetButton.DoClick = function()
    send_admin_action({ action = "round_restart", reason = "Lobby UI" })
  end

  self.PlayerViewCard = vgui.Create("BLCard", self.Frame)
  self.PlayerViewCard:SetTitle("Spieleransicht")
  self.PlayerViewCard:SetSubtitle("Moderne 2026-Ansicht mit Fokus auf eine einzelne Spieler-Identität.")

  self.PlayerViewBody = vgui.Create("DPanel", self.PlayerViewCard)
  self.PlayerViewBody:SetPaintBackground(false)
  self.PlayerViewBody:Dock(FILL)
  self.PlayerViewBody:DockMargin(0, BL.UI.bl_ui_scale(72), 0, 0)

  self.PlayerViewHeader = vgui.Create("DPanel", self.PlayerViewBody)
  self.PlayerViewHeader:SetPaintBackground(false)
  self.PlayerViewHeader:Dock(TOP)
  self.PlayerViewHeader:SetTall(BL.UI.bl_ui_scale(44))

  self.PlayerViewStatus = vgui.Create("DPanel", self.PlayerViewHeader)
  self.PlayerViewStatus.Paint = function(panel, w, h)
    local style = get_style()
    draw.RoundedBox(h * 0.5, 0, 0, w, h, style.Colors.ToastSuccess)
    draw.SimpleText(panel.Text or "Lobby", style.Fonts.Label, w * 0.5, h * 0.5, style.Colors.Text, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
  end

  self.PlayerProfile = vgui.Create("DPanel", self.PlayerViewBody)
  self.PlayerProfile:SetPaintBackground(false)
  self.PlayerProfile:Dock(TOP)
  self.PlayerProfile:SetTall(BL.UI.bl_ui_scale(84))
  self.PlayerProfile:DockMargin(0, style.Spacing.md, 0, 0)

  self.PlayerAvatar = vgui.Create("DPanel", self.PlayerProfile)
  self.PlayerAvatar.Initials = "--"
  self.PlayerAvatar.Paint = function(panel, w, h)
    local style = get_style()
    draw.RoundedBox(style.Radii.lg, 0, 0, w, h, style.Colors.Accent)
    draw.SimpleText(panel.Initials or "--", style.Fonts.Body, w * 0.5, h * 0.5, style.Colors.Text, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
  end

  self.PlayerName = create_label(self.PlayerProfile, "Keine Auswahl", style.Fonts.Heading, style.Colors.Text)
  self.PlayerRole = create_label(self.PlayerProfile, "Rolle: -", style.Fonts.Body, style.Colors.TextMuted)
  self.PlayerRoleDesc = create_label(self.PlayerProfile, "Wähle einen Spieler aus der Liste, um Details zu sehen.", style.Fonts.Body, style.Colors.TextMuted)

  self.PlayerStats = vgui.Create("DPanel", self.PlayerViewBody)
  self.PlayerStats:SetPaintBackground(false)
  self.PlayerStats:Dock(FILL)
  self.PlayerStats:DockMargin(0, style.Spacing.md, 0, style.Spacing.md)

  self.StatCards = {}
  for index = 1, 4 do
    local card = vgui.Create("BLLobbyStatCard", self.PlayerStats)
    self.StatCards[index] = card
  end

  self.PlayerActionsRow = vgui.Create("DPanel", self.PlayerViewBody)
  self.PlayerActionsRow:SetPaintBackground(false)
  self.PlayerActionsRow:Dock(BOTTOM)
  self.PlayerActionsRow:SetTall(BL.UI.bl_ui_scale(40))

  self.InspectButton = vgui.Create("BLButton", self.PlayerActionsRow)
  self.InspectButton:SetText("Spieler fokussieren")
  self.InspectButton:SetVariant("ghost")
  self.InspectButton:Dock(LEFT)
  self.InspectButton:DockMargin(0, 0, style.Spacing.sm, 0)
  self.InspectButton.DoClick = function()
    self:InspectSelectedPlayer()
  end

  self.MessageButton = vgui.Create("BLButton", self.PlayerActionsRow)
  self.MessageButton:SetText("Nachricht senden")
  self.MessageButton:SetVariant("primary")
  self.MessageButton:Dock(LEFT)
  self.MessageButton.DoClick = function()
    self:OpenMessageModal()
  end

  self.RoleCard = vgui.Create("BLCard", self.Frame)
  self.RoleCard:SetTitle("Rollenübersicht")
  self.RoleCard:SetSubtitle("Beim Start werden nur Verräter und Unschuldige verteilt. Die Verräter-Anzahl skaliert automatisch mit der Spielerzahl.")

  self.RoleBody = vgui.Create("DPanel", self.RoleCard)
  self.RoleBody:SetPaintBackground(false)
  self.RoleBody:Dock(FILL)
  self.RoleBody:DockMargin(0, BL.UI.bl_ui_scale(72), 0, 0)

  self.RoleList = vgui.Create("DScrollPanel", self.RoleBody)
  self.RoleList:Dock(FILL)
  apply_scroll_style(self.RoleList)

  self.PhaseCard = vgui.Create("BLCard", self.Frame)
  self.PhaseCard:SetTitle("Phasensteuerung")
  self.PhaseCard:SetSubtitle("Steuere Tag/Nacht für spätere Logik.")

  self.PhaseBody = vgui.Create("DPanel", self.PhaseCard)
  self.PhaseBody:SetPaintBackground(false)
  self.PhaseBody:Dock(FILL)
  self.PhaseBody:DockMargin(0, BL.UI.bl_ui_scale(72), 0, 0)

  self.PhaseHeader = vgui.Create("DPanel", self.PhaseBody)
  self.PhaseHeader:SetPaintBackground(false)
  self.PhaseHeader:Dock(TOP)
  self.PhaseHeader:SetTall(BL.UI.bl_ui_scale(48))

  self.PhaseLabel = create_label(self.PhaseHeader, "Aktuelle Phase", style.Fonts.Label, style.Colors.TextMuted)
  self.PhaseValue = create_label(self.PhaseHeader, "Lobby", style.Fonts.Body, style.Colors.Text)

  self.PhaseToggle = vgui.Create("BLButton", self.PhaseHeader)
  self.PhaseToggle:SetText("Phase wechseln")
  self.PhaseToggle:SetVariant("accent")
  self.PhaseToggle:Dock(RIGHT)
  self.PhaseToggle:SetWide(BL.UI.bl_ui_scale(160))
  self.PhaseToggle.DoClick = function()
    self:CyclePhase()
  end

  self.EventLogLabel = create_label(self.PhaseBody, "Ereignis-Log", style.Fonts.Label, style.Colors.TextMuted)
  self.EventLogLabel:Dock(TOP)
  self.EventLogLabel:DockMargin(0, style.Spacing.md, 0, style.Spacing.sm)

  self.EventLog = vgui.Create("DScrollPanel", self.PhaseBody)
  self.EventLog:Dock(FILL)
  apply_scroll_style(self.EventLog)

  self.PlayerFocusButton.DoClick = function()
    self:FocusPlayerByName()
  end

  self:RefreshFromCache(true)
end

function ROOT:OnMousePressed()
  if not IsValid(self.Frame) then
    return
  end
  local x, y = self:CursorPos()
  local fx, fy = self.Frame:GetPos()
  local fw, fh = self.Frame:GetSize()
  if x < fx or x > fx + fw or y < fy or y > fy + fh then
    self:Close()
  end
end

function ROOT:PerformLayout(w, h)
  local style = get_style()
  local padding = style.Spacing.xl
  local frame_w = BL.UI.bl_ui_scale(1100)
  local frame_h = BL.UI.bl_ui_scale(760)
  local x = (w - frame_w) * 0.5
  local y = (h - frame_h) * 0.5
  self.Frame:SetPos(x, y)
  self.Frame:SetSize(frame_w, frame_h)

  self.Header:SetPos(padding, padding)
  self.Header:SetSize(frame_w - padding * 2, BL.UI.bl_ui_scale(92))

  local header_w, header_h = self.Header:GetSize()
  self.Kicker:SetPos(0, 0)
  self.Kicker:SetWide(header_w * 0.7)
  self.Kicker:SetTall(BL.UI.bl_ui_scale(16))

  self.Title:SetPos(0, BL.UI.bl_ui_scale(14))
  self.Title:SetWide(header_w * 0.7)

  self.Subtitle:SetPos(0, BL.UI.bl_ui_scale(48))
  self.Subtitle:SetWide(header_w * 0.7)

  self.StatusCard:SetSize(BL.UI.bl_ui_scale(200), BL.UI.bl_ui_scale(64))
  self.StatusCard:SetPos(header_w - self.StatusCard:GetWide(), BL.UI.bl_ui_scale(8))

  self.StatusLabel:SetPos(style.Spacing.sm, style.Spacing.sm)
  self.StatusLabel:SetWide(self.StatusCard:GetWide() - style.Spacing.md)
  self.StatusValue:SetPos(style.Spacing.sm, style.Spacing.md + BL.UI.bl_ui_scale(12))
  self.StatusValue:SetWide(self.StatusCard:GetWide() - style.Spacing.md)

  local main_y = padding + header_h + padding
  local main_h = frame_h - main_y - padding
  local column_w = (frame_w - padding * 3) * 0.5
  local row_h = (main_h - padding) * 0.5

  self.PlayerCard:SetPos(padding, main_y)
  self.PlayerCard:SetSize(column_w, row_h)

  self.PlayerViewCard:SetPos(padding * 2 + column_w, main_y)
  self.PlayerViewCard:SetSize(column_w, row_h)

  self.RoleCard:SetPos(padding, main_y + row_h + padding)
  self.RoleCard:SetSize(column_w, row_h)

  self.PhaseCard:SetPos(padding * 2 + column_w, main_y + row_h + padding)
  self.PhaseCard:SetSize(column_w, row_h)

  self.PlayerViewHeader:SetTall(BL.UI.bl_ui_scale(32))
  self.PlayerViewStatus:SetSize(BL.UI.bl_ui_scale(100), BL.UI.bl_ui_scale(24))
  self.PlayerViewStatus:SetPos(self.PlayerViewHeader:GetWide() - self.PlayerViewStatus:GetWide(), 0)

  self.PlayerAvatar:SetSize(BL.UI.bl_ui_scale(64), BL.UI.bl_ui_scale(64))
  self.PlayerAvatar:SetPos(0, 0)

  local profile_x = self.PlayerAvatar:GetWide() + style.Spacing.md
  local profile_w = self.PlayerProfile:GetWide() - profile_x
  self.PlayerName:SetPos(profile_x, 0)
  self.PlayerName:SetWide(profile_w)
  self.PlayerRole:SetPos(profile_x, BL.UI.bl_ui_scale(24))
  self.PlayerRole:SetWide(profile_w)
  self.PlayerRoleDesc:SetPos(profile_x, BL.UI.bl_ui_scale(44))
  self.PlayerRoleDesc:SetWide(profile_w)

  local stat_gap = style.Spacing.sm
  local stat_w = (self.PlayerStats:GetWide() - stat_gap) * 0.5
  local stat_h = (self.PlayerStats:GetTall() - stat_gap) * 0.5
  for index, card in ipairs(self.StatCards) do
    local row = math.floor((index - 1) / 2)
    local col = (index - 1) % 2
    card:SetSize(stat_w, stat_h)
    card:SetPos(col * (stat_w + stat_gap), row * (stat_h + stat_gap))
  end

  self.PhaseLabel:SetPos(0, 0)
  self.PhaseLabel:SetWide(self.PhaseHeader:GetWide() - self.PhaseToggle:GetWide() - style.Spacing.sm)
  self.PhaseValue:SetPos(0, BL.UI.bl_ui_scale(18))
  self.PhaseValue:SetWide(self.PhaseHeader:GetWide() - self.PhaseToggle:GetWide() - style.Spacing.sm)
end

function ROOT:Close()
  if IsValid(self) then
    self:Remove()
  end
end

function ROOT:OnRemove()
  if BL.LobbyUI and BL.LobbyUI.Root == self then
    BL.LobbyUI.Root = nil
  end
end

function ROOT:Think()
  self:RefreshFromCache(false)
end

function ROOT:RefreshFromCache(force)
  local snapshot = BL.Net and BL.Net.GetSnapshot and BL.Net.GetSnapshot() or nil
  if snapshot ~= self.LastSnapshot or force then
    if type(snapshot) == "table" then
      self.LastSnapshot = snapshot
      self:ApplySnapshot(snapshot)
    end
  end

  local events = BL.Net and BL.Net.GetEvents and BL.Net.GetEvents() or nil
  if type(events) == "table" then
    local count = #events
    if count ~= self.LastEventCount then
      self.LastEventCount = count
      self:UpdateEventLog(events)
    end
  end
end

function ROOT:ApplySnapshot(snapshot)
  if type(snapshot) ~= "table" then
    return
  end

  local phase = snapshot.phase or "LOBBY"
  self.StatusValue:SetText(format_status_label(phase))
  self.PhaseValue:SetText(format_phase_label(phase))

  local players = snapshot.players_summary or {}
  if self.SelectedSteamId then
    local still_exists = false
    for _, entry in ipairs(players) do
      if entry.steamid64 == self.SelectedSteamId then
        still_exists = true
        break
      end
    end
    if not still_exists then
      self.SelectedSteamId = nil
    end
  end

  if not self.SelectedSteamId and players[1] then
    self.SelectedSteamId = players[1].steamid64
  end

  self:UpdatePlayerList(players)
  self:UpdatePlayerView(players, snapshot)
  self:UpdateRoleCards(snapshot.role_counts or {})
  self:UpdateEventLog(snapshot.event_log or {})
end

function ROOT:UpdatePlayerList(players)
  self.PlayerList:Clear()

  for _, entry in ipairs(players) do
    local row = vgui.Create("BLListRow", self.PlayerList)
    row:Dock(TOP)
    row:DockMargin(0, 0, 0, get_style().Spacing.sm)
    local suffix = entry.alive == false and " (tot)" or ""
    row:SetText((entry.name or "Unbekannt") .. suffix)
    row:SetActive(entry.steamid64 == self.SelectedSteamId)
    row.DoClick = function()
      self.SelectedSteamId = entry.steamid64
      self:UpdatePlayerList(players)
      self:UpdatePlayerView(players, self.LastSnapshot or {})
    end
  end
end

function ROOT:UpdatePlayerView(players, snapshot)
  local selected = nil
  local selected_index = nil
  for index, entry in ipairs(players or {}) do
    if entry.steamid64 == self.SelectedSteamId then
      selected = entry
      selected_index = index
      break
    end
  end

  if not selected then
    self.PlayerName:SetText("Keine Auswahl")
    self.PlayerRole:SetText("Rolle: -")
    self.PlayerRoleDesc:SetText("Wähle einen Spieler aus der Liste, um Details zu sehen.")
    self.PlayerAvatar.Initials = "--"
    self.PlayerViewStatus.Text = "Lobby"
    for _, card in ipairs(self.StatCards) do
      card:SetLabel("-")
      card:SetValue("-")
    end
    return
  end

  local role_name = selected.role_name or "Unbekannt"
  local role_desc = selected.role_revealed or selected.role_public
    and ("Rolle bestätigt: " .. role_name)
    or "Rolle wird beim Start des Spiels zugewiesen."

  self.PlayerName:SetText(selected.name or "Unbekannt")
  self.PlayerRole:SetText("Rolle: " .. role_name)
  self.PlayerRoleDesc:SetText(role_desc)
  self.PlayerAvatar.Initials = get_initials(selected.name or "")

  local phase = snapshot.phase or "LOBBY"
  self.PlayerViewStatus.Text = phase == "ACTIVE" and "Im Einsatz" or "Lobby"

  local role_counts = snapshot.role_counts or {}
  local traitors = tonumber(role_counts.TRAITOR) or 0
  local innocents = tonumber(role_counts.INNOCENT) or 0
  local round_status = phase == "LOBBY" and "Lobby" or "Aktiv"

  self.StatCards[1]:SetLabel("Spieler-ID")
  self.StatCards[1]:SetValue(selected_index and ("#" .. tostring(selected_index)) or "-")
  self.StatCards[2]:SetLabel("Rundenstatus")
  self.StatCards[2]:SetValue(round_status)
  self.StatCards[3]:SetLabel("Verräter")
  self.StatCards[3]:SetValue(tostring(traitors))
  self.StatCards[4]:SetLabel("Unschuldige")
  self.StatCards[4]:SetValue(tostring(innocents))
end

function ROOT:UpdateRoleCards(role_counts)
  self.RoleList:Clear()
  if type(role_counts) ~= "table" or next(role_counts) == nil then
    local label = create_label(self.RoleList, "Noch keine Rollen vergeben.", get_style().Fonts.Body, get_style().Colors.TextMuted)
    label:Dock(TOP)
    return
  end

  for role, count in pairs(role_counts) do
    local card = vgui.Create("BLLobbyRoleCard", self.RoleList)
    card:SetRole(role, count)
    card:Dock(TOP)
    card:DockMargin(0, 0, 0, get_style().Spacing.sm)
    card:SetTall(BL.UI.bl_ui_scale(48))
  end
end

function ROOT:UpdateEventLog(events)
  self.EventLog:Clear()
  if type(events) ~= "table" then
    return
  end

  local style = get_style()
  local start_index = math.max(#events - 7, 1)
  for index = #events, start_index, -1 do
    local entry = events[index]
    local text = format_event_entry(entry)
    local label = create_label(self.EventLog, tostring(text), style.Fonts.Body, style.Colors.TextMuted)
    label:Dock(TOP)
    label:DockMargin(0, 0, 0, style.Spacing.sm)
  end
end

function ROOT:FocusPlayerByName()
  local name = string.Trim(self.PlayerEntry:GetValue() or "")
  if name == "" then
    show_toast("Bitte einen Spielernamen eingeben.", "error")
    return
  end

  local snapshot = self.LastSnapshot or {}
  local players = snapshot.players_summary or {}
  for _, entry in ipairs(players) do
    if string.lower(entry.name or "") == string.lower(name) then
      self.SelectedSteamId = entry.steamid64
      self.PlayerEntry:SetText("")
      self:UpdatePlayerList(players)
      self:UpdatePlayerView(players, snapshot)
      show_toast("Spieler fokussiert: " .. (entry.name or name) .. ".", "success")
      return
    end
  end

  show_toast("Spieler nicht gefunden.", "error")
end

function ROOT:InspectSelectedPlayer()
  local snapshot = self.LastSnapshot or {}
  local players = snapshot.players_summary or {}
  for _, entry in ipairs(players) do
    if entry.steamid64 == self.SelectedSteamId then
      send_client_event({ type = "inspect_player", steamid64 = entry.steamid64 })
      show_toast("Inspektion angefragt: " .. (entry.name or "Spieler") .. ".")
      return
    end
  end

  show_toast("Bitte zuerst einen Spieler auswählen.", "error")
end

function ROOT:OpenMessageModal()
  local snapshot = self.LastSnapshot or {}
  local players = snapshot.players_summary or {}
  local target = nil
  for _, entry in ipairs(players) do
    if entry.steamid64 == self.SelectedSteamId then
      target = entry
      break
    end
  end

  if not target then
    show_toast("Bitte zuerst einen Spieler auswählen.", "error")
    return
  end

  local modal = vgui.Create("BLModal")
  modal:SetModalTitle("Nachricht an " .. (target.name or "Spieler"))
  modal:SetBackdropClosable(true)

  local body = vgui.Create("DPanel", modal)
  body:SetPaintBackground(false)
  body:Dock(FILL)
  body:DockMargin(BL.UI.Style.Spacing.lg, BL.UI.bl_ui_scale(52), BL.UI.Style.Spacing.lg, BL.UI.Style.Spacing.lg)

  local entry = create_text_entry(body, "Nachricht eingeben")
  entry:Dock(TOP)
  entry:SetTall(BL.UI.bl_ui_scale(36))

  local actions = vgui.Create("DPanel", body)
  actions:SetPaintBackground(false)
  actions:Dock(BOTTOM)
  actions:SetTall(BL.UI.bl_ui_scale(40))
  actions:DockMargin(0, BL.UI.Style.Spacing.md, 0, 0)

  local send = vgui.Create("BLButton", actions)
  send:SetText("Senden")
  send:SetVariant("primary")
  send:Dock(LEFT)
  send:DockMargin(0, 0, BL.UI.Style.Spacing.sm, 0)
  send.DoClick = function()
    local message = string.Trim(entry:GetValue() or "")
    if message == "" then
      show_toast("Nachricht darf nicht leer sein.", "error")
      return
    end
    send_client_event({ type = "message_player", steamid64 = target.steamid64, message = message })
    modal:Close()
    show_toast("Nachricht gesendet.", "success")
  end

  local cancel = vgui.Create("BLButton", actions)
  cancel:SetText("Abbrechen")
  cancel:SetVariant("ghost")
  cancel:Dock(LEFT)
  cancel.DoClick = function()
    modal:Close()
  end
end

function ROOT:CyclePhase()
  local snapshot = self.LastSnapshot or {}
  local phase = snapshot.phase or "LOBBY"
  local phases = { "LOBBY", "PREP", "ACTIVE", "POST" }
  local next_phase = phases[1]
  for index, value in ipairs(phases) do
    if value == phase then
      next_phase = phases[index % #phases + 1]
      break
    end
  end

  send_admin_action({ action = "round_set_phase", phase = next_phase, reason = "Lobby UI" })
end

vgui.Register("BLLobbyRoot", ROOT, "DPanel")

function BL.LobbyUI.Open()
  if IsValid(BL.LobbyUI.Root) then
    return
  end
  BL.LobbyUI.Root = vgui.Create("BLLobbyRoot")
end

function BL.LobbyUI.Close()
  if IsValid(BL.LobbyUI.Root) then
    BL.LobbyUI.Root:Close()
  end
end

function BL.LobbyUI.Toggle()
  if IsValid(BL.LobbyUI.Root) then
    BL.LobbyUI.Root:Close()
    return
  end
  BL.LobbyUI.Open()
end

concommand.Add("bl_lobby", function()
  BL.LobbyUI.Toggle()
end)
