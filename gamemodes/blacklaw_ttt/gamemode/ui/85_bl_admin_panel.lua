BL = BL or {}
BL.UI = BL.UI or {}
BL.AdminUI = BL.AdminUI or {}

local TEXT_ALIGN_RIGHT = TEXT_ALIGN_RIGHT or 2

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

local function create_combo(parent)
  local combo = vgui.Create("DComboBox", parent)
  combo:SetFont(BL.UI.Style.Fonts.Body)
  combo:SetTextColor(BL.UI.Style.Colors.Text)
  combo.Paint = function(self, w, h)
    local style = get_style()
    draw.RoundedBox(style.Radii.md, 0, 0, w, h, style.Colors.SurfaceStrong)
    surface.SetDrawColor(style.Colors.Border)
    surface.DrawOutlinedRect(0, 0, w, h, 1)
    self:SetTextColor(style.Colors.Text)
  end
  return combo
end

local function format_time(epoch)
  if type(epoch) ~= "number" then
    return "-"
  end
  return os.date("%H:%M:%S", epoch)
end

local function send_admin_action(payload)
  if not payload or type(payload) ~= "table" then
    return
  end
  net.Start(BL.Net.Messages.AdminAction)
  net.WriteTable(payload)
  net.SendToServer()
end

local ROUND_TAB = {}

function ROUND_TAB:Init()
  local style = get_style()
  self.Padding = style.Spacing.lg
  self:SetPaintBackground(false)

  self.ControlsCard = vgui.Create("BLCard", self)
  self.ControlsCard:SetTitle("Round-Steuerung")
  self.ControlsCard:SetSubtitle("Schnellaktionen für den Ablauf")

  self.Buttons = vgui.Create("DPanel", self.ControlsCard)
  self.Buttons:SetPaintBackground(false)
  self.Buttons:Dock(TOP)
  self.Buttons:DockMargin(0, BL.UI.bl_ui_scale(48), 0, 0)
  self.Buttons:SetTall(BL.UI.bl_ui_scale(44))

  self.StartButton = vgui.Create("BLButton", self.Buttons)
  self.StartButton:SetText("Start")
  self.StartButton:SetVariant("primary")
  self.StartButton:Dock(LEFT)
  self.StartButton:DockMargin(0, 0, style.Spacing.sm, 0)
  self.StartButton.DoClick = function()
    send_admin_action({ action = "round_start", reason = self:GetReason() })
  end

  self.EndButton = vgui.Create("BLButton", self.Buttons)
  self.EndButton:SetText("End")
  self.EndButton:SetVariant("ghost")
  self.EndButton:Dock(LEFT)
  self.EndButton:DockMargin(0, 0, style.Spacing.sm, 0)
  self.EndButton.DoClick = function()
    send_admin_action({ action = "round_end", reason = self:GetReason() })
  end

  self.RestartButton = vgui.Create("BLButton", self.Buttons)
  self.RestartButton:SetText("Restart")
  self.RestartButton:SetVariant("ghost")
  self.RestartButton:Dock(LEFT)
  self.RestartButton.DoClick = function()
    send_admin_action({ action = "round_restart", reason = self:GetReason() })
  end

  self.PhaseCard = vgui.Create("BLCard", self)
  self.PhaseCard:SetTitle("Phase setzen")
  self.PhaseCard:SetSubtitle("Setzt die aktuelle Runde sofort in eine Phase")

  self.PhaseCombo = create_combo(self.PhaseCard)
  self.PhaseCombo:Dock(TOP)
  self.PhaseCombo:DockMargin(0, BL.UI.bl_ui_scale(48), 0, style.Spacing.sm)
  self.PhaseCombo:SetTall(BL.UI.bl_ui_scale(36))
  self.PhaseCombo:AddChoice("LOBBY")
  self.PhaseCombo:AddChoice("PREP")
  self.PhaseCombo:AddChoice("ACTIVE")
  self.PhaseCombo:AddChoice("POST")
  self.PhaseCombo:ChooseOption("LOBBY", 1)

  self.SetPhaseButton = vgui.Create("BLButton", self.PhaseCard)
  self.SetPhaseButton:SetText("Phase setzen")
  self.SetPhaseButton:SetVariant("primary")
  self.SetPhaseButton:Dock(TOP)
  self.SetPhaseButton.DoClick = function()
    local selected_id = self.PhaseCombo:GetSelectedID() or 0
    local phase = self.PhaseCombo:GetOptionText(selected_id) or "LOBBY"
    send_admin_action({ action = "round_set_phase", phase = phase, reason = self:GetReason() })
  end

  self.DebugCard = vgui.Create("BLCard", self)
  self.DebugCard:SetTitle("Debug: Rolle erzwingen")
  self.DebugCard:SetSubtitle("Nur mit bl_admin_debug aktiv")

  self.RoleCombo = create_combo(self.DebugCard)
  self.RoleCombo:Dock(TOP)
  self.RoleCombo:DockMargin(0, BL.UI.bl_ui_scale(48), 0, style.Spacing.sm)
  self.RoleCombo:SetTall(BL.UI.bl_ui_scale(36))

  self.PlayerCombo = create_combo(self.DebugCard)
  self.PlayerCombo:Dock(TOP)
  self.PlayerCombo:DockMargin(0, 0, 0, style.Spacing.sm)
  self.PlayerCombo:SetTall(BL.UI.bl_ui_scale(36))

  self.ForceRoleButton = vgui.Create("BLButton", self.DebugCard)
  self.ForceRoleButton:SetText("Rolle setzen")
  self.ForceRoleButton:SetVariant("accent")
  self.ForceRoleButton:Dock(TOP)
  self.ForceRoleButton.DoClick = function()
    local player_id = self.PlayerCombo:GetOptionData(self.PlayerCombo:GetSelectedID() or 0)
    local role_id = self.RoleCombo:GetOptionData(self.RoleCombo:GetSelectedID() or 0)
    if not player_id or not role_id then
      return
    end
    send_admin_action({
      action = "round_force_role",
      target = tostring(player_id),
      role_id = tonumber(role_id),
      reason = self:GetReason(),
    })
  end

  self.ReasonEntry = create_text_entry(self, "Grund (optional)")
end

function ROUND_TAB:GetReason()
  if not IsValid(self.ReasonEntry) then
    return ""
  end
  return self.ReasonEntry:GetText() or ""
end

function ROUND_TAB:ApplySnapshot(payload)
  local admin_debug = payload and payload.admin_debug
  self.ForceRoleButton:SetEnabled(admin_debug == true)

  self.RoleCombo:Clear()
  local roles = payload and payload.roles or {}
  for _, role in ipairs(roles) do
    if role and role.name and role.id then
      self.RoleCombo:AddChoice(role.name, role.id)
    end
  end
  if #roles > 0 then
    self.RoleCombo:ChooseOptionID(1)
  end

  self.PlayerCombo:Clear()
  local snapshot = payload and payload.snapshot or {}
  for _, entry in ipairs(snapshot.players_summary or {}) do
    if entry and entry.name and entry.steamid64 then
      self.PlayerCombo:AddChoice(entry.name, entry.steamid64)
    end
  end
  if (snapshot.players_summary and #snapshot.players_summary > 0) then
    self.PlayerCombo:ChooseOptionID(1)
  end
end

function ROUND_TAB:PerformLayout(w, h)
  local style = get_style()
  local padding = self.Padding

  self.ControlsCard:SetPos(padding, padding)
  self.ControlsCard:SetSize(w * 0.5 - padding * 1.5, h * 0.4 - padding)

  self.PhaseCard:SetPos(padding, h * 0.4 + padding)
  self.PhaseCard:SetSize(w * 0.5 - padding * 1.5, h * 0.6 - padding * 2)

  self.DebugCard:SetPos(w * 0.5 + padding * 0.5, padding)
  self.DebugCard:SetSize(w * 0.5 - padding * 1.5, h - padding * 3 - BL.UI.bl_ui_scale(40))

  self.ReasonEntry:SetPos(padding, h - padding - BL.UI.bl_ui_scale(36))
  self.ReasonEntry:SetSize(w - padding * 2, BL.UI.bl_ui_scale(36))
end

vgui.Register("BLAdminRoundTab", ROUND_TAB, "DPanel")

local PLAYERS_TAB = {}

function PLAYERS_TAB:Init()
  local style = get_style()
  self.Padding = style.Spacing.lg
  self.Selected = nil
  self:SetPaintBackground(false)

  self.ListCard = vgui.Create("BLCard", self)
  self.ListCard:SetTitle("Spieler")
  self.ListCard:SetSubtitle("Auswählen für Aktionen")

  self.Scroll = vgui.Create("DScrollPanel", self.ListCard)
  self.Scroll:Dock(FILL)
  self.Scroll:DockMargin(0, BL.UI.bl_ui_scale(48), 0, 0)
  apply_scroll_style(self.Scroll)

  self.List = vgui.Create("DIconLayout", self.Scroll)
  self.List:Dock(FILL)
  self.List:SetSpaceY(style.Spacing.sm)

  self.ActionCard = vgui.Create("BLCard", self)
  self.ActionCard:SetTitle("Aktionen")
  self.ActionCard:SetSubtitle("Spieler-Tools")

  self.ActionScroll = vgui.Create("DScrollPanel", self.ActionCard)
  self.ActionScroll:Dock(FILL)
  self.ActionScroll:DockMargin(0, BL.UI.bl_ui_scale(48), 0, 0)
  apply_scroll_style(self.ActionScroll)

  self.ActionList = vgui.Create("DIconLayout", self.ActionScroll)
  self.ActionList:Dock(FILL)
  self.ActionList:SetSpaceY(style.Spacing.sm)

  self.HealthEntry = create_text_entry(self.ActionCard, "Health")
  self.ArmorEntry = create_text_entry(self.ActionCard, "Armor")
  self.CreditEntry = create_text_entry(self.ActionCard, "Credits")
  self.ReasonEntry = create_text_entry(self, "Grund (optional)")

  self:BuildActions()
end

function PLAYERS_TAB:GetReason()
  if not IsValid(self.ReasonEntry) then
    return ""
  end
  return self.ReasonEntry:GetText() or ""
end

function PLAYERS_TAB:GetSelectedTarget()
  return self.Selected and self.Selected.steamid64 or nil
end

function PLAYERS_TAB:AddActionButton(label, action, variant)
  local button = vgui.Create("BLButton", self.ActionList)
  button:SetText(label)
  button:SetVariant(variant or "ghost")
  button.DoClick = function()
    local target = self:GetSelectedTarget()
    if not target then
      return
    end
    send_admin_action({ action = action, target = target, reason = self:GetReason() })
  end
  return button
end

function PLAYERS_TAB:BuildActions()
  self.ActionList:Clear()

  self:AddActionButton("Bring", "player_bring")
  self:AddActionButton("Goto", "player_goto")
  self:AddActionButton("Freeze", "player_freeze")
  self:AddActionButton("Unfreeze", "player_unfreeze")
  self:AddActionButton("Respawn", "player_respawn", "primary")
  self:AddActionButton("Slay", "player_slay", "accent")

  local health_btn = vgui.Create("BLButton", self.ActionList)
  health_btn:SetText("Set Health")
  health_btn:SetVariant("ghost")
  health_btn.DoClick = function()
    local target = self:GetSelectedTarget()
    if not target then
      return
    end
    send_admin_action({
      action = "player_set_health",
      target = target,
      value = self.HealthEntry:GetText(),
      reason = self:GetReason(),
    })
  end

  local armor_btn = vgui.Create("BLButton", self.ActionList)
  armor_btn:SetText("Set Armor")
  armor_btn:SetVariant("ghost")
  armor_btn.DoClick = function()
    local target = self:GetSelectedTarget()
    if not target then
      return
    end
    send_admin_action({
      action = "player_set_armor",
      target = target,
      value = self.ArmorEntry:GetText(),
      reason = self:GetReason(),
    })
  end

  local credits_btn = vgui.Create("BLButton", self.ActionList)
  credits_btn:SetText("Give Credits")
  credits_btn:SetVariant("ghost")
  credits_btn.DoClick = function()
    local target = self:GetSelectedTarget()
    if not target then
      return
    end
    send_admin_action({
      action = "player_give_credits",
      target = target,
      value = self.CreditEntry:GetText(),
      reason = self:GetReason(),
    })
  end

  local admin_btn = vgui.Create("BLButton", self.ActionList)
  admin_btn:SetText("Make Admin")
  admin_btn:SetVariant("primary")
  admin_btn.DoClick = function()
    local target = self:GetSelectedTarget()
    if not target then
      return
    end
    send_admin_action({
      action = "player_make_admin",
      target = target,
      reason = self:GetReason(),
    })
  end
end

function PLAYERS_TAB:ApplySnapshot(payload)
  local snapshot = payload and payload.snapshot or {}
  self.List:Clear()

  for _, entry in ipairs(snapshot.players_summary or {}) do
    local row = self.List:Add("BLListRow")
    row:SetText(entry.name or "Unbekannt")
    row:SetTall(BL.UI.bl_ui_scale(40))
    row.DoClick = function()
      self.Selected = entry
      for _, child in ipairs(self.List:GetChildren() or {}) do
        if child.SetActive then
          child:SetActive(child == row)
        end
      end
    end
  end

  self.Selected = nil
end

function PLAYERS_TAB:PerformLayout(w, h)
  local style = get_style()
  local padding = self.Padding
  local card_w = (w - padding * 3) * 0.5

  self.ListCard:SetPos(padding, padding)
  self.ListCard:SetSize(card_w, h - padding * 3 - BL.UI.bl_ui_scale(40))

  self.ActionCard:SetPos(padding * 2 + card_w, padding)
  self.ActionCard:SetSize(card_w, h - padding * 3 - BL.UI.bl_ui_scale(40))

  local entry_w = card_w - padding * 2
  local entry_h = BL.UI.bl_ui_scale(36)
  local action_h = self.ActionCard:GetTall()

  if IsValid(self.HealthEntry) then
    self.HealthEntry:SetSize(entry_w, entry_h)
    self.HealthEntry:SetPos(padding, action_h - padding - entry_h * 3 - style.Spacing.sm * 2)
  end

  if IsValid(self.ArmorEntry) then
    self.ArmorEntry:SetSize(entry_w, entry_h)
    self.ArmorEntry:SetPos(padding, action_h - padding - entry_h * 2 - style.Spacing.sm)
  end

  if IsValid(self.CreditEntry) then
    self.CreditEntry:SetSize(entry_w, entry_h)
    self.CreditEntry:SetPos(padding, action_h - padding - entry_h)
  end

  self.ReasonEntry:SetPos(padding, h - padding - entry_h)
  self.ReasonEntry:SetSize(w - padding * 2, entry_h)
end

vgui.Register("BLAdminPlayersTab", PLAYERS_TAB, "DPanel")

local LOGS_TAB = {}

function LOGS_TAB:Init()
  local style = get_style()
  self.Padding = style.Spacing.lg
  self:SetPaintBackground(false)

  self.EventCard = vgui.Create("BLCard", self)
  self.EventCard:SetTitle("Event Log")
  self.EventCard:SetSubtitle("Runden-Events")

  self.EventFilter = create_text_entry(self.EventCard, "Filter: Player oder Typ")
  self.EventFilter:Dock(TOP)
  self.EventFilter:DockMargin(0, BL.UI.bl_ui_scale(48), 0, style.Spacing.sm)
  self.EventFilter:SetTall(BL.UI.bl_ui_scale(36))

  self.EventScroll = vgui.Create("DScrollPanel", self.EventCard)
  self.EventScroll:Dock(FILL)
  apply_scroll_style(self.EventScroll)

  self.EventList = vgui.Create("DIconLayout", self.EventScroll)
  self.EventList:Dock(FILL)
  self.EventList:SetSpaceY(style.Spacing.sm)

  self.AdminCard = vgui.Create("BLCard", self)
  self.AdminCard:SetTitle("Admin Action Log")
  self.AdminCard:SetSubtitle("Audit-Log")

  self.AdminFilter = create_text_entry(self.AdminCard, "Filter: Player oder Aktion")
  self.AdminFilter:Dock(TOP)
  self.AdminFilter:DockMargin(0, BL.UI.bl_ui_scale(48), 0, style.Spacing.sm)
  self.AdminFilter:SetTall(BL.UI.bl_ui_scale(36))

  self.AdminScroll = vgui.Create("DScrollPanel", self.AdminCard)
  self.AdminScroll:Dock(FILL)
  apply_scroll_style(self.AdminScroll)

  self.AdminList = vgui.Create("DIconLayout", self.AdminScroll)
  self.AdminList:Dock(FILL)
  self.AdminList:SetSpaceY(style.Spacing.sm)

  self.EventFilter.OnValueChange = function()
    self:Refresh()
  end
  self.AdminFilter.OnValueChange = function()
    self:Refresh()
  end
end

local function event_matches_filter(entry, filter)
  if filter == "" then
    return true
  end
  local lower = string.lower(filter)
  local type_match = entry.type and string.find(string.lower(entry.type), lower, 1, true)
  if type_match then
    return true
  end
  local payload = entry.payload or {}
  for _, field in pairs(payload) do
    if type(field) == "string" then
      if string.find(string.lower(field), lower, 1, true) then
        return true
      end
    end
  end
  return false
end

local function admin_matches_filter(entry, filter)
  if filter == "" then
    return true
  end
  local lower = string.lower(filter)
  if entry.action and string.find(string.lower(entry.action), lower, 1, true) then
    return true
  end
  local actor = entry.actor or {}
  local target = entry.target or {}
  local fields = {
    actor.name,
    actor.steamid64,
    target.name,
    target.steamid64,
  }
  for _, value in ipairs(fields) do
    if type(value) == "string" and string.find(string.lower(value), lower, 1, true) then
      return true
    end
  end
  return false
end

function LOGS_TAB:Refresh()
  local snapshot = self.Snapshot or {}
  local filter_event = string.lower(self.EventFilter:GetText() or "")
  local filter_admin = string.lower(self.AdminFilter:GetText() or "")

  self.EventList:Clear()
  for _, entry in ipairs(snapshot.event_log or {}) do
    if event_matches_filter(entry, filter_event) then
      local row = self.EventList:Add("BLListRow")
      local line = string.format("%s · %s", format_time(entry.time), entry.type or "-")
      row:SetText(line)
      row:SetTall(BL.UI.bl_ui_scale(32))
    end
  end

  self.AdminList:Clear()
  for _, entry in ipairs(self.AdminActions or {}) do
    if admin_matches_filter(entry, filter_admin) then
      local actor = entry.actor or {}
      local target = entry.target or {}
      local line = string.format(
        "%s · %s -> %s · %s",
        format_time(entry.time),
        actor.name or "-",
        target.name or "-",
        entry.action or "-"
      )
      local row = self.AdminList:Add("BLListRow")
      row:SetText(line)
      row:SetTall(BL.UI.bl_ui_scale(32))
    end
  end
end

function LOGS_TAB:ApplySnapshot(payload)
  self.Snapshot = payload and payload.snapshot or {}
  self.AdminActions = payload and payload.admin_actions or {}
  self:Refresh()
end

function LOGS_TAB:PerformLayout(w, h)
  local padding = self.Padding
  local card_w = (w - padding * 3) * 0.5

  self.EventCard:SetPos(padding, padding)
  self.EventCard:SetSize(card_w, h - padding * 2)

  self.AdminCard:SetPos(padding * 2 + card_w, padding)
  self.AdminCard:SetSize(card_w, h - padding * 2)
end

vgui.Register("BLAdminLogsTab", LOGS_TAB, "DPanel")

local SETTINGS_TAB = {}

function SETTINGS_TAB:Init()
  local style = get_style()
  self.Padding = style.Spacing.lg
  self:SetPaintBackground(false)

  self.SettingsCard = vgui.Create("BLCard", self)
  self.SettingsCard:SetTitle("Server ConVars")
  self.SettingsCard:SetSubtitle("Nur mit settings.edit")

  self.Scroll = vgui.Create("DScrollPanel", self.SettingsCard)
  self.Scroll:Dock(FILL)
  self.Scroll:DockMargin(0, BL.UI.bl_ui_scale(48), 0, 0)
  apply_scroll_style(self.Scroll)

  self.List = vgui.Create("DIconLayout", self.Scroll)
  self.List:Dock(FILL)
  self.List:SetSpaceY(style.Spacing.sm)

  self.ReasonEntry = create_text_entry(self, "Grund (optional)")
end

function SETTINGS_TAB:GetReason()
  if not IsValid(self.ReasonEntry) then
    return ""
  end
  return self.ReasonEntry:GetText() or ""
end

function SETTINGS_TAB:ApplySnapshot(payload)
  self.List:Clear()

  local permissions = payload and payload.permissions or {}
  if not permissions.settings_edit then
    local row = self.List:Add("DLabel")
    row:SetText("Keine Berechtigung")
    row:SetFont(BL.UI.Style.Fonts.Body)
    row:SetTextColor(BL.UI.Style.Colors.TextMuted)
    row:SizeToContents()
    return
  end

  for _, entry in ipairs(payload.settings or {}) do
    local row = self.List:Add("DPanel")
    row:SetTall(BL.UI.bl_ui_scale(80))
    row.Paint = function(_, w, h)
      local style = get_style()
      draw.RoundedBox(style.Radii.md, 0, 0, w, h, style.Colors.Row)
      surface.SetDrawColor(style.Colors.Border)
      surface.DrawOutlinedRect(0, 0, w, h, 1)
    end

    local label = vgui.Create("DLabel", row)
    label:SetFont(BL.UI.Style.Fonts.Label)
    label:SetTextColor(BL.UI.Style.Colors.Text)
    label:SetText(entry.name)
    label:Dock(TOP)
    label:DockMargin(BL.UI.Style.Spacing.md, BL.UI.Style.Spacing.sm, 0, 0)
    label:SizeToContents()

    local help = vgui.Create("DLabel", row)
    help:SetFont(BL.UI.Style.Fonts.Body)
    help:SetTextColor(BL.UI.Style.Colors.TextMuted)
    help:SetText(entry.help or "")
    help:Dock(TOP)
    help:DockMargin(BL.UI.Style.Spacing.md, 0, 0, 0)
    help:SetTall(BL.UI.bl_ui_scale(20))

    local controls = vgui.Create("DPanel", row)
    controls:Dock(TOP)
    controls:SetPaintBackground(false)
    controls:SetTall(BL.UI.bl_ui_scale(36))
    controls:DockMargin(BL.UI.Style.Spacing.md, BL.UI.Style.Spacing.sm, 0, 0)

    local entry_box = create_text_entry(controls, tostring(entry.value))
    entry_box:Dock(LEFT)
    entry_box:DockMargin(0, 0, BL.UI.Style.Spacing.sm, 0)
    entry_box:SetWide(BL.UI.bl_ui_scale(160))
    entry_box:SetText(tostring(entry.value))

    local button = vgui.Create("BLButton", controls)
    button:SetText("Apply")
    button:SetVariant("primary")
    button:Dock(LEFT)
    button:DockMargin(0, 0, BL.UI.Style.Spacing.sm, 0)
    button:SetWide(BL.UI.bl_ui_scale(120))
    button.DoClick = function()
      send_admin_action({
        action = "settings_set",
        name = entry.name,
        value = entry_box:GetText(),
        reason = self:GetReason(),
      })
    end
  end
end

function SETTINGS_TAB:PerformLayout(w, h)
  local padding = self.Padding

  self.SettingsCard:SetPos(padding, padding)
  self.SettingsCard:SetSize(w - padding * 2, h - padding * 3 - BL.UI.bl_ui_scale(40))

  self.ReasonEntry:SetPos(padding, h - padding - BL.UI.bl_ui_scale(36))
  self.ReasonEntry:SetSize(w - padding * 2, BL.UI.bl_ui_scale(36))
end

vgui.Register("BLAdminSettingsTab", SETTINGS_TAB, "DPanel")

local ROOT = {}

function ROOT:Init()
  local style = get_style()
  self:SetSize(ScrW(), ScrH())
  self:SetPos(0, 0)
  self:MakePopup()
  self:SetKeyboardInputEnabled(true)
  self:SetMouseInputEnabled(true)

  self.Frame = vgui.Create("DPanel", self)
  self.Frame.Paint = function(_, w, h)
    draw.RoundedBox(style.Radii.lg, 0, 0, w, h, style.Colors.Surface)
    surface.SetDrawColor(style.Colors.CardBorder)
    surface.DrawOutlinedRect(0, 0, w, h, 1)
  end

  self.Header = vgui.Create("DPanel", self.Frame)
  self.Header:Dock(TOP)
  self.Header:SetTall(BL.UI.bl_ui_scale(56))
  self.Header:SetPaintBackground(false)

  self.Title = vgui.Create("DLabel", self.Header)
  self.Title:SetFont(style.Fonts.Title)
  self.Title:SetTextColor(style.Colors.Text)
  self.Title:SetText("Adminpanel")
  self.Title:Dock(LEFT)
  self.Title:DockMargin(style.Spacing.lg, 0, 0, 0)
  self.Title:SizeToContents()

  self.RefreshButton = vgui.Create("BLButton", self.Header)
  self.RefreshButton:SetText("Refresh")
  self.RefreshButton:SetVariant("ghost")
  self.RefreshButton:Dock(RIGHT)
  self.RefreshButton:DockMargin(0, style.Spacing.sm, style.Spacing.sm, style.Spacing.sm)
  self.RefreshButton.DoClick = function()
    BL.AdminUI.RequestSnapshot()
  end

  self.CloseButton = vgui.Create("BLButton", self.Header)
  self.CloseButton:SetText("Close")
  self.CloseButton:SetVariant("ghost")
  self.CloseButton:Dock(RIGHT)
  self.CloseButton:DockMargin(0, style.Spacing.sm, style.Spacing.sm, style.Spacing.sm)
  self.CloseButton.DoClick = function()
    self:Close()
  end

  self.Tabs = vgui.Create("BLTabs", self.Frame)
  self.Tabs:Dock(FILL)
  self.Tabs:DockMargin(style.Spacing.lg, style.Spacing.sm, style.Spacing.lg, style.Spacing.lg)

  self.RoundTab = self.Tabs:AddTab("Round", vgui.Create("BLAdminRoundTab", self.Tabs.Body))
  self.PlayersTab = self.Tabs:AddTab("Players", vgui.Create("BLAdminPlayersTab", self.Tabs.Body))
  self.LogsTab = self.Tabs:AddTab("Logs", vgui.Create("BLAdminLogsTab", self.Tabs.Body))
  self.SettingsTab = self.Tabs:AddTab("Settings", vgui.Create("BLAdminSettingsTab", self.Tabs.Body))

  BL.AdminUI.RequestSnapshot()
end

function ROOT:ApplySnapshot(payload)
  if IsValid(self.RoundTab) then
    self.RoundTab:ApplySnapshot(payload)
  end
  if IsValid(self.PlayersTab) then
    self.PlayersTab:ApplySnapshot(payload)
  end
  if IsValid(self.LogsTab) then
    self.LogsTab:ApplySnapshot(payload)
  end
  if IsValid(self.SettingsTab) then
    self.SettingsTab:ApplySnapshot(payload)
  end
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
  local frame_w = BL.UI.bl_ui_scale(1100)
  local frame_h = BL.UI.bl_ui_scale(760)
  local x = (w - frame_w) * 0.5
  local y = (h - frame_h) * 0.5
  self.Frame:SetPos(x, y)
  self.Frame:SetSize(frame_w, frame_h)
end

function ROOT:Paint(w, h)
  local style = get_style()
  local overlay = style.Colors.Overlay or Color(0, 0, 0, 200)
  draw.RoundedBox(0, 0, 0, w, h, overlay)
end

function ROOT:OnRemove()
  if BL.AdminUI and BL.AdminUI.Root == self then
    BL.AdminUI.Root = nil
  end
end

vgui.Register("BLAdminRoot", ROOT, "DPanel")

function BL.AdminUI.ApplySnapshot(payload)
  BL.AdminUI.State = payload
  if IsValid(BL.AdminUI.Root) then
    BL.AdminUI.Root:ApplySnapshot(payload)
  end
end

function BL.AdminUI.RequestSnapshot()
  net.Start(BL.Net.Messages.AdminRequest)
  net.WriteTable({})
  net.SendToServer()
end

function BL.AdminUI.Open()
  if IsValid(BL.AdminUI.Root) then
    return
  end
  BL.AdminUI.Root = vgui.Create("BLAdminRoot")
end

function BL.AdminUI.Close()
  if IsValid(BL.AdminUI.Root) then
    BL.AdminUI.Root:Close()
  end
end

function BL.AdminUI.Toggle()
  if IsValid(BL.AdminUI.Root) then
    BL.AdminUI.Root:Close()
    return
  end
  BL.AdminUI.Open()
end

concommand.Add("bl_adminpanel", function()
  BL.AdminUI.Toggle()
end)

hook.Add("ShowSpare2", "BL.AdminUI.Toggle", function()
  BL.AdminUI.Toggle()
  return false
end)
