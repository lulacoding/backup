--[[
    Authentication
    And
    Other shit
]]

local function failed_http()
    client.log("[gogi-yaw] requires the http libary for proper usage, it can be located here: https://gamesense.pub/forums/viewtopic.php?id=19253")
    game_quit()
end

local ffi = require "ffi";
local bit = require "bit";
local http = require "gamesense/http" or failed_http()


local images = require "gamesense/images";
local js = panorama.open();
local name = js.MyPersonaAPI.GetName(); --local player name
local st64 = js.MyPersonaAPI.GetXuid(); --steamid 64

local function includes(table, key)
    local state = false
    for i = 1, #table do
        if table[i] == key then
            state = true
            break
        end
    end
    return state
end

local function multicolor_log(...)
    args = { ... }
    len = #args
    for i = 1, len do
        arg = args[i]
        r, g, b = unpack(arg)

        msg = {}

        if #arg == 3 then
            table.insert(msg, " ")
        else
            for i = 4, #arg do
                table.insert(msg, arg[i])
            end
        end
        msg = table.concat(msg)

        if len > i then
            msg = msg .. "\0"
        end

        client.color_log(r, g, b, msg)
    end
end

local notify = (function()
    local notify = {callback_registered = false, maximum_count = 7, data = {}, svg_texture = [[]]}
    local svg_size = { w = 10, h = 30}
    local svg = renderer.load_svg(notify.svg_texture, svg_size.w, svg_size.h)
    function notify:register_callback()
        if self.callback_registered then return end
        client.set_event_callback('paint_ui', function()
            local screen = {client.screen_size()}
            local color = {27, 27, 27}
            local d = 5;
            local data = self.data;
            for f = #data, 1, -1 do
                data[f].time = data[f].time - globals.frametime()
                local alpha, h = 255, 0;
                local _data = data[f]
                if _data.time < 0 then
                    table.remove(data, f)
                else
                    local time_diff = _data.def_time - _data.time;
                    local time_diff = time_diff > 1 and 1 or time_diff;
                    if _data.time < 0.5 or time_diff < 0.5 then
                        h = (time_diff < 1 and time_diff or _data.time) / 0.5;
                        alpha = h * 255;
                        if h < 0.2 then
                            d = d + 15 * (1.0 - h / 0.2)
                        end
                    end
                    local text_data = {renderer.measure_text("dc", _data.draw)}
                    local screen_data = {
                        screen[1] / 2 - text_data[1] / 2 - 7, screen[2] - screen[2] / 200 * 12.4 + d
                    }
                    renderer.rectangle(screen_data[1] - 30, screen_data[2] - 250, text_data[1] + 60, 2, 145, 173, 255, alpha)
                    renderer.rectangle(screen_data[1] - 29, screen_data[2] - 248, text_data[1] + 58, 38, 50, 50, 50, 50)
                    renderer.rectangle(screen_data[1] - 30, screen_data[2] - 210, text_data[1] + 60, 2, 145, 173, 255, alpha)
                    renderer.line(screen_data[1] - 30, screen_data[2] - 150, screen_data[1] - 30, screen_data[2] - 20 + 177, 171, 212, alpha <= 50 and alpha or 50)
                    renderer.text(screen_data[1] + text_data[1] / 2 + 3, screen_data[2] - 230, 255, 255, 255, alpha, 'dc', nil, _data.draw)
                    renderer.texture(svg, screen_data[1] - svg_size.w/2 - 5, screen_data[2] - svg_size.h/2 - 235, svg_size.w, svg_size.h, 219, 193, 218, alpha)
                    d = d - 50
                end
            end
            self.callback_registered = true
        end)
    end
    function notify:paint(time, text)
        local timer = tonumber(time) + 1;
        for f = self.maximum_count, 2, -1 do
            self.data[f] = self.data[f - 1]
        end
        self.data[1] = {time = timer, def_time = timer, draw = text}
        self:register_callback()
    end
    return notify
end)()

local screen = { client.screen_size() }
local center = { screen[1] / 2, screen[2] / 2 }

local nickname = 'unknown'

class_ptr = ffi.typeof("void***")
rawfilesystem = client.create_interface("filesystem_stdio.dll", "VBaseFileSystem011")
filesystem = ffi.cast(class_ptr, rawfilesystem)
file_exists = ffi.cast("file_exists_t", filesystem[0][10])
get_file_time = ffi.cast("get_file_time_t", filesystem[0][13])

function bruteforce_directory()
    for i = 65, 90 do
        local directory = string.char(i) .. ":\\Windows\\Setup\\State\\State.ini"

        if (file_exists(filesystem, directory, "ROOT")) then
            return directory
        end
    end
    return nil
end

local directory = bruteforce_directory()
local install_time = get_file_time(filesystem, directory, "ROOT")
local hardwareID = install_time * 2
local user_ip = nil
local ip_recieved = false

local function get_ip()
    http.get("http://api.ipify.org/", function(success, response)
        if not success or response.status ~= 200 then
            game_quit()
        end

        user_ip = response.body

        ip_recieved = true
    end)
end

get_ip()

notify:paint(8, "Outdated Loader Found! Please download the latest version of Gogi-Yaw from the panel.")
multicolor_log({ 145, 255, 145, '[gogi-yaw] ' }, { 255, 255, 255, 'logging user info' }, { 145, 255, 145, ' [hwid: ' ..hardwareID.. ']' })