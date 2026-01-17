BL = BL or {}
BL.TTT2 = BL.TTT2 or {}
BL.TTT2.Validation = BL.TTT2.Validation or {}

local function is_int(value)
  return type(value) == "number" and value == math.floor(value)
end

function BL.TTT2.Validation.IsIntRange(value, min, max)
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

function BL.TTT2.Validation.IsNumberRange(value, min, max)
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

function BL.TTT2.Validation.IsStringLen(value, min, max)
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

function BL.TTT2.Validation.IsBool(value)
  return type(value) == "boolean"
end

function BL.TTT2.Validation.IsTableLen(value, min, max)
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
