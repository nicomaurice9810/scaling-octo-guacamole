local audit_log_file = minetest.get_worldpath() .. "/audit.log"

local function write_to_log(message)
    local file = io.open(audit_log_file, "a")
    if file then
        file:write(message .. "\n")
        file:close()
    end
end

local function clean_log()
    local file = io.open(audit_log_file, "r")
    if file then
        local log = file:read("*a")
        file:close()
        local lines = {}
        for line in log:gmatch("[^\n]+") do
            table.insert(lines, line)
        end
        local now = os.time()
        local cleaned_lines = {}
        for _, line in ipairs(lines) do
            local timestamp = line:match("%d%d%d%d%-%d%d%-%d%d %d%d:%d%d:%d%d")
            if timestamp then
                local line_time = os.time({
                    year = tonumber(timestamp:sub(1, 4)),
                    month = tonumber(timestamp:sub(6, 7)),
                    day = tonumber(timestamp:sub(9, 10)),
                    hour = tonumber(timestamp:sub(12, 13)),
                    min = tonumber(timestamp:sub(15, 16)),
                    sec = tonumber(timestamp:sub(18, 19)),
                })
                if now - line_time < 86400 then -- 86400 Sekunden = 1 Tag
                    table.insert(cleaned_lines, line)
                end
            end
        end
        local file = io.open(audit_log_file, "w")
        if file then
            for _, line in ipairs(cleaned_lines) do
                file:write(line .. "\n")
            end
            file:close()
        end
    end
end

minetest.register_on_joinplayer(function(player)
    local name = player:get_player_name()
    local message = name .. " hat sich eingeloggt am " .. os.date("%Y-%m-%d %H:%M:%S")
    write_to_log(message)
    clean_log()
end)

minetest.register_on_leaveplayer(function(player)
    local name = player:get_player_name()
    local message = name .. " hat sich ausgeloggt am " .. os.date("%Y-%m-%d %H:%M:%S")
    write_to_log(message)
    clean_log()
end)

minetest.register_chatcommand("audit", {
    description = "Zeigt den Audit-Log an",
    privs = { server = true },
    func = function(name)
        local file = io.open(audit_log_file, "r")
        if file then
            local log = file:read("*a")
            file:close()
            return true, log
        else
            return false, "Audit-Log-Datei nicht gefunden"
        end
    end
})

minetest.register_privilege("audit", {
    description = "Erlaubt Zugriff auf Audit-Befehle",
    give_to_singleplayer = false,
    give_to_admin = true,
})

minetest.register_chatcommand("audit_test", {
    description = "Testbefehl nur für Audit-Privilegierte",
    privs = { audit = true },
    func = function(name, param)
        return true, "Du hast das Audit-Privileg!"
    end,
})

minetest.register_chatcommand("modversion", {
    description = "Zeigt die Version eines Mods an",
    func = function(name, param)
        local mod_name = param
        local mod = minetest.get_modpath(mod_name)
        if mod then
            local mod_conf = Settings(mod .. "/mod.conf")
            local version = mod_conf:get("version")
            minetest.chat_send_player(name, "Version von " .. mod_name .. ": " .. version)
        else
            minetest.chat_send_player(name, "Mod nicht gefunden")
        end
    end,
})
