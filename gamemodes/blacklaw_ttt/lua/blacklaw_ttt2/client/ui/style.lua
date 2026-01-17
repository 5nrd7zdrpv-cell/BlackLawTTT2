BL = BL or {}
BL.UI = BL.UI or {}
BL.UI.Style = BL.UI.Style or {}

local function bl_ui_scale(value)
  local base_height = 1080
  local scale = math.max(ScrH() / base_height, 0.75)
  return math.floor(value * scale + 0.5)
end

BL.UI.Scale = bl_ui_scale

function BL.UI.RefreshFonts()
  local scale = BL.UI.Scale
  surface.CreateFont("BL.UI.Title", {
    font = "Inter",
    size = scale(28),
    weight = 700,
    extended = true,
  })

  surface.CreateFont("BL.UI.Heading", {
    font = "Inter",
    size = scale(18),
    weight = 600,
    extended = true,
  })

  surface.CreateFont("BL.UI.Body", {
    font = "Inter",
    size = scale(15),
    weight = 500,
    extended = true,
  })

  surface.CreateFont("BL.UI.Label", {
    font = "Inter",
    size = scale(12),
    weight = 600,
    extended = true,
  })

  surface.CreateFont("BL.UI.Value", {
    font = "Inter",
    size = scale(22),
    weight = 700,
    extended = true,
  })
end

function BL.UI.RefreshStyle()
  local scale = BL.UI.Scale

  BL.UI.Style.Spacing = {
    xs = scale(6),
    sm = scale(8),
    md = scale(12),
    lg = scale(16),
    xl = scale(24),
  }

  BL.UI.Style.Radii = {
    sm = scale(8),
    md = scale(12),
    lg = scale(16),
  }

  BL.UI.Style.Fonts = {
    Title = "BL.UI.Title",
    Heading = "BL.UI.Heading",
    Body = "BL.UI.Body",
    Label = "BL.UI.Label",
    Value = "BL.UI.Value",
  }

  BL.UI.Style.Colors = {
    Background = Color(13, 17, 23),
    Surface = Color(16, 22, 34, 230),
    Border = Color(42, 50, 69, 255),
    CardBorder = Color(123, 166, 255, 38),
    Accent = Color(31, 111, 235),
    Primary = Color(49, 176, 153),
    Text = Color(248, 249, 251),
    TextMuted = Color(154, 167, 189),
    Alert = Color(255, 123, 123),
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
