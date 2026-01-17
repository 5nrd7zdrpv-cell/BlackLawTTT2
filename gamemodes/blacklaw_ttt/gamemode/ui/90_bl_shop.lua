BL = BL or {}
BL.UI = BL.UI or {}
BL.ShopUI = BL.ShopUI or {}

local TEXT_ALIGN_CENTER = TEXT_ALIGN_CENTER or 1

local function get_style()
  return BL.UI and BL.UI.Style or {}
end

local function apply_scroll_style(scroll)
  if not IsValid(scroll) then
    return
  end
  local style = get_style()
  local bar = scroll:GetVBar()
  if not IsValid(bar) then
    return
  end
  bar:SetWide(BL.UI.bl_ui_scale(6))
  bar.Paint = function(_, w, h)
    draw.RoundedBox(style.Radii.md, 0, 0, w, h, style.Colors.SurfaceStrong)
  end
  bar.btnGrip.Paint = function(_, w, h)
    draw.RoundedBox(style.Radii.md, 0, 0, w, h, style.Colors.CardBorder)
  end
  bar.btnUp.Paint = function() end
  bar.btnDown.Paint = function() end
end

local function status_text(status)
  if status == "role_restricted" then
    return "Rolle gesperrt"
  elseif status == "limit_reached" then
    return "Limit erreicht"
  elseif status == "no_credits" then
    return "Nicht genug Credits"
  end
  return "Verfügbar"
end

local function status_color(status)
  local style = get_style()
  if status == "role_restricted" then
    return style.Colors.ToastError or color_white
  elseif status == "limit_reached" then
    return style.Colors.ToastInfo or color_white
  elseif status == "no_credits" then
    return style.Colors.TextMuted or color_white
  end
  return style.Colors.Primary or color_white
end

local function format_limits(item)
  if type(item) ~= "table" then
    return ""
  end
  local parts = {}
  if (item.per_round_limit or 0) > 0 then
    parts[#parts + 1] = string.format("Runde %d/%d", item.round_count or 0, item.per_round_limit)
  end
  if (item.per_player_limit or 0) > 0 then
    parts[#parts + 1] = string.format("Du %d/%d", item.player_count or 0, item.per_player_limit)
  end
  return table.concat(parts, " • ")
end

local BUY_BUTTON = {}

function BUY_BUTTON:Init()
  self.IsDisabled = false
  self:SetVariant("primary")
end

function BUY_BUTTON:SetDisabledState(is_disabled)
  self.IsDisabled = is_disabled and true or false
  self:SetEnabled(not self.IsDisabled)
  self:SetCursor(self.IsDisabled and "arrow" or "hand")
end

function BUY_BUTTON:Paint(w, h)
  if not self.IsDisabled then
    return self.BaseClass.Paint(self, w, h)
  end

  local style = get_style()
  draw.RoundedBox(style.Radii.md, 0, 0, w, h, style.Colors.SurfaceStrong)
  surface.SetDrawColor(style.Colors.Border)
  surface.DrawOutlinedRect(0, 0, w, h, 1)
  self:SetTextColor(style.Colors.TextMuted)
  return true
end

vgui.Register("BLShopBuyButton", BUY_BUTTON, "BLButton")

local ITEM_CARD = {}

function ITEM_CARD:Init()
  local style = get_style()
  self.Item = nil
  self.Padding = style.Spacing.lg
  self:SetTall(BL.UI.bl_ui_scale(124))

  self.BuyButton = vgui.Create("BLShopBuyButton", self)
  self.BuyButton:SetText("Kaufen")
  self.BuyButton.DoClick = function()
    if not self.Item or not self.Item.id then
      return
    end
    if self.Item.status ~= "ok" then
      return
    end
    if not BL.Net or not BL.Net.Messages or not BL.Net.Messages.ShopBuy then
      return
    end
    net.Start(BL.Net.Messages.ShopBuy)
    net.WriteString(self.Item.id)
    net.SendToServer()
  end
end

function ITEM_CARD:SetItem(item)
  self.Item = item
  if not IsValid(self.BuyButton) then
    return
  end

  local status = item and item.status or "ok"
  if status == "role_restricted" then
    self.BuyButton:SetText("Gesperrt")
  elseif status == "limit_reached" then
    self.BuyButton:SetText("Limit")
  elseif status == "no_credits" then
    self.BuyButton:SetText("Zu teuer")
  else
    self.BuyButton:SetText("Kaufen")
  end

  self.BuyButton:SetDisabledState(status ~= "ok")
end

function ITEM_CARD:PerformLayout(w, h)
  local padding = self.Padding
  if not IsValid(self.BuyButton) then
    return
  end
  local button_w = BL.UI.bl_ui_scale(128)
  local button_h = BL.UI.bl_ui_scale(36)
  self.BuyButton:SetSize(button_w, button_h)
  self.BuyButton:SetPos(w - padding - button_w, h - padding - button_h)
end

function ITEM_CARD:Paint(w, h)
  local style = get_style()
  local item = self.Item or {}
  local is_hovered = self:IsHovered()
  local background = is_hovered and style.Colors.RowActive or style.Colors.Row

  draw.RoundedBox(style.Radii.lg, 0, 0, w, h, background)
  surface.SetDrawColor(style.Colors.CardBorder)
  surface.DrawOutlinedRect(0, 0, w, h, 1)

  local padding = self.Padding
  local name = item.name or "Unbekanntes Item"
  local price = tonumber(item.price or 0) or 0
  local price_text = string.format("%d Credits", math.max(price, 0))
  local status = item.status or "ok"
  local status_label = status_text(status)
  local limit_text = format_limits(item)

  draw.SimpleText(name, style.Fonts.Heading, padding, padding, style.Colors.Text)
  draw.SimpleText(status_label, style.Fonts.Label, padding, padding + BL.UI.bl_ui_scale(26), status_color(status))

  if limit_text ~= "" then
    draw.SimpleText(limit_text, style.Fonts.Label, padding, padding + BL.UI.bl_ui_scale(44), style.Colors.TextMuted)
  end

  surface.SetFont(style.Fonts.Label)
  local text_w, text_h = surface.GetTextSize(price_text)
  local badge_padding_x = BL.UI.bl_ui_scale(10)
  local badge_padding_y = BL.UI.bl_ui_scale(6)
  local badge_w = text_w + badge_padding_x * 2
  local badge_h = text_h + badge_padding_y * 2
  local badge_x = w - padding - badge_w
  local badge_y = padding

  draw.RoundedBox(style.Radii.md, badge_x, badge_y, badge_w, badge_h, style.Colors.Accent)
  draw.SimpleText(price_text, style.Fonts.Label, badge_x + badge_padding_x, badge_y + badge_padding_y, style.Colors.Text)
end

vgui.Register("BLShopItemCard", ITEM_CARD, "DPanel")

local SHOP_FRAME = {}

function SHOP_FRAME:Init()
  local style = get_style()
  self.Items = {}
  self.SearchQuery = ""

  self.Card = vgui.Create("BLCard", self)
  self.Card:SetTitle("")
  self.Card:SetSubtitle("")

  self.Header = vgui.Create("DPanel", self.Card)
  self.Header:SetTall(BL.UI.bl_ui_scale(80))
  self.Header:SetPaintBackground(false)
  self.Header.Paint = function(_, w, h)
    local current_style = get_style()
    draw.SimpleText("Shop", current_style.Fonts.Title, current_style.Spacing.lg, current_style.Spacing.sm, current_style.Colors.Text)
    draw.SimpleText("Ausrüstung & Upgrades", current_style.Fonts.Body, current_style.Spacing.lg, current_style.Spacing.sm + BL.UI.bl_ui_scale(28), current_style.Colors.TextMuted)
  end

  self.CreditsBadge = vgui.Create("DPanel", self.Header)
  self.CreditsBadge:SetTall(BL.UI.bl_ui_scale(36))
  self.CreditsValue = 0
  self.CreditsBadge.Paint = function(_, w, h)
    local current_style = get_style()
    local colors = current_style.Colors
    draw.RoundedBox(current_style.Radii.md, 0, 0, w, h, colors.SurfaceStrong)
    surface.SetDrawColor(colors.Border)
    surface.DrawOutlinedRect(0, 0, w, h, 1)
    draw.SimpleText(string.format("%d Credits", self.CreditsValue or 0), current_style.Fonts.Label, w * 0.5, h * 0.5, colors.Text, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
  end

  self.CloseButton = vgui.Create("BLButton", self.Header)
  self.CloseButton:SetVariant("ghost")
  self.CloseButton:SetText("Schließen")
  self.CloseButton:SetTall(BL.UI.bl_ui_scale(32))
  self.CloseButton.DoClick = function()
    if self.OnRequestClose then
      self:OnRequestClose()
    end
  end

  self.Toolbar = vgui.Create("DPanel", self.Card)
  self.Toolbar:SetTall(BL.UI.bl_ui_scale(44))
  self.Toolbar:SetPaintBackground(false)

  self.SearchEntry = vgui.Create("DTextEntry", self.Toolbar)
  self.SearchEntry:SetFont(style.Fonts.Body)
  self.SearchEntry:SetTextColor(style.Colors.Text)
  self.SearchEntry:SetPlaceholderText("Item suchen")
  self.SearchEntry:SetUpdateOnType(true)
  self.SearchEntry:SetDrawBackground(false)
  self.SearchEntry:SetDrawBorder(false)
  self.SearchEntry.OnValueChange = function(_, value)
    self.SearchQuery = value or ""
    self:RefreshItems()
  end
  self.SearchEntry.Paint = function(entry, w, h)
    local current_style = get_style()
    local colors = current_style.Colors
    draw.RoundedBox(current_style.Radii.md, 0, 0, w, h, colors.SurfaceStrong)
    surface.SetDrawColor(colors.Border)
    surface.DrawOutlinedRect(0, 0, w, h, 1)
    entry:DrawTextEntryText(colors.Text, colors.Primary, colors.TextMuted)
  end

  self.Scroll = vgui.Create("DScrollPanel", self.Card)
  apply_scroll_style(self.Scroll)

  self.List = vgui.Create("DIconLayout", self.Scroll)
  self.List:Dock(FILL)
  self.List:SetSpaceY(style.Spacing.md)

  self.EmptyLabel = vgui.Create("DLabel", self.Card)
  self.EmptyLabel:SetFont(style.Fonts.Body)
  self.EmptyLabel:SetTextColor(style.Colors.TextMuted)
  self.EmptyLabel:SetText("Keine Items verfügbar.")
  self.EmptyLabel:SetVisible(false)
end

function SHOP_FRAME:SetCredits(credits)
  self.CreditsValue = math.max(0, math.floor(tonumber(credits) or 0))
end

function SHOP_FRAME:SetItems(items)
  self.Items = items or {}
  self:RefreshItems()
end

function SHOP_FRAME:RefreshItems()
  if not IsValid(self.List) then
    return
  end

  self.List:Clear()
  local query = string.Trim(string.lower(self.SearchQuery or ""))
  local visible = 0

  for _, item in ipairs(self.Items) do
    local name = string.lower(tostring(item.name or ""))
    local id = string.lower(tostring(item.id or ""))
    if query == "" or string.find(name, query, 1, true) or string.find(id, query, 1, true) then
      local card = self.List:Add("BLShopItemCard")
      card:SetWide(self.List:GetWide())
      card:SetItem(item)
      visible = visible + 1
    end
  end

  if IsValid(self.EmptyLabel) then
    self.EmptyLabel:SetVisible(visible == 0)
  end
end

function SHOP_FRAME:PerformLayout(w, h)
  local style = get_style()
  local credits_text = string.format("%d Credits", self.CreditsValue or 0)

  surface.SetFont(style.Fonts.Label)
  local text_w, text_h = surface.GetTextSize(credits_text)
  local badge_padding_x = BL.UI.bl_ui_scale(12)
  local badge_padding_y = BL.UI.bl_ui_scale(8)
  local badge_w = text_w + badge_padding_x * 2
  local badge_h = text_h + badge_padding_y * 2

  if IsValid(self.Card) then
    self.Card:SetSize(w, h)
    self.Card:Dock(FILL)
  end

  if IsValid(self.Header) then
    self.Header:Dock(TOP)
    self.Header:DockMargin(0, 0, 0, style.Spacing.sm)
  end

  if IsValid(self.Toolbar) then
    self.Toolbar:Dock(TOP)
    self.Toolbar:DockMargin(0, 0, 0, style.Spacing.md)
  end

  if IsValid(self.Scroll) then
    self.Scroll:Dock(FILL)
    self.Scroll:DockMargin(0, 0, 0, 0)
  end

  if IsValid(self.SearchEntry) then
    self.SearchEntry:Dock(FILL)
  end

  if IsValid(self.CloseButton) then
    self.CloseButton:Dock(RIGHT)
    self.CloseButton:SizeToContents()
    self.CloseButton:SetTall(BL.UI.bl_ui_scale(32))
  end

  if IsValid(self.CreditsBadge) then
    self.CreditsBadge:Dock(RIGHT)
    self.CreditsBadge:DockMargin(0, 0, style.Spacing.sm, 0)
    self.CreditsBadge:SetSize(badge_w, badge_h)
  end

  if IsValid(self.EmptyLabel) then
    self.EmptyLabel:Dock(TOP)
    self.EmptyLabel:DockMargin(0, style.Spacing.sm, 0, 0)
    self.EmptyLabel:SizeToContents()
  end

  if IsValid(self.List) then
    self.List:SetWide(self.Scroll:GetWide())
    for _, child in ipairs(self.List:GetChildren()) do
      child:SetWide(self.List:GetWide())
    end
  end
end

function SHOP_FRAME:OnRequestClose() end

vgui.Register("BLShopFrame", SHOP_FRAME, "DPanel")

local SHOP_ROOT = {}

function SHOP_ROOT:Init()
  self:SetSize(ScrW(), ScrH())
  self:SetPos(0, 0)
  self:SetAlpha(255)
  self:MakePopup()
  self:SetKeyboardInputEnabled(true)
  self:SetMouseInputEnabled(true)

  self.Progress = 0
  self.Target = 1
  self.AnimSpeed = 6

  self.Frame = vgui.Create("BLShopFrame", self)
  self.Frame.OnRequestClose = function()
    self:Close()
  end

  self.LastSnapshotAt = 0
  self:UpdateFromSnapshot()
end

function SHOP_ROOT:UpdateFromSnapshot()
  if not IsValid(self.Frame) then
    return
  end
  local snapshot = BL.Net and BL.Net.GetSnapshot and BL.Net.GetSnapshot() or nil
  local shop = snapshot and snapshot.shop or nil
  if type(shop) ~= "table" then
    self.Frame:SetCredits(0)
    self.Frame:SetItems({})
    return
  end
  self.Frame:SetCredits(shop.credits or snapshot.credits or 0)
  self.Frame:SetItems(shop.items or {})
end

function SHOP_ROOT:Close()
  self.Target = 0
end

function SHOP_ROOT:Think()
  if self:GetWide() ~= ScrW() or self:GetTall() ~= ScrH() then
    self:SetSize(ScrW(), ScrH())
  end

  local last_snapshot = BL.Net and BL.Net.Cache and BL.Net.Cache.last_snapshot_at or 0
  if last_snapshot > self.LastSnapshotAt then
    self.LastSnapshotAt = last_snapshot
    self:UpdateFromSnapshot()
  end

  local delta = FrameTime() * self.AnimSpeed
  self.Progress = math.Approach(self.Progress, self.Target, delta)

  if self.Target == 0 and self.Progress <= 0.01 then
    self:Remove()
    return
  end

  if IsValid(self.Frame) then
    local card_w = BL.UI.bl_ui_scale(980)
    local card_h = BL.UI.bl_ui_scale(720)
    local x = (self:GetWide() - card_w) * 0.5
    local y = (self:GetTall() - card_h) * 0.5 + (1 - self.Progress) * BL.UI.bl_ui_scale(30)
    self.Frame:SetSize(card_w, card_h)
    self.Frame:SetPos(x, y)
    self.Frame:SetAlpha(math.floor(255 * self.Progress))
  end
end

function SHOP_ROOT:OnMousePressed()
  if not IsValid(self.Frame) then
    return
  end
  local x, y = self:CursorPos()
  local fx, fy = self.Frame:GetPos()
  local fw, fh = self.Frame:GetSize()
  if x < fx or x > fx + fw or y < fy or y > fy + fh then
    self:Close()
  end
end

function SHOP_ROOT:Paint(w, h)
  local style = get_style()
  local overlay = style.Colors.Overlay or Color(0, 0, 0, 200)
  local alpha = math.floor((overlay.a or 200) * self.Progress)
  draw.RoundedBox(0, 0, 0, w, h, Color(overlay.r, overlay.g, overlay.b, alpha))
end

function SHOP_ROOT:OnRemove()
  if BL.ShopUI and BL.ShopUI.Root == self then
    BL.ShopUI.Root = nil
  end
end

vgui.Register("BLShopRoot", SHOP_ROOT, "DPanel")

function BL.ShopUI.Open()
  if IsValid(BL.ShopUI.Root) then
    return
  end
  BL.ShopUI.Root = vgui.Create("BLShopRoot")
end

function BL.ShopUI.Close()
  if IsValid(BL.ShopUI.Root) then
    BL.ShopUI.Root:Close()
  end
end

function BL.ShopUI.Toggle()
  if IsValid(BL.ShopUI.Root) then
    BL.ShopUI.Root:Close()
    return
  end
  BL.ShopUI.Open()
end

concommand.Add("bl_shop", function()
  BL.ShopUI.Toggle()
end)

hook.Add("ShowSpare1", "BL.ShopUI.Toggle", function()
  BL.ShopUI.Toggle()
  return false
end)
