BL = BL or {}
BL.HUD = BL.HUD or {}

BL.HUD.State = BL.HUD.State or {
  last_snapshot_at = 0,
  last_event_count = 0,
  role_name = "Unknown",
  role_key = "UNKNOWN",
  last_role_key = nil,
  last_role_name = nil,
  phase = "LOBBY",
  round_id = 0,
  phase_end = nil,
  event_entries = {},
  credits = 0,
}

local EVENT_MAX = 8

local function get_style()
  return BL.UI and BL.UI.Style or {}
end

local function get_local_entry(snapshot)
  if type(snapshot) ~= "table" then
    return nil
  end

  local players = snapshot.players_summary
  if type(players) ~= "table" then
    return nil
  end

  local ply = LocalPlayer()
  if not IsValid(ply) then
    return nil
  end

  local steamid64 = ply:SteamID64()
  if not steamid64 or steamid64 == "" then
    return nil
  end

  for _, entry in ipairs(players) do
    if entry.steamid64 == steamid64 then
      return entry
    end
  end

  return nil
end

local function get_role_color(role_key)
  local style = get_style()
  local colors = {
    INNOCENT = Color(123, 166, 255),
    TRAITOR = Color(255, 123, 123),
  }
  return colors[role_key] or style.Colors and style.Colors.TextMuted or color_white
end

local function format_timer(seconds)
  if not seconds or seconds < 0 then
    return "--:--"
  end
  local mins = math.floor(seconds / 60)
  local secs = math.floor(seconds % 60)
  return string.format("%02d:%02d", mins, secs)
end

local function format_event(entry)
  if type(entry) ~= "table" then
    return nil
  end

  local event_type = entry.type
  if type(event_type) ~= "string" then
    return nil
  end

  local payload = entry.payload
  if type(payload) ~= "table" then
    payload = {}
  end

  if event_type == "phase_lobby" then
    return "Phase: Lobby", "Status"
  end
  if event_type == "phase_prep" then
    return "Phase: Vorbereitung", "Status"
  end
  if event_type == "phase_active" then
    return "Phase: Runde aktiv", "Status"
  end
  if event_type == "phase_post" then
    return "Phase: Auswertung", "Status"
  end
  if event_type == "round_win" then
    local winner = payload.winner or "unbekannt"
    local reason = payload.reason or ""
    local suffix = reason ~= "" and (" (" .. reason .. ")") or ""
    return "Runde entschieden: " .. winner .. suffix, "Highlight"
  end
  if event_type == "round_summary" then
    local winner = payload.winner or "unbekannt"
    return "Rundenzusammenfassung: " .. winner, "Muted"
  end
  if event_type == "role_reveal" then
    local name = payload.name or "Spieler"
    local role_name = payload.role_name or "Unbekannt"
    return name .. " ist " .. role_name, "Role"
  end
  if event_type == "player_death" then
    local name = payload.name or "Spieler"
    if payload.role_public or payload.role_revealed then
      local role = payload.role_name or "Unbekannt"
      return name .. " ist gestorben (" .. role .. ")", "Alert"
    end
    return name .. " ist gestorben", "Alert"
  end
  if event_type == "admin_force_start" then
    return "Adminstart: " .. (payload.by or "unbekannt"), "Muted"
  end
  if event_type == "admin_force_end" then
    return "Adminende: " .. (payload.by or "unbekannt"), "Muted"
  end

  return nil
end

local function pick_event_color(tag)
  local style = get_style()
  if not style.Colors then
    return color_white
  end

  if tag == "Highlight" then
    return style.Colors.Primary or color_white
  end
  if tag == "Alert" then
    return style.Colors.ToastError or color_white
  end
  if tag == "Role" then
    return style.Colors.Accent or color_white
  end
  if tag == "Muted" then
    return style.Colors.TextMuted or color_white
  end
  if tag == "Status" then
    return style.Colors.Text or color_white
  end

  return style.Colors.Text or color_white
end

local function find_phase_end(events)
  if type(events) ~= "table" then
    return nil
  end

  for index = #events, 1, -1 do
    local entry = events[index]
    if type(entry) == "table" then
      local event_type = entry.type
      if event_type == "phase_prep" or event_type == "phase_active" or event_type == "phase_post" then
        local payload = entry.payload
        if type(payload) == "table" and type(payload.ends_at) == "number" then
          return payload.ends_at
        end
      end
    end
  end

  return nil
end

local function is_event_log_enabled()
  if GM and GM.BLTTT and GM.BLTTT.GetConfigValue then
    local enabled = GM.BLTTT.GetConfigValue("Client", "bl_show_eventlog")
    if type(enabled) == "boolean" then
      return enabled
    end
  end
  return true
end

local function emit_toast(message, kind, duration)
  if BL.UI and BL.UI.Toast and BL.UI.Toast.Show then
    BL.UI.Toast.Show(message, kind or "info", duration or 4)
  end
end

local function play_cue(name)
  if BL.Audio and BL.Audio.PlayCue then
    BL.Audio.PlayCue(name)
  end
end

local function handle_event_feedback(event)
  if type(event) ~= "table" then
    return
  end
  local event_type = event.type
  if type(event_type) ~= "string" then
    return
  end
  local payload = type(event.payload) == "table" and event.payload or {}

  if event_type == "round_win" then
    local winner = payload.winner or "unbekannt"
    emit_toast("Runde beendet: " .. winner, "info", 5)
  elseif event_type == "phase_active" then
    emit_toast("Runde gestartet", "info", 4)
    play_cue("round_start")
  end
end

function BL.HUD.RefreshState()
  local cache = BL.Net and BL.Net.Cache or nil
  local snapshot = BL.Net and BL.Net.GetSnapshot and BL.Net.GetSnapshot() or nil
  local state = BL.HUD.State

  if cache and cache.last_snapshot_at and cache.last_snapshot_at ~= state.last_snapshot_at then
    state.last_snapshot_at = cache.last_snapshot_at

    if type(snapshot) == "table" then
      state.phase = snapshot.phase or state.phase
      state.round_id = snapshot.round_id or state.round_id
      state.phase_end = find_phase_end(snapshot.event_log) or state.phase_end

      local entry = get_local_entry(snapshot)
      if entry then
        local role_name = entry.role_name
        local role_key = entry.role_key
        if type(role_name) ~= "string" or role_name == "" then
          role_name = "Unknown"
        end
        if type(role_key) ~= "string" or role_key == "" then
          role_key = "UNKNOWN"
        end
        state.role_name = role_name
        state.role_key = role_key
      else
        state.role_name = "Unknown"
        state.role_key = "UNKNOWN"
      end

      if state.role_key ~= "UNKNOWN" and state.role_key ~= (state.last_role_key or "") then
        emit_toast("Rolle zugewiesen: " .. state.role_name, "success", 4)
        play_cue("role_reveal_end")
      end
      state.last_role_key = state.role_key
      state.last_role_name = state.role_name

      if type(snapshot.credits) == "number" then
        state.credits = math.max(0, math.floor(snapshot.credits))
      else
        state.credits = 0
      end

      state.event_entries = {}
      local events = snapshot.event_log
      if type(events) == "table" then
        for _, event in ipairs(events) do
          local text, tag = format_event(event)
          if text then
            local time_label = ""
            if type(event.time) == "number" then
              time_label = os.date("%H:%M", event.time)
            end
            state.event_entries[#state.event_entries + 1] = {
              text = text,
              color = pick_event_color(tag),
              time = time_label,
            }
          end
        end
      end

      if #state.event_entries > EVENT_MAX then
        local offset = #state.event_entries - EVENT_MAX
        for _ = 1, offset do
          table.remove(state.event_entries, 1)
        end
      end
    end
  end

  local events = BL.Net and BL.Net.GetEvents and BL.Net.GetEvents() or {}
  if type(events) == "table" then
    for index = state.last_event_count + 1, #events do
      local event = events[index]
      local text, tag = format_event(event)
      if text then
        local time_label = ""
        if type(event.time) == "number" then
          time_label = os.date("%H:%M", event.time)
        end
        state.event_entries[#state.event_entries + 1] = {
          text = text,
          color = pick_event_color(tag),
          time = time_label,
        }
      end

      if event and type(event.payload) == "table" then
        local event_type = event.type
        if event_type == "phase_prep" or event_type == "phase_active" or event_type == "phase_post" then
          if type(event.payload.ends_at) == "number" then
            state.phase_end = event.payload.ends_at
          end
        end
      end

      handle_event_feedback(event)
    end
  end

  state.last_event_count = type(events) == "table" and #events or state.last_event_count

  if #state.event_entries > EVENT_MAX then
    local offset = #state.event_entries - EVENT_MAX
    for _ = 1, offset do
      table.remove(state.event_entries, 1)
    end
  end
end

local PANEL = {}

function PANEL:Init()
  self:SetMouseInputEnabled(false)
  self:SetKeyboardInputEnabled(false)
  self.LastW = ScrW()
  self.LastH = ScrH()
  self:SetSize(self.LastW, self.LastH)
  self:SetPos(0, 0)
  self.NextUpdate = 0
end

function PANEL:Think()
  local now = CurTime()
  if now >= self.NextUpdate then
    BL.HUD.RefreshState()
    self.NextUpdate = now + 0.2
  end

  local w, h = ScrW(), ScrH()
  if w ~= self.LastW or h ~= self.LastH then
    self.LastW = w
    self.LastH = h
    self:SetSize(w, h)
  end
end

function PANEL:Paint(w, h)
  local style = get_style()
  if not style.Colors then
    return
  end

  local scale = BL.UI and BL.UI.bl_ui_scale or function(v) return v end
  local margin = style.Spacing and style.Spacing.xl or scale(24)
  local left_width = scale(320)
  local right_width = scale(360)
  local role_height = scale(140)
  local stats_height = scale(120)
  local round_height = scale(120)
  local event_height = scale(280)

  local compact = false
  if GM and GM.BLTTT and GM.BLTTT.GetConfigValue then
    compact = GM.BLTTT.GetConfigValue("Client", "bl_ui_compact") == true
  end
  if compact then
    left_width = scale(280)
    right_width = scale(320)
    role_height = scale(120)
    stats_height = scale(100)
    round_height = scale(110)
    event_height = scale(220)
  end

  local left_x = margin
  local left_y = margin
  local right_x = w - margin - right_width
  local right_y = margin

  local stacked = right_x <= left_x + left_width + margin
  if stacked then
    right_x = left_x
    right_y = left_y + role_height + stats_height + margin * 2
  end

  local function draw_card(x, y, width, height)
    draw.RoundedBox(style.Radii.lg, x, y, width, height, style.Colors.Surface)
    surface.SetDrawColor(style.Colors.CardBorder)
    surface.DrawOutlinedRect(x, y, width, height, 1)
  end

  local function draw_label(text, x, y)
    draw.SimpleText(text, style.Fonts.HUDLabel, x, y, style.Colors.TextMuted)
  end

  local function draw_value(text, x, y, color, font)
    draw.SimpleText(text, font or style.Fonts.HUDValue, x, y, color or style.Colors.Text)
  end

  draw_card(left_x, left_y, left_width, role_height)

  local badge_x = left_x + margin
  local badge_y = left_y + margin
  local badge_w = scale(120)
  local badge_h = scale(34)
  local role_color = get_role_color(BL.HUD.State.role_key)

  draw.RoundedBox(style.Radii.md, badge_x, badge_y, badge_w, badge_h, role_color)
  draw.SimpleText("ROLLE", style.Fonts.HUDLabel, badge_x + scale(12), badge_y + scale(8), style.Colors.Text)

  draw_value(BL.HUD.State.role_name, badge_x, badge_y + badge_h + scale(10), style.Colors.Text, style.Fonts.Heading)
  draw_label("Rollenstatus", badge_x, badge_y + badge_h + scale(44))
  draw_value(BL.HUD.State.role_key, badge_x, badge_y + badge_h + scale(60), style.Colors.TextMuted, style.Fonts.Body)

  local stats_y = left_y + role_height + margin
  draw_card(left_x, stats_y, left_width, stats_height)

  local ply = LocalPlayer()
  local health = IsValid(ply) and math.max(ply:Health(), 0) or 0
  local armor = IsValid(ply) and math.max(ply:Armor(), 0) or 0
  local weapon = IsValid(ply) and ply:GetActiveWeapon() or nil
  local ammo = 0
  if IsValid(weapon) then
    local ammo_type = weapon:GetPrimaryAmmoType()
    if ammo_type and ammo_type >= 0 then
      ammo = ply:GetAmmoCount(ammo_type)
    end
  end

  local column_w = left_width / 4
  local stats_top = stats_y + margin

  draw_label("HP", left_x + margin, stats_top)
  draw_value(tostring(health), left_x + margin, stats_top + scale(18), style.Colors.Text)

  draw_label("ARMOR", left_x + column_w + margin, stats_top)
  draw_value(tostring(armor), left_x + column_w + margin, stats_top + scale(18), style.Colors.Text)

  draw_label("AMMO", left_x + column_w * 2 + margin, stats_top)
  draw_value(tostring(ammo), left_x + column_w * 2 + margin, stats_top + scale(18), style.Colors.Text)

  draw_label("CREDITS", left_x + column_w * 3 + margin, stats_top)
  draw_value(tostring(BL.HUD.State.credits or 0), left_x + column_w * 3 + margin, stats_top + scale(18), style.Colors.Text)

  draw_card(right_x, right_y, right_width, round_height)

  local phase_text = BL.HUD.State.phase or "LOBBY"
  local phase_color = style.Colors.Accent
  if phase_text == "ACTIVE" then
    phase_color = style.Colors.Primary
  elseif phase_text == "POST" then
    phase_color = style.Colors.ToastError
  elseif phase_text == "PREP" then
    phase_color = style.Colors.Accent
  else
    phase_color = style.Colors.TextMuted
  end

  local phase_badge_w = scale(110)
  local phase_badge_h = scale(30)
  local phase_badge_x = right_x + margin
  local phase_badge_y = right_y + margin
  draw.RoundedBox(style.Radii.md, phase_badge_x, phase_badge_y, phase_badge_w, phase_badge_h, phase_color)
  draw.SimpleText("PHASE", style.Fonts.HUDLabel, phase_badge_x + scale(10), phase_badge_y + scale(8), style.Colors.Text)

  draw_value(phase_text, phase_badge_x, phase_badge_y + phase_badge_h + scale(10), style.Colors.Text, style.Fonts.Heading)

  local time_left = BL.HUD.State.phase_end and math.max(0, BL.HUD.State.phase_end - CurTime()) or nil
  local timer_value = BL.HUD.State.phase_end and format_timer(time_left) or "--:--"
  draw_label("ROUND TIMER", phase_badge_x, phase_badge_y + phase_badge_h + scale(40))
  draw_value(timer_value, phase_badge_x, phase_badge_y + phase_badge_h + scale(60), style.Colors.Text, style.Fonts.HUDTimer)

  local round_label = "Round #" .. tostring(BL.HUD.State.round_id or 0)
  draw_label(round_label, phase_badge_x + phase_badge_w + scale(16), phase_badge_y)

  if is_event_log_enabled() then
    local event_y = right_y + round_height + margin
    draw_card(right_x, event_y, right_width, event_height)

    draw_label("EVENT LOG", right_x + margin, event_y + margin)

    local start_y = event_y + margin + scale(22)
    local line_height = scale(20)
    local events = BL.HUD.State.event_entries or {}
    local total = #events
    for i = 1, total do
      local entry = events[i]
      local time_prefix = entry.time and entry.time ~= "" and (entry.time .. " ") or ""
      draw.SimpleText(time_prefix .. entry.text, style.Fonts.Body, right_x + margin, start_y + (i - 1) * line_height, entry.color or style.Colors.Text)
    end
  end
end

vgui.Register("BLHUD", PANEL, "DPanel")

function BL.HUD.Create()
  if IsValid(BL.HUD.Panel) then
    return
  end
  BL.HUD.Panel = vgui.Create("BLHUD")
end

hook.Add("InitPostEntity", "BL.HUD.Create", function()
  BL.HUD.Create()
end)

hook.Add("HUDShouldDraw", "BL.HUD.HideDefault", function(name)
  local hidden = {
    CHudHealth = true,
    CHudBattery = true,
    CHudAmmo = true,
    CHudSecondaryAmmo = true,
  }

  if hidden[name] then
    return false
  end
end)
