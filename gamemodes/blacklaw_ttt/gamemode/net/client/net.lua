BL = BL or {}
BL.Net = BL.Net or {}

local MAX_EVENTS = 200

BL.Net.Cache = BL.Net.Cache or {
  snapshot = nil,
  events = {},
  last_snapshot_at = 0,
  last_event_at = 0,
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
  local snapshot = net.ReadTable()
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

function BL.Net.GetSnapshot()
  return BL.Net.Cache.snapshot
end

function BL.Net.GetEvents()
  return BL.Net.Cache.events
end
