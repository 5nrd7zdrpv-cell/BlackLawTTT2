BL = BL or {}
BL.Net = BL.Net or {}

local function is_int(value)
  return type(value) == "number" and value == math.floor(value)
end

function BL.Net.IsSteamID64(value)
  return type(value) == "string" and value:match("^%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d$") ~= nil
end

function BL.Net.IsIntRange(value, min, max)
  if not is_int(value) then
    return false
  end
  if min ~= nil and value < min then
    return false
  end
  if max ~= nil and value > max then
    return false
  end
  return true
end

function BL.Net.IsNumberRange(value, min, max)
  if type(value) ~= "number" then
    return false
  end
  if min ~= nil and value < min then
    return false
  end
  if max ~= nil and value > max then
    return false
  end
  return true
end

function BL.Net.IsStringLen(value, min, max)
  if type(value) ~= "string" then
    return false
  end
  local len = #value
  if min ~= nil and len < min then
    return false
  end
  if max ~= nil and len > max then
    return false
  end
  return true
end

function BL.Net.IsBool(value)
  return type(value) == "boolean"
end

function BL.Net.IsTableLen(value, min, max)
  if type(value) ~= "table" then
    return false
  end
  local count = 0
  for _ in pairs(value) do
    count = count + 1
  end
  if min ~= nil and count < min then
    return false
  end
  if max ~= nil and count > max then
    return false
  end
  return true
end

function BL.Net.IsOneOf(value, allowed)
  if type(allowed) ~= "table" then
    return false
  end
  for _, entry in ipairs(allowed) do
    if value == entry then
      return true
    end
  end
  return false
end
