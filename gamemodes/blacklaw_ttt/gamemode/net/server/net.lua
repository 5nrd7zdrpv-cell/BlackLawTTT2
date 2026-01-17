BL = BL or {}
BL.Net = BL.Net or {}

BL.Net.RateLimit = BL.Net.RateLimit or {
  Default = 10,
  Interval = 1,
}

BL.Net._rate_state = BL.Net._rate_state or {}

local function get_rate_state(ply, message)
  local ply_state = BL.Net._rate_state[ply]
  if not ply_state then
    ply_state = {}
    BL.Net._rate_state[ply] = ply_state
  end
  local entry = ply_state[message]
  if not entry then
    entry = { count = 0, window_start = CurTime() }
    ply_state[message] = entry
  end
  return entry
end

function BL.Net.IsRateLimited(ply, message, limit, interval)
  if not IsValid(ply) then
    return true
  end

  local max_count = limit or BL.Net.RateLimit.Default
  local window = interval or BL.Net.RateLimit.Interval
  local now = CurTime()
  local entry = get_rate_state(ply, message)

  if now - entry.window_start >= window then
    entry.window_start = now
    entry.count = 0
  end

  entry.count = entry.count + 1
  return entry.count > max_count
end

function BL.Net.Receive(message, opts, handler)
  if type(message) ~= "string" or message == "" then
    return
  end
  if type(handler) ~= "function" then
    return
  end

  net.Receive(message, function(len, ply)
    if not IsValid(ply) then
      return
    end

    local limit = opts and opts.limit or BL.Net.RateLimit.Default
    local interval = opts and opts.interval or BL.Net.RateLimit.Interval
    if BL.Net.IsRateLimited(ply, message, limit, interval) then
      return
    end

    handler(len, ply)
  end)
end

function BL.Net.SendSnapshot(ply)
  if not IsValid(ply) then
    return
  end

  local snapshot = BL.State and BL.State.GetSnapshot and BL.State.GetSnapshot(ply) or {}
  net.Start(BL.Net.Messages.Snapshot)
  net.WriteTable(snapshot)
  net.Send(ply)
end

function BL.Net.BroadcastSnapshot()
  local snapshot = BL.State and BL.State.GetSnapshot and BL.State.GetSnapshot(nil) or {}
  net.Start(BL.Net.Messages.Snapshot)
  net.WriteTable(snapshot)
  net.Broadcast()
end

function BL.Net.SendEvent(event)
  if type(event) ~= "table" then
    return
  end

  if type(event.type) ~= "string" or event.type == "" then
    return
  end

  local payload = {
    time = event.time or os.time(),
    type = event.type,
    payload = event.payload,
  }

  net.Start(BL.Net.Messages.Event)
  net.WriteTable(payload)
  net.Broadcast()
end

hook.Add("PlayerDisconnected", "BL.Net.RateLimitCleanup", function(ply)
  BL.Net._rate_state[ply] = nil
end)

for _, message in pairs(BL.Net.Messages) do
  if type(message) == "string" then
    util.AddNetworkString(message)
  end
end
