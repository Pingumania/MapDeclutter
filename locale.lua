local ADDON_NAME, ns = ...
local L = setmetatable({}, { __index = function(t, k)
	local v = tostring(k)
	rawset(t, k, v)
	return v
end })
ns.L = L

local LOCALE = GetLocale()

if LOCALE == "enUS" then
    return
end

if LOCALE == "deDE" then
    return
end

if LOCALE == "frFR" then
    return
end

if LOCALE == "esES" or LOCALE == "esMX" then
    return
end

if LOCALE == "ptBR" then
    return
end

if LOCALE == "ruRU" then
    return
end

if LOCALE == "koKR" then
    return
end

if LOCALE == "zhCN" then
    return
end

if LOCALE == "zhTW" then
    return
end