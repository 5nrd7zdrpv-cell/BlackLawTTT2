BL = BL or {}
BL.Inspect = BL.Inspect or {}

BL.Inspect.Active = BL.Inspect.Active or {}

local INSPECT_DURATION = 20

local function get_id(ply)
  if not IsValid(ply) then
    return nil
  end
  local steamid64 = ply:SteamID64()
  if type(steamid64) ~= "string" or steamid64 == "" then
    return nil
  end
  return steamid64
end

function BL.Inspect.Request(viewer, target)
  if not IsValid(viewer) or not IsValid(target) then
    return false
  end
  if not viewer:IsAdmin() then
    return false
  end

  local viewer_id = get_id(viewer)
  local target_id = get_id(target)
  if not viewer_id or not target_id then
    return false
  end

  local per_viewer = BL.Inspect.Active[viewer_id]
  if not per_viewer then
    per_viewer = {}
    BL.Inspect.Active[viewer_id] = per_viewer
  end

  per_viewer[target_id] = CurTime() + INSPECT_DURATION
  return true
end

function BL.Inspect.CanReveal(viewer, target)
  local viewer_id = get_id(viewer)
  local target_id = get_id(target)
  if not viewer_id or not target_id then
    return false
  end

  local per_viewer = BL.Inspect.Active[viewer_id]
  if not per_viewer then
    return false
  end

  local expires_at = per_viewer[target_id]
  if not expires_at then
    return false
  end

  if expires_at < CurTime() then
    per_viewer[target_id] = nil
    return false
  end

  return true
end

function BL.Inspect.ClearViewer(viewer)
  local viewer_id = get_id(viewer)
  if not viewer_id then
    return
  end
  BL.Inspect.Active[viewer_id] = nil
end

hook.Add("PlayerDisconnected", "BL.Inspect.PlayerDisconnected", function(ply)
  BL.Inspect.ClearViewer(ply)
end)
