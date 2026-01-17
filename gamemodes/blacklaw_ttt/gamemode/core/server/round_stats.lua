BL = BL or {}
BL.RoundStats = BL.RoundStats or {}

local function reset_player_stats(ply)
  if not IsValid(ply) then
    return
  end
  ply.BLTTT_RoundKills = 0
  ply.BLTTT_RoundDeaths = 0
end

function BL.RoundStats.Reset(ply)
  reset_player_stats(ply)
end

function BL.RoundStats.ResetAll()
  for _, ply in ipairs(player.GetAll()) do
    reset_player_stats(ply)
  end
end

function BL.RoundStats.AddKill(ply)
  if not IsValid(ply) or not ply:IsPlayer() then
    return
  end
  ply.BLTTT_RoundKills = math.max(0, math.floor(tonumber(ply.BLTTT_RoundKills) or 0)) + 1
end

function BL.RoundStats.AddDeath(ply)
  if not IsValid(ply) then
    return
  end
  ply.BLTTT_RoundDeaths = math.max(0, math.floor(tonumber(ply.BLTTT_RoundDeaths) or 0)) + 1
end

hook.Add("PlayerInitialSpawn", "BL.RoundStats.PlayerInitialSpawn", function(ply)
  reset_player_stats(ply)
end)

hook.Add("PlayerDeath", "BL.RoundStats.PlayerDeath", function(victim, _inflictor, attacker)
  local phase = BL.State and BL.State.Data and BL.State.Data.phase or "LOBBY"
  if phase ~= "ACTIVE" then
    return
  end

  if IsValid(attacker) and attacker:IsPlayer() and attacker ~= victim then
    BL.RoundStats.AddKill(attacker)
  end

  if IsValid(victim) then
    BL.RoundStats.AddDeath(victim)
  end
end)
