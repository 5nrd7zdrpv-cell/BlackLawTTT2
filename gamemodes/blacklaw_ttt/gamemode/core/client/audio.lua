BL = BL or {}
BL.Audio = BL.Audio or {}

BL.Audio.Cues = BL.Audio.Cues or {
  round_start = {
    "ui/buttonclickrelease.wav",
    "buttons/button15.wav",
    "buttons/button14.wav",
  },
  role_reveal_end = {
    "ui/buttonclick.wav",
    "buttons/button9.wav",
    "buttons/button8.wav",
  },
}

BL.Audio.Resolved = BL.Audio.Resolved or {}

local function is_sound_available(path)
  if type(path) ~= "string" or path == "" then
    return false
  end
  return file.Exists("sound/" .. path, "GAME")
end

function BL.Audio.ResolveCue(cue)
  if BL.Audio.Resolved[cue] ~= nil then
    return BL.Audio.Resolved[cue]
  end

  local list = BL.Audio.Cues[cue]
  if type(list) ~= "table" then
    BL.Audio.Resolved[cue] = nil
    return nil
  end

  for _, candidate in ipairs(list) do
    if is_sound_available(candidate) then
      BL.Audio.Resolved[cue] = candidate
      return candidate
    end
  end

  BL.Audio.Resolved[cue] = nil
  return nil
end

function BL.Audio.PlayCue(cue)
  local resolved = BL.Audio.ResolveCue(cue)
  if not resolved then
    return
  end
  surface.PlaySound(resolved)
end
