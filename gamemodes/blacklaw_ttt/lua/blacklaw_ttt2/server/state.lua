BL = BL or {}
BL.TTT2 = BL.TTT2 or {}
BL.TTT2.State = BL.TTT2.State or {}

local MAX_EVENTS = 64

BL.TTT2.State.Data = BL.TTT2.State.Data or {
  phase = "LOBBY",
  round_id = 0,
  phase_end = nil,
  event_log = {},
}

local function push_event(event_type, payload)
  local log = BL.TTT2.State.Data.event_log
  log[#log + 1] = {
    time = os.time(),
    type = event_type,
    payload = payload or {},
  }
  if #log > MAX_EVENTS then
    table.remove(log, 1)
  end
end

local function update_phase(phase)
  local data = BL.TTT2.State.Data
  data.phase = phase
  local round_end = GetGlobalFloat("ttt_round_end", 0)
  if type(round_end) == "number" and round_end > 0 then
    data.phase_end = round_end
  else
    data.phase_end = nil
  end
  push_event("phase_" .. string.lower(phase))
end

local function get_role_data(ply)
  local role_id = 0
  if ply.GetSubRole then
    role_id = ply:GetSubRole()
  elseif ply.GetRole then
    role_id = ply:GetRole()
  end

  local role_tbl = roles and roles.GetByIndex and roles.GetByIndex(role_id) or nil
  local role_name = role_tbl and role_tbl.name or "Unbekannt"
  local role_key = role_tbl and (role_tbl.abbr or role_tbl.name or "") or ""

  if role_key == "" then
    role_key = tostring(role_id)
  end

  return role_id, role_key, role_name
end

local function should_reveal_role(viewer, target)
  if not IsValid(viewer) or not IsValid(target) then
    return false
  end
  if viewer == target then
    return true
  end
  if BL.TTT2.State.Data.phase == "POST" then
    return true
  end
  if target.GetNWBool and target:GetNWBool("ttt_role_revealed", false) then
    return true
  end
  if target.GetNWBool and target:GetNWBool("body_found", false) then
    return true
  end
  return false
end

local function build_players_summary(viewer)
  local summary = {}
  for _, ply in ipairs(player.GetAll()) do
    local reveal = should_reveal_role(viewer, ply)
    local role_id, role_key, role_name = 0, "UNKNOWN", "Unbekannt"
    if reveal then
      role_id, role_key, role_name = get_role_data(ply)
    end

    summary[#summary + 1] = {
      steamid64 = ply:SteamID64() or "",
      name = ply:Nick() or "Unbekannt",
      ping = math.max(0, math.floor(ply:Ping() or 0)),
      alive = ply:Alive() and true or false,
      role_id = role_id,
      role_key = role_key,
      role_name = role_name,
    }
  end
  return summary
end

function BL.TTT2.State.BuildSnapshot(viewer)
  if not IsValid(viewer) then
    return {}
  end

  local data = BL.TTT2.State.Data
  local role_id, role_key, role_name = get_role_data(viewer)
  local credits = 0
  if viewer.GetCredits then
    credits = viewer:GetCredits() or 0
  elseif viewer.GetNWInt then
    credits = viewer:GetNWInt("ttt_credits", 0)
  end

  return {
    phase = data.phase,
    round_id = data.round_id,
    phase_end = data.phase_end,
    self = {
      health = math.max(0, math.floor(viewer:Health() or 0)),
      armor = math.max(0, math.floor(viewer:Armor() or 0)),
      credits = math.max(0, math.floor(credits)),
      alive = viewer:Alive() and true or false,
      role_id = role_id,
      role_key = role_key,
      role_name = role_name,
    },
    players = build_players_summary(viewer),
    event_log = table.Copy(data.event_log),
  }
end

hook.Add("Initialize", "BL.TTT2.State.Initialize", function()
  BL.TTT2.State.Data.phase = "LOBBY"
  BL.TTT2.State.Data.round_id = 0
  BL.TTT2.State.Data.event_log = {}
  push_event("phase_lobby")
end)

hook.Add("TTTPrepareRound", "BL.TTT2.State.Prepare", function()
  update_phase("PREP")
end)

hook.Add("TTTBeginRound", "BL.TTT2.State.Begin", function()
  BL.TTT2.State.Data.round_id = BL.TTT2.State.Data.round_id + 1
  update_phase("ACTIVE")
end)

hook.Add("TTTEndRound", "BL.TTT2.State.End", function()
  update_phase("POST")
end)
