local function blt_boot_log(message)
  if GM and GM.BLTTT_BootLog then
    GM:BLTTT_BootLog(message)
    return
  end
  MsgC(Color(80, 200, 255), "[BLACKLAW_TTT] ", color_white, message .. "\n")
end

if not SERVER then
  return
end

GM.BLTTT = GM.BLTTT or {}
GM.BLTTT.Workshop = GM.BLTTT.Workshop or { LoadedIds = {} }

local function normalize_workshop_id(rawId)
  if rawId == nil then
    return nil
  end

  local id = tostring(rawId):match("^%s*(%d+)%s*$")
  if not id or id == "" then
    return nil
  end

  return id
end

local function add_workshop_id(id, sourceLabel)
  local state = GM.BLTTT.Workshop
  if state.LoadedIds[id] then
    return
  end

  state.LoadedIds[id] = sourceLabel or "config"
  resource.AddWorkshop(id)
  blt_boot_log(("Mounted Workshop item %s (%s)"):format(id, state.LoadedIds[id]))
end

local function check_workshop_visibility(id)
  if not steamworks or not steamworks.FileInfo then
    return
  end

  steamworks.FileInfo(id, function(info)
    if not info then
      blt_boot_log(("Workshop self-check: no info for item %s."):format(id))
      return
    end

    local visibility = info.visibility or info.Visibility or info.VisibilityString
    if visibility == nil then
      blt_boot_log(("Workshop self-check: unknown visibility for item %s."):format(id))
      return
    end

    local visibilityLabel = visibility
    local isPublic = false
    if type(visibility) == "number" then
      isPublic = visibility == 0
      local map = { [0] = "public", [1] = "friends-only", [2] = "private", [3] = "unlisted" }
      visibilityLabel = map[visibility] or tostring(visibility)
    else
      visibilityLabel = tostring(visibility)
      isPublic = visibilityLabel:lower() == "public"
    end

    if not isPublic then
      blt_boot_log(("Workshop self-check: item %s is not public (%s). Clients will not download it."):format(id, visibilityLabel))
    end
  end)
end

local function parse_csv_ids(value)
  local ids = {}
  if not value or value == "" then
    return ids
  end

  for token in string.gmatch(value, "([^,]+)") do
    local id = normalize_workshop_id(token)
    if id then
      table.insert(ids, id)
    else
      blt_boot_log(("Workshop config: invalid ID '%s' ignored."):format(tostring(token)))
    end
  end

  return ids
end

local function mount_csv_ids()
  local csv = GM.BLTTT.GetConfigValue("Server", "bl_workshop_ids_csv") or ""
  local ids = parse_csv_ids(csv)
  for _, id in ipairs(ids) do
    add_workshop_id(id, "csv")
    check_workshop_visibility(id)
  end
end

local function mount_collection()
  local collectionId = normalize_workshop_id(GM.BLTTT.GetConfigValue("Server", "bl_workshop_collection_id"))
  if not collectionId then
    return
  end

  if not steamworks or not steamworks.GetCollectionDetails then
    blt_boot_log("Workshop collection requested, but steamworks.GetCollectionDetails is unavailable.")
    return
  end

  steamworks.GetCollectionDetails({ collectionId }, function(details)
    local collection = istable(details) and details[1] or nil
    if not collection then
      blt_boot_log(("Workshop collection %s failed to load."):format(collectionId))
      return
    end

    local children = collection.children or {}
    for _, childId in ipairs(children) do
      local id = normalize_workshop_id(childId)
      if id then
        add_workshop_id(id, "collection")
        check_workshop_visibility(id)
      end
    end

    blt_boot_log(("Workshop collection %s loaded (%d items)."):format(collectionId, #children))
  end)
end

mount_csv_ids()
mount_collection()

blt_boot_log("Workshop loader ready")
