BL = BL or {}
BL.Net = BL.Net or {}

local function read_item_id()
  local raw = net.ReadString()
  if type(raw) ~= "string" then
    return nil
  end
  local trimmed = string.Trim(raw)
  if trimmed == "" then
    return nil
  end
  if #trimmed > 64 then
    return nil
  end
  return trimmed
end

BL.Net.Receive(BL.Net.Messages.ShopBuy, { limit = 4, interval = 1 }, function(_len, ply)
  local item_id = read_item_id()
  if not item_id then
    return
  end

  if not BL.Shop or not BL.Shop.TryPurchase then
    return
  end

  BL.Shop.TryPurchase(ply, item_id)
end)
