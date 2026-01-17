BL = BL or {}
BL.TTT2 = BL.TTT2 or {}
BL.TTT2.Net = BL.TTT2.Net or {}

BL.TTT2.Net.RateLimit = BL.TTT2.Net.RateLimit or {
  Default = 6,
  Interval = 1,
}

BL.TTT2.Net._rate_state = BL.TTT2.Net._rate_state or {}

local function get_rate_state(ply, message)
  local ply_state = BL.TTT2.Net._rate_state[ply]
  if not ply_state then
    ply_state = {}
    BL.TTT2.Net._rate_state[ply] = ply_state
  end
  local entry = ply_state[message]
  if not entry then
    entry = { count = 0, window_start = CurTime() }
    ply_state[message] = entry
  end
  return entry
end

function BL.TTT2.Net.IsRateLimited(ply, message, limit, interval)
  if not IsValid(ply) then
    return true
  end

  local max_count = limit or BL.TTT2.Net.RateLimit.Default
  local window = interval or BL.TTT2.Net.RateLimit.Interval
  local now = CurTime()
  local entry = get_rate_state(ply, message)

  if now - entry.window_start >= window then
    entry.window_start = now
    entry.count = 0
  end

  entry.count = entry.count + 1
  return entry.count > max_count
end

function BL.TTT2.Net.SendSnapshot(ply)
  if not IsValid(ply) then
    return
  end

  local snapshot = BL.TTT2.State and BL.TTT2.State.BuildSnapshot and BL.TTT2.State.BuildSnapshot(ply) or {}
  net.Start(BL.TTT2.Net.Messages.Snapshot)
  net.WriteTable(snapshot)
  net.Send(ply)
end

function BL.TTT2.Net.BroadcastSnapshots()
  if not BL.TTT2.State or not BL.TTT2.State.BuildSnapshot then
    return
  end

  for _, ply in ipairs(player.GetAll()) do
    if IsValid(ply) then
      local snapshot = BL.TTT2.State.BuildSnapshot(ply) or {}
      net.Start(BL.TTT2.Net.Messages.Snapshot)
      net.WriteTable(snapshot)
      net.Send(ply)
    end
  end
end

hook.Add("PlayerDisconnected", "BL.TTT2.Net.RateLimitCleanup", function(ply)
  BL.TTT2.Net._rate_state[ply] = nil
end)

for _, message in pairs(BL.TTT2.Net.Messages) do
  if type(message) == "string" then
    util.AddNetworkString(message)
  end
end

timer.Create("BL.TTT2.Net.BroadcastSnapshot", 1, 0, function()
  if GetRoundState and GetRoundState() == ROUND_ACTIVE then
    BL.TTT2.Net.BroadcastSnapshots()
    return
  end

  if CurTime() % 3 < 1 then
    BL.TTT2.Net.BroadcastSnapshots()
  end
end)
