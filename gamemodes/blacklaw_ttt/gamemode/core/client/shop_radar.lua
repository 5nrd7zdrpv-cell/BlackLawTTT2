BL = BL or {}
BL.Shop = BL.Shop or {}
BL.Shop.Radar = BL.Shop.Radar or {
  pings = {},
  duration = 4,
}

local function get_style()
  return BL.UI and BL.UI.Style or {}
end

net.Receive(BL.Net.Messages.ShopRadarPing, function()
  local count = net.ReadUInt(6)
  if count > 32 then
    return
  end

  local now = CurTime()
  local pings = {}
  for _ = 1, count do
    local pos = net.ReadVector()
    local name = net.ReadString()
    if isvector(pos) and type(name) == "string" then
      pings[#pings + 1] = {
        pos = pos,
        name = name,
        time = now,
      }
    end
  end

  BL.Shop.Radar.pings = pings
end)

hook.Add("HUDPaint", "BL.Shop.RadarHUD", function()
  local radar = BL.Shop.Radar
  if not radar then
    return
  end

  local style = get_style()
  local now = CurTime()
  local pings = radar.pings or {}
  local display = {}

  for _, ping in ipairs(pings) do
    if now - (ping.time or 0) <= radar.duration then
      display[#display + 1] = ping
    end
  end

  if #display == 0 then
    return
  end

  local title = "Radar-Ping"
  local base_x = ScrW() - 260
  local base_y = 120
  local box_w = 220
  local box_h = 28 + (#display * 18)

  surface.SetDrawColor(style.Colors and style.Colors.Surface or Color(20, 24, 34, 220))
  surface.DrawRect(base_x, base_y, box_w, box_h)

  draw.SimpleText(title, "BL.UI.Title", base_x + 12, base_y + 6, style.Colors and style.Colors.Text or color_white)

  local offset_y = base_y + 26
  for _, ping in ipairs(display) do
    local screen = ping.pos:ToScreen()
    local distance = "?"
    if screen and screen.visible then
      distance = tostring(math.floor(LocalPlayer():GetPos():Distance(ping.pos))) .. "u"
    end
    local text = string.format("%s (%s)", ping.name, distance)
    draw.SimpleText(text, "BL.UI.Body", base_x + 12, offset_y, style.Colors and style.Colors.TextMuted or color_white)
    offset_y = offset_y + 18
  end
end)
