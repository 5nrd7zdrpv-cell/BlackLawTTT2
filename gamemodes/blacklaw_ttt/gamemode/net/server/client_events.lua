BL = BL or {}
BL.Net = BL.Net or {}

local function find_player_by_steamid64(steamid64)
  if type(steamid64) ~= "string" or steamid64 == "" then
    return nil
  end
  for _, ply in ipairs(player.GetAll()) do
    if IsValid(ply) and ply:SteamID64() == steamid64 then
      return ply
    end
  end
  return nil
end

BL.Net.Receive(BL.Net.Messages.ClientEvent, { limit = 5, interval = 1 }, function(_len, ply)
  local payload = net.ReadTable()
  if type(payload) ~= "table" then
    return
  end

  local event_type = payload.type
  if type(event_type) ~= "string" or event_type == "" then
    return
  end

  if event_type == "inspect_player" then
    if not BL.Perm or not BL.Perm.Has or not BL.Perm.Has(ply, "player.action") then
      return
    end

    local target_id = payload.steamid64
    local target = find_player_by_steamid64(target_id)
    if not IsValid(target) then
      return
    end

    if BL.Inspect and BL.Inspect.Request and BL.Inspect.Request(ply, target) then
      if BL.Net and BL.Net.SendSnapshot then
        BL.Net.SendSnapshot(ply)
      end
    end
  end
end)
