BL = BL or {}
BL.Net = BL.Net or {}

local MAX_EVENTS = 200

BL.Net.Cache = BL.Net.Cache or {
  snapshot = nil,
  events = {},
  last_snapshot_at = 0,
  last_event_at = 0,
}

BL.Net.AdminCache = BL.Net.AdminCache or {
  snapshot = nil,
  last_snapshot_at = 0,
}

local function push_event(event)
  if type(event) ~= "table" then
    return
  end

  local events = BL.Net.Cache.events
  events[#events + 1] = event
  if #events > MAX_EVENTS then
    table.remove(events, 1)
  end
  BL.Net.Cache.last_event_at = CurTime()
end

net.Receive(BL.Net.Messages.Snapshot, function()
  local snapshot = BL.Net.ReadCompressedTable and BL.Net.ReadCompressedTable() or net.ReadTable()
  if type(snapshot) ~= "table" then
    return
  end

  BL.Net.Cache.snapshot = snapshot
  BL.Net.Cache.last_snapshot_at = CurTime()
end)

net.Receive(BL.Net.Messages.Event, function()
  local event = net.ReadTable()
  push_event(event)
end)

net.Receive(BL.Net.Messages.AdminSnapshot, function()
  local payload = BL.Net.ReadCompressedTable and BL.Net.ReadCompressedTable() or net.ReadTable()
  if type(payload) ~= "table" then
    return
  end

  BL.Net.AdminCache.snapshot = payload
  BL.Net.AdminCache.last_snapshot_at = CurTime()

  if BL.AdminUI and BL.AdminUI.ApplySnapshot then
    BL.AdminUI.ApplySnapshot(payload)
  end
end)

local function sanitize_notice_string(value, max_len)
  if type(value) ~= "string" then
    return ""
  end
  local trimmed = string.Trim(value)
  if max_len and #trimmed > max_len then
    return string.sub(trimmed, 1, max_len)
  end
  return trimmed
end

local function handle_shop_notice(payload)
  local success = payload.success == true
  local item_name = sanitize_notice_string(payload.item_name, 80)
  local reason = sanitize_notice_string(payload.reason, 48)

  local message = ""
  if success then
    if item_name ~= "" then
      message = "Kauf erfolgreich: " .. item_name
    else
      message = "Kauf erfolgreich"
    end
  else
    if reason == "no_credits" then
      message = "Kauf fehlgeschlagen: zu wenig Credits"
    elseif reason == "limit_reached" then
      message = "Kauf fehlgeschlagen: Limit erreicht"
    elseif reason == "role_restricted" then
      message = "Kauf fehlgeschlagen: Rolle gesperrt"
    elseif reason == "phase_locked" then
      message = "Kauf fehlgeschlagen: Phase gesperrt"
    elseif reason == "dead" then
      message = "Kauf fehlgeschlagen: du bist tot"
    else
      message = "Kauf fehlgeschlagen"
    end
    if item_name ~= "" then
      message = message .. " (" .. item_name .. ")"
    end
  end

  if BL.UI and BL.UI.Toast and BL.UI.Toast.Show then
    BL.UI.Toast.Show(message, success and "success" or "error", 4)
    return
  end

  BL.UI = BL.UI or {}
  BL.UI.Toast = BL.UI.Toast or {}
  BL.UI.Toast.Pending = BL.UI.Toast.Pending or {}
  BL.UI.Toast.Pending[#BL.UI.Toast.Pending + 1] = {
    message = message,
    kind = success and "success" or "error",
    duration = 4,
  }
end

net.Receive(BL.Net.Messages.Notice, function()
  local payload = net.ReadTable()
  if type(payload) ~= "table" then
    return
  end

  local notice_type = payload.type
  if notice_type == "shop_purchase" then
    handle_shop_notice(payload)
  end
end)

function BL.Net.GetSnapshot()
  return BL.Net.Cache.snapshot
end

function BL.Net.GetEvents()
  return BL.Net.Cache.events
end

function BL.Net.GetAdminSnapshot()
  return BL.Net.AdminCache.snapshot
end
