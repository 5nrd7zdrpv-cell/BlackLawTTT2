BL = BL or {}
BL.Net = BL.Net or {}

local function find_player_by_steamid64(steamid64)
  if BL.Net and BL.Net.IsSteamID64 and not BL.Net.IsSteamID64(steamid64) then
    return nil
  end
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

local function is_valid_event_type(value)
  return value == "request_snapshot"
    or value == "inspect_player"
    or value == "message_player"
end

local function sanitize_message(value)
  if type(value) ~= "string" then
    return ""
  end
  local trimmed = string.Trim(value)
  if trimmed == "" then
    return ""
  end
  if #trimmed > 200 then
    trimmed = string.sub(trimmed, 1, 200)
  end
  return trimmed
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
  if not is_valid_event_type(event_type) then
    return
  end

  if event_type == "request_snapshot" then
    if BL.Net and BL.Net.SendSnapshot then
      BL.Net.SendSnapshot(ply)
    end
  elseif event_type == "inspect_player" then
    if not BL.Perm or not BL.Perm.Has or not BL.Perm.Has(ply, "player.action") then
      return
    end

    local target_id = payload.steamid64
    if BL.Net and BL.Net.IsSteamID64 and not BL.Net.IsSteamID64(target_id) then
      return
    end
    local target = find_player_by_steamid64(target_id)
    if not IsValid(target) then
      return
    end

    if BL.Inspect and BL.Inspect.Request and BL.Inspect.Request(ply, target) then
      if BL.Net and BL.Net.SendSnapshot then
        BL.Net.SendSnapshot(ply)
      end
    end
    return
  end

  if event_type == "message_player" then
    if not BL.Perm or not BL.Perm.Has or not BL.Perm.Has(ply, "player.action") then
      return
    end

    local target_id = payload.steamid64
    if BL.Net and BL.Net.IsSteamID64 and not BL.Net.IsSteamID64(target_id) then
      return
    end
    local target = find_player_by_steamid64(target_id)
    if not IsValid(target) then
      return
    end

    local message = sanitize_message(payload.message)
    if message == "" then
      return
    end

    target:ChatPrint("[BLTTT] Nachricht von " .. ply:Nick() .. ": " .. message)
    ply:ChatPrint("[BLTTT] Nachricht an " .. target:Nick() .. ": " .. message)
  end
end)
