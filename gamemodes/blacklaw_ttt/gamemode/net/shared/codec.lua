BL = BL or {}
BL.Net = BL.Net or {}

local MAX_COMPRESSED_BYTES = 2 * 1024 * 1024

function BL.Net.WriteCompressedTable(payload)
  if type(payload) ~= "table" then
    payload = {}
  end

  local json = util.TableToJSON(payload, false) or ""
  local compressed = util.Compress(json) or ""
  local length = #compressed

  if length > MAX_COMPRESSED_BYTES then
    compressed = ""
    length = 0
  end

  net.WriteUInt(length, 32)
  if length > 0 then
    net.WriteData(compressed, length)
  end
end

function BL.Net.ReadCompressedTable()
  local length = net.ReadUInt(32)
  if not length or length <= 0 then
    return {}
  end
  if length > MAX_COMPRESSED_BYTES then
    return {}
  end

  local data = net.ReadData(length)
  if not data then
    return {}
  end

  local json = util.Decompress(data)
  if not json or json == "" then
    return {}
  end

  local payload = util.JSONToTable(json)
  if type(payload) ~= "table" then
    return {}
  end

  return payload
end
