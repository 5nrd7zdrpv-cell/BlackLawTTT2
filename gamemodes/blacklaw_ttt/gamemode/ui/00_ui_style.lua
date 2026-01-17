BL = BL or {}
BL.UI = BL.UI or {}

BL.UI.Style = BL.UI.Style or {}

local function bl_ui_scale(value)
  local base_height = 1080
  local scale = math.max(ScrH() / base_height, 0.75)
  local ui_scale = 1
  if GM and GM.BLTTT and GM.BLTTT.GetConfigValue then
    local config_scale = GM.BLTTT.GetConfigValue("Client", "bl_ui_scale")
    if type(config_scale) == "number" then
      ui_scale = math.Clamp(config_scale, 0.5, 2)
    end
  end
  return math.floor(value * scale * ui_scale + 0.5)
end

BL.UI.bl_ui_scale = bl_ui_scale

function BL.UI.RefreshFonts()
  local font_scale = BL.UI.bl_ui_scale(1)
  if BL.UI.LastFontScale == font_scale then
    return
  end
  BL.UI.LastFontScale = font_scale

  local scale = BL.UI.bl_ui_scale
  surface.CreateFont("BL.UI.Title", {
    font = "Inter",
    size = scale(28),
    weight = 700,
    extended = true
  })

  surface.CreateFont("BL.UI.Heading", {
    font = "Inter",
    size = scale(20),
    weight = 600,
    extended = true
  })

  surface.CreateFont("BL.UI.Body", {
    font = "Inter",
    size = scale(16),
    weight = 500,
    extended = true
  })

  surface.CreateFont("BL.UI.Label", {
    font = "Inter",
    size = scale(12),
    weight = 600,
    extended = true
  })

  surface.CreateFont("BL.UI.Button", {
    font = "Inter",
    size = scale(15),
    weight = 600,
    extended = true
  })

  surface.CreateFont("BL.UI.HUDValue", {
    font = "Inter",
    size = scale(24),
    weight = 700,
    extended = true
  })

  surface.CreateFont("BL.UI.HUDLabel", {
    font = "Inter",
    size = scale(12),
    weight = 600,
    extended = true
  })

  surface.CreateFont("BL.UI.HUDTimer", {
    font = "Inter",
    size = scale(26),
    weight = 700,
    extended = true
  })
end

function BL.UI.RefreshStyle()
  local scale = BL.UI.bl_ui_scale

  BL.UI.Style.Spacing = {
    xs = scale(6),
    sm = scale(8),
    md = scale(12),
    lg = scale(16),
    xl = scale(24),
    xxl = scale(32)
  }

  BL.UI.Style.Radii = {
    sm = scale(8),
    md = scale(12),
    lg = scale(16),
    xl = scale(20)
  }

  BL.UI.Style.Fonts = {
    Title = "BL.UI.Title",
    Heading = "BL.UI.Heading",
    Body = "BL.UI.Body",
    Label = "BL.UI.Label",
    Button = "BL.UI.Button",
    HUDValue = "BL.UI.HUDValue",
    HUDLabel = "BL.UI.HUDLabel",
    HUDTimer = "BL.UI.HUDTimer"
  }

  BL.UI.Style.Colors = {
    Background = Color(13, 17, 23),
    Surface = Color(16, 22, 34, 220),
    SurfaceStrong = Color(27, 34, 48, 235),
    Border = Color(42, 50, 69, 255),
    CardBorder = Color(123, 166, 255, 38),
    Accent = Color(31, 111, 235),
    AccentHover = Color(45, 123, 255),
    Primary = Color(49, 176, 153),
    PrimaryHover = Color(54, 193, 170),
    Ghost = Color(16, 22, 34, 0),
    Text = Color(248, 249, 251),
    TextMuted = Color(154, 167, 189),
    Row = Color(123, 166, 255, 26),
    RowActive = Color(123, 166, 255, 51),
    Overlay = Color(8, 10, 15, 200),
    ToastInfo = Color(123, 166, 255, 35),
    ToastSuccess = Color(49, 176, 153, 35),
    ToastError = Color(255, 123, 123, 35)
  }
end

function BL.UI.Initialize()
  BL.UI.RefreshFonts()
  BL.UI.RefreshStyle()
end

hook.Add("OnScreenSizeChanged", "BL.UI.Rescale", function()
  BL.UI.Initialize()
end)

BL.UI.Initialize()
