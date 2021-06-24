 --[[
    Notes
    last updated 08/06/21
    Things to add/do:

    - Per item color changer
    - Grenade Blend
    - Debug Panel
    - ONSHOT AA
    - FIX OVERLAPP
    - FIX ANTIBRUTE
    - FAKELAG TRIGGER
    - NOSCOPE HC
    - IMPROVE IDEALTICK
 --]]
local name = " C&A"
local ref_inverter = g_Config:FindVar("Aimbot", "Anti Aim", "Fake Angle", "Inverter")
local ref_fake_options = g_Config:FindVar("Aimbot", "Anti Aim", "Fake Angle", "Fake Options")
local ref_freestanding = g_Config:FindVar("Aimbot", "Anti Aim", "Fake Angle", "Freestanding Desync")
local ref_on_shot = g_Config:FindVar("Aimbot", "Anti Aim", "Fake Angle", "Desync On Shot")
local ref_limit_left = g_Config:FindVar("Aimbot", "Anti Aim", "Fake Angle", "Left Limit")
local ref_limit_right = g_Config:FindVar("Aimbot", "Anti Aim", "Fake Angle", "Right Limit")
local ref_legs = g_Config:FindVar("Aimbot", "Anti Aim", "Misc", "Leg Movement")
local ref_sw = g_Config:FindVar("Aimbot", "Anti Aim", "Misc", "Slow Walk")
local ref_fd = g_Config:FindVar("Aimbot", "Anti Aim", "Misc", "Fake Duck")
local ref_yaw_add = g_Config:FindVar("Aimbot",  "Anti Aim", "Main", "Yaw Add")
local ref_yaw_base = g_Config:FindVar("Aimbot",  "Anti Aim", "Main", "Yaw Base")
local ref_aa_pitch = g_Config:FindVar("Aimbot",  "Anti Aim", "Main", "Pitch")
local ref_yaw_modifier = g_Config:FindVar("Aimbot",  "Anti Aim", "Main", "Yaw Modifier")
local ref_yaw_modifier_degree = g_Config:FindVar("Aimbot", "Anti Aim", "Main", "Modifier Degree")
local ref_dt = g_Config:FindVar("Aimbot",  "Ragebot", "Exploits", "Double Tap")
local ref_dt_autostop = g_Config:FindVar("Aimbot",  "Ragebot", "Misc", "Double Tap Options")
local ref_autopeek = g_Config:FindVar("Miscellaneous", "Main", "Movement", "Auto Peek")
local ref_fakelag = g_Config:FindVar("Aimbot",  "Anti Aim", "Fake Lag", "Enable Fake Lag")
local ref_fakelag_limit = g_Config:FindVar("Aimbot",  "Anti Aim", "Fake Lag", "Limit")
local ref_fakelag_rand = g_Config:FindVar("Aimbot", "Anti Aim", "Fake Lag", "Randomization")
local ref_v_md = g_Config:FindVar("Aimbot", "Ragebot", "Min. Damage", "Visible", "AutoSniper")
local ref_aw_md = g_Config:FindVar("Aimbot", "Ragebot", "Min. Damage", "Autowall", "AutoSniper")

local best_hitbox = {}
local best_damage = {}
local ticking   
local predicmode = "none"
local fakelagdisable
local yaw_base
local choke_cycle = 0
local roundeddamage
local dtthing
local combos
local idealticking
local mode
local should_invert
local tickbase = ""
local highdelta
local delta
local activedtmode = ""
local frame_rate = 0.0
local textSize = 0
local clock = 0
local ffi = require"ffi"
ffi.cdef[[
    short GetAsyncKeyState(int);
    int GetForegroundWindow(void);
    int FindWindowA(const char*, const char*);
    void* CreateFileA(
        const char*                lpFileName,
        unsigned long                 dwDesiredAccess,
        unsigned long                 dwShareMode,
        unsigned long lpSecurityAttributes,
        unsigned long                 dwCreationDisposition,
        unsigned long                 dwFlagsAndAttributes,
        void*                hTemplateFile
        );
    bool ReadFile(
            void*       hFile,
            char*       lpBuffer,
            unsigned long        nNumberOfBytesToRead,
            unsigned long*      lpNumberOfBytesRead,
            int lpOverlapped
          );
    bool WriteFile(
            void*       hFile,
            char*      lpBuffer,
            unsigned long        nNumberOfBytesToWrite,
            unsigned long*      lpNumberOfBytesWritten,
            int lpOverlapped
        );

    unsigned long GetFileSize(
        void*  hFile,
        unsigned long* lpFileSizeHigh
    );
    bool CloseHandle(void* hFile);
    typedef int(__fastcall* clantag_t)(const char*, const char*);
    void* GetProcAddress(void* hModule, const char* lpProcName);
    void* GetModuleHandleA(const char* lpModuleName);
    
    typedef struct {
        uint8_t r;
        uint8_t g;
        uint8_t b;
        uint8_t a;
    } color_struct_t;
    typedef void (*console_color_print)(const color_struct_t&, const char*, ...);
    typedef void* (__thiscall* get_client_entity_t)(void*, int);
]]
local pfile = ffi.cast("void*", ffi.C.CreateFileA("nl/C&A.txt", 0xC0000000, 0x00000003, 0, 0x4, 0x80, nil))
local fn_change_clantag = utils.PatternScan("engine.dll", "53 56 57 8B DA 8B F9 FF 15")
local set_clantag = ffi.cast("clantag_t", fn_change_clantag)
local size = ffi.C.GetFileSize(pfile, nil)
local buff = ffi.new("char[" ..(size + 1).. "]")
ffi.C.ReadFile(pfile, buff, size, nil, 0)
buff = ffi.string(buff)
local ffi_helpers = {
    color_print_fn = ffi.cast("console_color_print", ffi.C.GetProcAddress(ffi.C.GetModuleHandleA("tier0.dll"), "?ConColorMsg@@YAXABVColor@@PBDZZ")),
    color_print = function(self, text, color,text2,color2)
        local col = ffi.new("color_struct_t")
        local col2 = ffi.new("color_struct_t")

        col.r = color:r() * 255
        col.g = color:g() * 255
        col.b = color:b() * 255
        col.a = color:a() * 255

        col2.r = color2:r() * 255
        col2.g = color2:g() * 255
        col2.b = color2:b() * 255
        col2.a = color2:a() * 255

        self.color_print_fn(col, text)
        self.color_print_fn(col2, text2)

    end
}
local function coloredPrint(color, text, color2, text2)
	ffi_helpers.color_print(ffi_helpers, text, color,text2,color2)
end
local function game_is_active()
    local hWndForeGround = ffi.C.GetForegroundWindow();
    local hWndFound = ffi.C.FindWindowA("Valve001", nil);

    return (hWndForeGround == hWndFound) and hWndForeGround ~= nil;
end

local InputSystem = {}
InputSystem.__index = InputSystem

function InputSystem.init()
    local self = setmetatable({
        has_been_pressed = {},
        key_was_down = {},
        drag_table = {},
    }, InputSystem)

    return self
end

function InputSystem:register_key(key)
    if self.has_been_pressed[key] == nil then
        self.has_been_pressed[key] = false
    end

    if self.key_was_down[key] == nil then
        self.key_was_down[key] = false
    end
end

function InputSystem:register_dragging(index)
    local tbl = self.drag_table

    if not tbl[index] then
        tbl[index] = {
            delta_position = {x = 0, y = 0},
            mouse_down_outside = false,
            mouse_down_inside = false
        }
    end

    return tbl[index]
end

function InputSystem:is_key_held(key)
    if ffi.C.GetAsyncKeyState(key) ~= 0 and game_is_active() and cheat.IsMenuVisible() then
        return true
    end

    return false
end

function InputSystem:is_key_pressed(key)
    self:register_key(key)
    
    if self:is_key_held(key) and not self.has_been_pressed[key] then
        self.has_been_pressed[key] = true
        return true
    elseif not self:is_key_held(key) then
        self.has_been_pressed[key] = false
    end

    return false
end

function InputSystem:is_key_released(key)
    self:register_key(key)
    
    if self:is_key_held(key) then
        self.key_was_down[key] = true
    elseif not self:is_key_held(key) and self.key_was_down[key] then
        self.key_was_down[key] = false
        return true
    end

    return false
end

function InputSystem:is_mouse_in_area(x, y, w, h)
    local mouse_pos = cheat.GetMousePos()

    return ((mouse_pos.x >= x and mouse_pos.x < x + w and mouse_pos.y >= y and mouse_pos.y < y + h) and cheat.IsMenuVisible())
end

function InputSystem:handle_dragging(index, x, y, w, h)
    local mouse_pos = cheat.GetMousePos()
    local tbl = self:register_dragging(index)

    if not self:is_key_held(1) then
        tbl.mouse_down_outside = false
        tbl.mouse_down_inside = false
    end

    if not self:is_mouse_in_area(x, y, w, h) then
        tbl.mouse_down_outside = true
    elseif not tbl.mouse_down_inside and not tbl.mouse_down_outside then
        tbl.mouse_down_inside = true
    
        tbl.delta_position.x = mouse_pos.x - x
        tbl.delta_position.y = mouse_pos.y - y
    end

    if tbl.mouse_down_inside then
        x = mouse_pos.x - tbl.delta_position.x
        y = mouse_pos.y - tbl.delta_position.y
    end

    return x, y, x + w, y + h
end

function InputSystem:is_mouse_in_area_vec(pos1, pos2)
    local mouse_pos = cheat.GetMousePos()

    return ((mouse_pos.x >= pos1.x and mouse_pos.x < pos2.x and mouse_pos.y >= pos1.y and mouse_pos.y < pos2.y) and cheat.IsMenuVisible())
end

function InputSystem:handle_dragging_vec(index, pos1, pos2)
    local mouse_pos = cheat.GetMousePos()
    local tbl = self:register_dragging(index)

    if not self:is_key_held(1) then
        tbl.mouse_down_outside = false
        tbl.mouse_down_inside = false
    end

    if not self:is_mouse_in_area_vec(pos1, pos2) then
        tbl.mouse_down_outside = true
    elseif not tbl.mouse_down_inside and not tbl.mouse_down_outside then
        tbl.mouse_down_inside = true
    
        tbl.delta_position.x = mouse_pos.x - pos1.x
        tbl.delta_position.y = mouse_pos.y - pos1.y
    end

    if tbl.mouse_down_inside then
        pos2.x = pos2.x - (pos1.x - (mouse_pos.x - tbl.delta_position.x))
        pos2.y = pos2.y - (pos1.y - (mouse_pos.y - tbl.delta_position.y))

        pos1.x = mouse_pos.x - tbl.delta_position.x
        pos1.y = mouse_pos.y - tbl.delta_position.y
    end
end
local input = InputSystem.init()

function startlua()
    local info = {
        version = "beta",
        username = cheat.GetCheatUserName(),
        side = nil
    }
    local brute = {
        fl_mode = "",
        tick_miss = 0,
        yaw_status = "",
        indexed_angle = 0,
        last_miss = 0,
        best_angle = 0,
        misses = 0,
        shootermisses = 0,
        right_misses = 0,
        left_misses = 0,
        playermode = 0
    }

    menu.Text("C&A Neverlose", "Welcome "..info.username.."!\n\nBuild Version: "..info.version.."\n\nAdd Crow#5151 On discord to join the Buyers Only Discord Server!")
    local settings_button = menu.Button("C&A Neverlose", "Load Recommended Settings")

    local ui = {
        --MAIN MENU
        --AA
        aamenutext = menu.Text("Anti Aim", "[C&A] Anti Aim"),
        aa_modes = menu.Combo("Anti Aim", "Anti-Aim Presets", {"-","Smart","Rotation Synced"}, 0, "Freestanding logic that will be used with the LUA (this is not the inbuilt freestand)"),
        aa_multimodes = menu.MultiCombo("Anti Aim", "AA Customization", { "Lowdelta Slow Walk","Legit AA on Use", "Avoid High Delta"}, 0),

        freestanding_mode = menu.Combo("Anti Aim", "Freestanding style", {"-","Default", "Reversed"}, 0, "Freestanding logic that will be used with the LUA (this is not the inbuilt freestand)"),
        dormant_switch = menu.Switch("Anti Aim", "Dormant AA",false, "Enables Anti-Aim on Enemy Dormant"),
        dormant_option = menu.Combo("Anti Aim", "Dormant AA Options", {"Jitter", "Offence"}, 0, "Anti-Aim presets that will occur when enemys are dormant"),
        -- freestand_jitter = menu.Switch("Anti Aim", "Inactive Freestand Jitter",false, "Enables Inactive Freestand Jitter"),
        -- lowdelta_slowwalk = menu.Switch("Anti Aim", "Lowdelta Slow Walk",false, "Enables Lowdelta Slow Walk"),
        brute_switch = menu.Switch("Anti Aim", "Anti-Bruteforce",false, "Enables Anti-Bruteforce"),
        Jitter_legs_switch = menu.Switch("Anti Aim", "Jitter Legs",false, "Jitters your Leg Movement"),
        --DT
        dtmenutext = menu.Text("Exploits", "[C&A] Exploits"),
        dt_enable_switch = menu.Switch("Exploits", "C&A Double Tap",false, "Enables Double Tap Features"),
        dtmode = menu.MultiCombo("Exploits", "Double Tap Options", {"Latency", "Vulnerability"}, 1),
        vul_mode = menu.Combo("Exploits", "Vulnerability Mode", {"safe", "unsafe"}, 0),
        idealtick_switch = menu.Switch("Exploits", "Ideal-Tick",false, "Ideal Tick, Make sure to bind"),
        dt_prediction_switch = menu.Switch("Exploits", "Damage Prediction",false, "Enables Double Tap Damage Prediction"),
        dt_prediction_log_switch = menu.Switch("Exploits", "Prediction logs",false, "Enables Prediction logs"),
        zues_dt_enable_switch = menu.Switch("Exploits", "Teleport On Zeus",false, "Enables Teleport On Zeus"),
    
        --Fake-Lag
        flmenutext = menu.Text("Fake Lag", "[C&A] Fake Lag"),
        fakelag_switch = menu.Switch("Fake Lag","C&A Fake Lag",false,"Enables C&A Fake Lag"),
        fakelag_mode = menu.Combo("Fake Lag", "Fake Lag Mode", {"Dynamic", "Fluctuate"}, 0),
        fakelag_fluc_amount= menu.SliderInt("Fake Lag","Flucuation Amount",1,1,14),
        fakelag_disable = menu.Switch("Fake Lag","Disable on Knife",false,"Disables Fake Lag on knife"),

        --Visuals
        visualmenutext = menu.Text("Visual", "[C&A] Visual"),
        indicators_check = menu.Switch("Visual","Enable Indicators",false,"Enables all C&A visual indications."),
        indicator_style =  menu.Combo("Visual", "Indicator Style", {"Main","Simple", "Other"}, 0),
        arrow_check = menu.Switch("Visual","Enable Arrows",false),
        arrow_style =  menu.Combo("Visual", "Arrow Style", {"Main","Flat"}, 0),
        arrowside_style =  menu.Combo("Visual", "Arrow Direction Style", {"Manuel", "Freestanding"}, 0),
        arrow_vis_check = menu.Switch("Visual","Enable Only active Arrow",false),
        watermark_style =  menu.Combo("Visual", "Watermark Style", {"Main","DT"}, 0),
        debug_check = menu.Switch("Visual","Enable Debug Logs",false),
        debug_logs = menu.MultiCombo("Visual", "Debug Options", {"Panel", "Console"}, 1),
        clantagswitch = menu.Switch("Visual", "Clantag",false),
        clantag_style =  menu.Combo("Visual", "Clantag Style", {"Static","Animated"}, 0),


        -- --colors
        -- left_check = menu.Switch("Keybinds","Manuel Left Bind",false),
        -- right_check = menu.Switch("Visual","Manuel Right Bind",false),
        -- back_check = menu.Switch("Visual","Manuel Back Bind",false),

        --hidden data nigga
        x_pos_slider = menu.SliderInt("hidden","hidden x Amount",1,1,1000),
        y_pos_slider = menu.SliderInt("hidden","hidden y Amount",1,1,1000),

        colors = {
            main = menu.ColorEdit("Colors", "Main accent", Color.new(1.0, 1.0, 1.0, 1.0)),
            other = menu.ColorEdit("Colors", "Secondary accent", Color.new(1.0, 1.0, 1.0, 1.0)),
            dt = menu.ColorEdit("Colors", "DT Active", Color.new(1.0, 1.0, 1.0, 1.0)),
            arrow = menu.ColorEdit("Colors", "Arrow Active Color", Color.new(1.0, 1.0, 1.0, 1.0)),
            arrowinactive = menu.ColorEdit("Colors", "Arrow Inactive Color", Color.new(1.0, 1.0, 1.0, 1.0)),
        }
    }
    local hitgroups = {

        [0] = "generic",
        [1] = "head",
        [2] = "chest",
        [3] = "stomach",
        [4] = "left arm",
        [5] = "right arm", 
        [6] = "left leg",
        [7] = "right leg", 
        [10] = "gear"
        
        }
    local hitboxes = {
        [0] = "head",
        [1] = "neck",
        [2] = "pelvis",
        [3] = "stomach",
        [4] = "lower chest",
        [5] = "chest",
        [6] = "upper chest",
        [7] = "right thigh",
        [8] = "left thigh",
        [9] = "right calf",
        [10] = "left calf",
        [11] = "right foot",
        [12] = "left foot",
        [13] = "right hand",
        [14] = "left hand",
        [15] = "right upper arm",
        [16] = "right forearm",
        [17] = "left upper arm",
        [18] = "left forearm"
    }
    local animatedclantag = {
        "      ",
        "c     ",
        "c&    ",
        "c&a   ",
        "c&a   ",
        "c&a   ",
        "c&a   ",
        "c&    ",
        "c     ",
        "      ",
    }
    local statictag = {
        "c&a     ",
    }
    
    local function angle_vector(angle_x, angle_y)
        local sy = math.sin(math.rad(angle_y))
        local cy = math.cos(math.rad(angle_y))
        local sp = math.sin(math.rad(angle_x))
        local cp = math.cos(math.rad(angle_x))
        return cp * cy, cp * sy, -sp
    end
    function get_delta(ent)
        local speed = get_velocity(ent)
        local deltalol = (speed / 8)
        return (58 - deltalol)
    end
    function C_BaseEntity:m_iHealth()
        return self:GetProp("DT_BasePlayer", "m_iHealth")
    end
    
    function VectorAdd(a, b) 
        return {a[1] + b[1], a[2] + b[2], a[3] + b[3]};
    end
    
    function VectorSubtract(a, b) 
        return {a[1] - b[1], a[2] - b[2], a[3] - b[3]};
    end
    
    function VectorMultiply(a, b) 
        return {a[1] * b[1], a[2] * b[2], a[3] * b[3]};
    end
    
    function VectorLength(x, y, z) 
        return math.sqrt(x * x + y * y + z * z);
    end
    
    function VectorNormalize(vec) 
        local length = VectorLength(vec[1], vec[2], vec[3]);
        return {vec[1] / length, vec[2] / length, vec[3] / length};
    end
    
    function VectorDot(a, b) 
        return a[1] * b[1] + a[2] * b[2] + a[3] * b[3];
    end
    
    function VectorDistance(a, b) 
        return VectorLength(a[1] - b[1], a[2] - b[2], a[3] - b[3])
    end

    local function get_damage(enemy, vec_end)
        local e = {}
    
        e[0] = enemy:GetHitboxCenter(0)
        e[1] = e[0] + Vector.new(40,0,0)
        e[2] = e[0] + Vector.new(0,40,0)
        e[3] = e[0] + Vector.new(-40,0,0)
        e[4] = e[0] + Vector.new(0,-40,0)
        e[5] = e[0] + Vector.new(0,0,40)
        e[6] = e[0] + Vector.new(0,0,-40)
    
        local best_fraction = 0
    
        for i = 0, 6 do
            local trace = cheat.FireBullet(enemy, e[i], vec_end)
            if trace.damage > best_fraction then
                best_fraction = trace.damage
            end
        end
    
        return best_fraction
    end
    function get_abs_fps()
        frame_rate = 0.9 * frame_rate + (1.0 - 0.9) * g_GlobalVars.absoluteframetime
        return math.floor((1.0 / frame_rate) + 0.5)
        end
    local extend_vector = function(pos,length,angle) 
        local rad = angle * math.pi / 180
        return pos + Vector:new((math.cos(rad) * length),(math.sin(rad) * length),0)
    end
    local function get_latency()
        local netchann_info = g_EngineClient:GetNetChannelInfo()
        if netchann_info == nil then return "0" end
        local latency = netchann_info:GetLatency(0)
        return string.format("%1.f", math.max(0.0, latency) * 1000.0)
        end
    function extrapolate_pos(pos,ent,ticks)
        local vecvelocity = ent:GetProp("m_vecVelocity[1]")
        local vecvelocity2 = ent:GetProp("m_vecVelocity[2]")
        return Vector.new(pos.x + vecvelocity* g_GlobalVars.interval_per_tick *ticks,pos.y + vecvelocity2*g_GlobalVars.interval_per_tick*ticks,pos.z)
    end
    
    function get_velocity(ent) 
        return VectorLength(ent:GetProp("m_vecVelocity[0]"),ent:GetProp("m_vecVelocity[1]"),ent:GetProp("m_vecVelocity[2]"))
    end
    
    local function on_ground(player)
        local flags = player:GetProp("m_fFlags")
        
        if bit.band(flags, 1) == 1 then
            return true
        end
        
        return false
    end
    
    local function in_air(player)
        local flags = player:GetProp("m_fFlags")
        
        if bit.band(flags, 1) == 0 then
            return true
        end
        
        return false
    end
    local function aa_base(delta, lean, override)
        if delta <= 0 and override == true then
            antiaim.OverrideInverter(false)
        else
            if delta > 0 and override == true then
                antiaim.OverrideInverter(true)
            end
        end
        antiaim.OverrideLimit(math.abs(delta))
        antiaim.OverrideYawOffset(lean)
    end
   
    local function is_crouching(player)
        local flags = player:GetProp("m_fFlags")
        
        if bit.band(flags, 4) == 4 then
            return true
        end
        
        return false
    end

    local has_killed 
 
    local function round(num, decimals)
        local mult = 10^(decimals or 0)
        return math.floor(num * mult + 0.5) / mult
    end
    
    function normalize_yaw(yaw)
        while yaw > 180 do yaw = yaw - 360 end
        while yaw < -180 do yaw = yaw + 360 end
        return yaw
    end
    
    local function world2scren(xdelta, ydelta)
        if xdelta == 0 and ydelta == 0 then
            return 0
        end
        return math.deg(math.atan2(ydelta, xdelta))
    end
    function g_Render_TextOutline(text, pos, clr, size, font)
        clr_2 = Color.new(0,0,0,clr:a())
        g_Render:Text(text, pos + Vector2:new(1,1), clr_2, size, font)
        g_Render:Text(text, pos + Vector2:new(1,-1), clr_2, size, font)
        g_Render:Text(text, pos + Vector2:new(1,0), clr_2, size, font)
        g_Render:Text(text, pos + Vector2:new(-1,1), clr_2, size, font)
        g_Render:Text(text, pos + Vector2:new(-1,-1), clr_2, size, font)
        g_Render:Text(text, pos + Vector2:new(-1,0), clr_2, size, font)
        g_Render:Text(text, pos + Vector2:new(0,1), clr_2, size, font)
        g_Render:Text(text, pos + Vector2:new(0,-1), clr_2, size, font)
        g_Render:Text(text, pos + Vector2:new(0,0), clr_2, size, font)
    
        g_Render:Text(text, pos, clr, size, font)
    end
    local function CalcAngle(local_pos, enemy_pos)
        local ydelta = local_pos.y - enemy_pos.y
        local xdelta = local_pos.x - enemy_pos.x
        local relativeyaw = math.atan( ydelta / xdelta )
        relativeyaw = normalize_yaw( relativeyaw * 180 / math.pi )
        if xdelta >= 0 then
            relativeyaw = normalize_yaw(relativeyaw + 180)
        end
        return relativeyaw
    end
    local function get_enemy()
        local localplayer = g_EntityList:GetClientEntity(g_EngineClient:GetLocalPlayer())
        local me2 = localplayer:GetPlayer()
    
        best_enemy = nil
        local players = g_EntityList:GetPlayers()
        local best_fov = 180
        for ent_index, player in pairs(players) do
            local eyepos = me2:GetEyePosition()
            local viewangles = g_EngineClient:GetViewAngles()
    
            for i=1, #players do
                local lpos = localplayer:GetRenderOrigin()
                local cur_fov = math.abs(normalize_yaw(world2scren(eyepos.x - lpos.x, eyepos.y - lpos.y) - viewangles.yaw + 180))
                if cur_fov < best_fov then
                    best_fov = cur_fov
                    best_enemy = players[i]
                end
                return best_enemy
            end
        end
    end
    local checkhitbox = {18,17,16,15,14,13,12,11,10,9,8,7,6,5,4,3,2,0}

    local function canseeentity(localplayer, entity)
        if not entity or not localplayer then return false end
        local canhit = false
        for k,v in pairs(checkhitbox) do
            local trace = cheat.FireBullet(localplayer, localplayer:GetEyePosition(), entity:GetPlayer():GetHitboxCenter(v))
            local damage = round(trace.damage, 0)
            if damage > 0 then 
                canhit = true
                break 
            end
        end
        return canhit
    end
    
    local function wait()
        local sleep_time = -1
        if math.floor(g_GlobalVars.curtime) > sleep_time + 5 then
        --do something
        sleep_time = g_GlobalVars.curtime
        end
    end
    function get_target()
        local me = g_EntityList:GetClientEntity(g_EngineClient:GetLocalPlayer())
        if me == nil then
            return nil
        end
    
        local lpos = me:GetRenderOrigin()
        local viewangles = g_EngineClient:GetViewAngles()
    
        local players = g_EntityList:GetPlayers()
        if players == nil or #players == 0 then
            return nil
        end
    
        local data = {}
        fov = 180
        for i = 1, #players do
            if players[i] == nil or players[i]:IsTeamMate() or players[i] == me or players[i]:IsDormant() or players[i]:m_iHealth() <= 0 then goto skip end
            local epos = players[i]:GetProp("m_vecOrigin")
            local cur_fov = math.abs(normalize_yaw(world2scren(lpos.x - epos.x, lpos.y - epos.y) - viewangles.yaw + 180))
            if cur_fov <= fov then
                data = {
                    id = players[i],
                    fov = cur_fov
                }
                fov = cur_fov
                
            end
            ::skip::
        end
    
        if data.id ~= nil then
            local epos = data.id:GetProp("m_vecOrigin")
    
            data.yaw = CalcAngle(lpos,epos)
        end
    
        return data
    end
    local function get_best_angle()
        -- Since we run this from run_command no need to check if we are alive or anything.
        local data = get_target()
        local me = g_EntityList:GetClientEntity(g_EngineClient:GetLocalPlayer())
        local player = me:GetPlayer()
        brute.best_angle = 0
    
    
        if data.id == nil then return end
        
        local eye_pos = player:GetEyePosition()
        local hitbox = data.id:GetPlayer():GetHitboxCenter(0)
        local angles = {90,45,-90,-45}
        
    
        local yaw = CalcAngle(eye_pos,hitbox)
        local vec1_end = extend_vector(hitbox,10,yaw + 90)
        local vec2_end = extend_vector(hitbox,10,yaw - 90)
        local vec3_end = extend_vector(hitbox,100,yaw + 90)
        local vec4_end = extend_vector(hitbox,100,yaw - 90)

        ldamage = get_damage(data.id,vec1_end)
        rdamage = get_damage(data.id,vec2_end)
        l2damage = get_damage(data.id,vec3_end)
        r2damage = get_damage(data.id,vec4_end)

        if l2damage > r2damage or ldamage > rdamage then
            brute.best_angle = 1
        elseif r2damage > l2damage or rdamage > ldamage then
            brute.best_angle = 2
        end
    end
    local function is_auto_vis(local_player,player)

        local fire = cheat.FireBullet(local_player, local_player:GetEyePosition(), player)
        if entity == nil then
            return false
        end
        if entity == local_player then
            return false
        end

            if fire.damage > ref_v_md:GetInt() then
                return true
            else
                return false
            end
    end
    
    local function trace_positions(player,player2,player3,local_player)
        if is_auto_vis(local_player,player) then
            return true
        end
        if is_auto_vis(local_player,player2) then
            return true
        end
        if is_auto_vis(local_player,player3) then
            return true
        end
        return false
    end
    function get_freestand_side(target,type)
        local me = g_EntityList:GetClientEntity(g_EngineClient:GetLocalPlayer())
        if target.id == nil then
            return nil
        end
    
        local data = {left = 0, right = 0}
        local angles = {90,45,-90,-45}
        
        for i = 1, #angles do
            local hitbox = me:GetPlayer():GetHitboxCenter(1)
            local vec_end = extend_vector(hitbox,100,target.yaw + angles[i])
    
            damage = get_damage(target.id,vec_end)
    
            if angles[i] > 0 then
                --data.left = damage + data.left
                
                if data.left < damage then
                    data.left = damage
                end
                
            elseif angles[i] < 0 then
                --data.right = damage + data.right
                
                if data.right < damage then
                    data.right = damage
                end
                
            end
        end
    
        if data.left + data.right == 0 then
            return nil
        end
    
        if data.left > data.right then
            return (type == 0) and 0 or 1
        elseif data.right > data.left then
            return (type == 0) and 1 or 0
        else 
            return 2
        end
    end
    function handle_fake_yaw(side,target,me)
       
        local data = get_target()
        combos = {
            usage = {
                normal = {
                    left = 25,
                    right = 25
                },
                ducking = {
                    left = 25,
                    right = 25
                } --ducking and ct and standing and not jumping
            },
            standing = {
                normal = {
                    left = 25,
                    right = 25
                },
                ducking = {
                    ct = {
                        left =  math.abs(-3, 3),
                        right = math.abs(-3, 3)
                    },
                    t = {
                        left = math.abs(-3, 3),
                        right = math.abs(-3, 3)
                    },
                }
            },
            slow_walking = {
                normal = {
                    left = 35,
                    right = 35
                },
                lowdelta = {
                    left = 18,
                    right = 18
                    
                }
            },
            running = {
                normal = {
                    left = 59,
                    right = 59
                },
                ducking = {
                    ct = {
                        left = 27,
                        right = 27
                    },
                    t = {
                        left = 27,
                        right = 27
                    }
                }
            },
            jumping = {
                normal = {
                    left = 59,
                    right = 59
                }
            }
        }
    
        vel = get_velocity(me)
        states = {
            team = (me:GetProp("m_iTeamNum") == 3),
            usage = false,
            ducking = is_crouching(me),
            standing = (vel < 1.2),
            slowwalking = (ref_sw:GetInt() ~= 0),
            running = (vel >= 1.2),
            jumping = in_air(me)
        }
    
        if states.usage then
            --[[
            if states.ducking and states.team and states.standing and not states.jumping then
                delta = combos.usage.ducking
            else 
                delta = combos.usage.normal.left
            end
            
        elseif brute.on_shot[1] == true and brute.on_shot[2] - globals.curtime() > 0 and contains(ui.get(gui.low_delta_on),"Shot fired") then
            delta = 59
            on_shot = true
        elseif anti_brute then
            delta = 59
            ]]
        elseif states.standing and not states.jumping then
            if states.ducking then
                if states.team then
                    playermode = combos.standing.ducking.ct
                    delta = combos.standing.ducking.ct
                else 
                    playermode = combos.standing.ducking.t
                    delta = combos.standing.ducking.t
                end
            else 
                playermode = combos.standing.normal
                delta = combos.standing.normal
            end
        elseif states.slowwalking and not states.jumping then
            if(ui.aa_multimodes:GetBool(0)) then
                playermode = combos.slow_walking.lowdelta

                delta = combos.slow_walking.lowdelta
            else 
                playermode = combos.slow_walking.normal

                delta = combos.slow_walking.normal
            end   
        elseif states.running and not states.jumping then
            if states.ducking then
                if states.team then
                    playermode = combos.running.ducking.ct

                    delta = combos.running.ducking.ct
                else 
                    playermode = combos.running.ducking.t

                    delta = combos.running.ducking.t
                end
            else
                playermode = combos.running.normal

                delta = combos.running.normal
            end
        elseif states.jumping then
            
            playermode = aa_base(-2, 2, true)

        end
        
        if g_ClientState.m_choked_commands == 0 then
            body_yaw = math.max(-60, math.min(60, round((me:GetProp("m_flPoseParameter")[11] or 0)*120-60+0.5, 1)))
        end
        if(has_killed == true) then

        else
            yaw_add = 0
    
            if vel > 200 then
                yaw_add = 20
            elseif vel > 80 then
                yaw_add = 10
            end
            -- if side == nil then
            --     ref_yaw_add:SetInt(0)
            -- elseif side ~= 2 then
            --     ref_yaw_add:SetInt(side == 1 and yaw_add or -yaw_add)
            -- end
        end


    
  
        if(data.id == nil and ui.dormant_option:GetInt() == 1) then
            ref_limit_right:SetInt(60)
            ref_limit_left:SetInt(60)
        elseif(ui.aa_multimodes:GetBool(1) and cheat.IsKeyDown(0x45)) then
            ref_limit_right:SetInt(60)
            ref_limit_left:SetInt(60)
        else
            ref_limit_left:SetInt(delta.left)
            ref_limit_right:SetInt(delta.right)
        end
        local slowwalking
        if(ref_sw:GetInt() ~= 0) then
            slow_walking = true
            ref_fake_options:SetBool(0,true)
            ref_fake_options:SetBool(1,false)
        else
            if(slowwalking == true) then
                ref_fake_options:SetInt(dormat_data[1])
                slowwalking = false
            end
            
        end
    end
    local notdormant
    local dormat_data = {
        ref_fake_options:GetInt(), ref_yaw_modifier:GetInt(), ref_yaw_modifier_degree:GetInt()
    }
    
    local legit_aa_data = {
        ref_yaw_base:GetInt(), ref_aa_pitch:GetInt(),
        ref_limit_left:GetInt(), ref_limit_right:GetInt()
    }
                      -- don't touch
    
    function handle_aa()
        local fakeoffset
        local realoffset
        local yawbase
        local yawadd
        local yawadddegree
        local fakeoptions
        local dormantoff
        local distortion
        local me = g_EntityList:GetClientEntity(g_EngineClient:GetLocalPlayer())
        local data = get_target()
        local health = me:GetProp("m_iHealth")
        if (clock == 3) then

            clock = 0   
        else 
            clock = clock + 1
        end

    
        brute.tick_miss = brute.tick_miss + 1
        if(health > 0) then

            
            target = {
                id = (data == nil) and nil or data.id,
                yaw = (data == nil) and nil or data.yaw,
                fov = (data == nil) and nil or data.fov
            }

            info.side = get_freestand_side(target,ui.freestanding_mode:GetInt())
            if(ui.aa_modes:GetInt() == 0) then
                dormantoff = true
                if(data.id == nil) then
                    if(ui.dormant_switch:GetBool()) then    
                        if(ui.dormant_option:GetInt() == 0) then
                            brute.yaw_status = "JITTER"
                            notdormant = true
                            ref_fake_options:SetInt(2)
                            ref_yaw_modifier:SetInt(1)
                            ref_yaw_modifier_degree:SetInt(-10)
                        
                        elseif(ui.dormant_option:GetInt() == 1) then
                            brute.yaw_status = "OFFENCE"
                            if(ref_fake_options:GetInt() == 2) then
                                ref_fake_options:SetInt(0)
                            end
                            notdormant = true
                            ref_yaw_modifier:SetInt(2)
                            ref_yaw_modifier_degree:SetInt(-3)
                        
                        
                        end
                    else
                        brute.yaw_status = "DEFAULT"
                    end
                elseif(data.id ~= nil) then
                    brute.yaw_status = "DEFAULT"
                    if(ui.dormant_option:GetInt() == 0) then
                        
                        if(ui.dormant_switch:GetBool()) then
                            ref_fake_options:SetInt(dormat_data[1])
                            ref_yaw_modifier:SetInt(dormat_data[2])
                            ref_yaw_modifier_degree:SetInt(dormat_data[3])
                            notdormant = false
                        end


                    elseif(ui.dormant_option:GetInt() == 1) then
                        if(ui.dormant_switch:GetBool()) then
                            ref_yaw_modifier:SetInt(dormat_data[2])
                            ref_yaw_modifier_degree:SetInt(dormat_data[3])
                            notdormant = false
                        end
                    

                    end
                    if(ui.dormant_switch:GetBool() == false) then  

                        if(ui.dormant_option:GetInt() == 0 and dormantoff == true) then
                            
                            ref_fake_options:SetInt(dormat_data[1])
                            ref_yaw_modifier:SetInt(dormat_data[2])
                            ref_yaw_modifier_degree:SetInt(dormat_data[3])
                            dormantoff = false
                        elseif(ui.dormant_option:GetInt() == 1 and dormantoff == true) then
                            ref_yaw_modifier:SetInt(dormat_data[2])
                            ref_yaw_modifier_degree:SetInt(dormat_data[3])
                            dormantoff = false

                        end
                    end
                end
                ref_fake_options:SetBool(3,false)
            
                -- if(ui.freestand_jitter:GetBool()) then
                --     if info.side == nil then
                --         ref_inverter:SetBool(true)
                --         ref_fake_options:SetBool(1,true)
                --         ref_freestanding:SetInt(0)
                --     elseif info.side == 0 then
                --         ref_freestanding:SetInt(1)
                --         ref_inverter:SetBool(false)
                --         ref_fake_options:SetBool(1,false)
        
                --     elseif info.side == 1 then
                --         ref_fake_options:SetBool(1,false)
                --         ref_freestanding:SetInt(1)
                --         ref_inverter:SetBool(true)
                --     elseif info.side == 2 then
                --         ref_fake_options:SetBool(1,false)
                --         ref_inverter:SetBool(true)
                --         ref_freestanding:SetInt(0)
                --     end
                if(ui.freestanding_mode:GetInt() == 1) then
                    if info.side == nil then
                        should_invert = true
                        if(should_invert == true) then
                            ref_inverter:SetBool(true)
                            should_invert = false
                        end
                        -- ref_fake_options:SetBool(1,true)
                        ref_freestanding:SetInt(0)
                    elseif info.side == 0 then
                        if(should_invert == false) then
                            ref_inverter:SetBool(false)
                            should_invert = true
                        elseif(should_invert == true) then
                            ref_inverter:SetBool(true)
                            should_invert = false
                        end
                        ref_freestanding:SetInt(1)
                        
                        -- ref_fake_options:SetBool(1,false)
        
                    elseif info.side == 1 then
                        -- ref_fake_options:SetBool(1,false)
                        ref_freestanding:SetInt(1)
                        ref_inverter:SetBool(true)
                    elseif info.side == 2 then

                        -- ref_fake_options:SetBool(1,false)
                        ref_inverter:SetBool(true)
                        ref_freestanding:SetInt(0)
                    end
                elseif(ui.freestanding_mode:GetInt() == 2) then
                    if info.side == nil then
                        ref_inverter:SetBool(true)
                        -- ref_fake_options:SetBool(1,true)
                        ref_freestanding:SetInt(0)
                    elseif info.side == 0 then
                        ref_freestanding:SetInt(2)
                        ref_inverter:SetBool(false)
                        -- ref_fake_options:SetBool(1,false)
        
                    elseif info.side == 1 then
                        -- ref_fake_options:SetBool(1,false)
                        ref_freestanding:SetInt(2)
                        ref_inverter:SetBool(true)
                    elseif info.side == 2 then
                        -- ref_fake_options:SetBool(1,false)
                        ref_inverter:SetBool(true)
                        ref_freestanding:SetInt(0)
                    end
                end
                ref_on_shot:SetInt(3)
                handle_fake_yaw(info.side,target,me)
            elseif(ui.aa_modes:GetInt() == 1) then
                --DEFAULT\
                
                if has_killed == nil or  has_killed == false then

                    dormantoff = true
                    if(data.id == nil) then
                        if(ui.dormant_switch:GetBool()) then    
                            if(ui.dormant_option:GetInt() == 0) then
                                brute.yaw_status = "JITTER"
                                notdormant = true
                                ref_fake_options:SetInt(2)
                                ref_yaw_modifier:SetInt(1)
                                ref_yaw_modifier_degree:SetInt(-10)
                            
                            elseif(ui.dormant_option:GetInt() == 1) then
                                brute.yaw_status = "OFFENCE"
                                if(ref_fake_options:GetInt() == 2) then
                                    ref_fake_options:SetInt(0)
                                end
                                notdormant = true
                                ref_yaw_modifier:SetInt(2)
                                ref_yaw_modifier_degree:SetInt(-3)
                            
                            
                            end
                        else
                            brute.yaw_status = "DEFAULT"
                        end
                    elseif(data.id ~= nil) then
                        brute.yaw_status = "DEFAULT"
                        if(ui.dormant_option:GetInt() == 0) then
                            
                            if(ui.dormant_switch:GetBool()) then
                                ref_fake_options:SetInt(dormat_data[1])
                                ref_yaw_modifier:SetInt(dormat_data[2])
                                ref_yaw_modifier_degree:SetInt(dormat_data[3])
                                notdormant = false
                            end


                        elseif(ui.dormant_option:GetInt() == 1) then
                            if(ui.dormant_switch:GetBool()) then
                                ref_yaw_modifier:SetInt(dormat_data[2])
                                ref_yaw_modifier_degree:SetInt(dormat_data[3])
                                notdormant = false
                            end
                        

                        end
                        if(ui.dormant_switch:GetBool() == false) then  

                            if(ui.dormant_option:GetInt() == 0 and dormantoff == true) then
                                
                                ref_fake_options:SetInt(dormat_data[1])
                                ref_yaw_modifier:SetInt(dormat_data[2])
                                ref_yaw_modifier_degree:SetInt(dormat_data[3])
                                dormantoff = false
                            elseif(ui.dormant_option:GetInt() == 1 and dormantoff == true) then
                                ref_yaw_modifier:SetInt(dormat_data[2])
                                ref_yaw_modifier_degree:SetInt(dormat_data[3])
                                dormantoff = false
    
                            end
                        end
--["..brute.misses.."]
                        if(brute.shootermisses >= 1)then
                            brute.yaw_status = "INDEXED"
                            if (clock < 10) then
                                ref_yaw_add:SetInt(-3)
                            elseif (clock > 10 and clock < 25)then

                                ref_yaw_add:SetInt(3)
                            elseif( clock >25 and clock <40) then
                                ref_yaw_add:SetInt(3)
                            elseif (clock > 40)then

                                ref_yaw_add:SetInt(-3)
                            end
                            if(ui.dormant_option:GetInt() == 0) then
                                
                                if(ui.dormant_switch:GetBool()) then
                                    ref_fake_options:SetInt(dormat_data[1])
                                    ref_yaw_modifier:SetInt(dormat_data[2])
                                    ref_yaw_modifier_degree:SetInt(dormat_data[3])
                                    notdormant = false
                                end


                            elseif(ui.dormant_option:GetInt() == 1) then
                                if(ui.dormant_switch:GetBool()) then
                                    ref_yaw_modifier:SetInt(dormat_data[2])
                                    ref_yaw_modifier_degree:SetInt(dormat_data[3])
                                    notdormant = false
                                end
                            

                            end
           -- ["..brute.misses.."]                 
                        elseif(brute.shootermisses == 3 )then
                            brute.yaw_status = "INDEXED"
                            if (clock < 10) then
                                ref_yaw_add:SetInt(-8)
                            elseif (clock > 10 and clock < 25)then

                                ref_yaw_add:SetInt(-5)
                            elseif( clock >25 and clock <40) then
                                ref_yaw_add:SetInt(8)
                            elseif (clock > 40)then

                                ref_yaw_add:SetInt(5)
                            end
                            if(ui.dormant_option:GetInt() == 0) then
                                
                                if(ui.dormant_switch:GetBool()) then
                                    ref_fake_options:SetInt(dormat_data[1])
                                    ref_yaw_modifier:SetInt(dormat_data[2])
                                    ref_yaw_modifier_degree:SetInt(dormat_data[3])
                                    notdormant = false
                                end


                            elseif(ui.dormant_option:GetInt() == 1) then
                                if(ui.dormant_switch:GetBool()) then
                                    ref_yaw_modifier:SetInt(dormat_data[2])
                                    ref_yaw_modifier_degree:SetInt(dormat_data[3])
                                    notdormant = false
                                end
                            

                            end
                            -- ["..brute.misses.."]
                        elseif(brute.shootermisses > 3)then
                            brute.yaw_status = "INDEXED"
                            ref_yaw_add:SetInt(25)

                            if(ui.dormant_option:GetInt() == 0) then
                                
                                if(ui.dormant_switch:GetBool()) then
                                    ref_fake_options:SetInt(dormat_data[1])
                                    ref_yaw_modifier:SetInt(dormat_data[2])
                                    ref_yaw_modifier_degree:SetInt(dormat_data[3])
                                    notdormant = false
                                end


                            elseif(ui.dormant_option:GetInt() == 1) then
                                if(ui.dormant_switch:GetBool()) then
                                    ref_yaw_modifier:SetInt(dormat_data[2])
                                    ref_yaw_modifier_degree:SetInt(dormat_data[3])
                                    notdormant = false
                                end
                        

                            end
                        end 
                    
                        
                    end
                else
         
                    if(has_killed == true) then
                        distortion = (math.random(-5,5))
                        desync_amount = brute.playermode + distortion
                        aa_base(desync_amount, 0, false)
                        brute.yaw_status = "FLICK"
                        -- status == flicker
                        if(clock == 0) then
                            ref_yaw_add:SetInt(-17)
                        elseif(clock == 1)then

                            ref_yaw_add:SetInt(17)
                        elseif(clock == 2) then
                            ref_yaw_add:SetInt(-17)
                        elseif (clock == 3)then

                            ref_yaw_add:SetInt(17)
                        end
                    end
                    
                end 
                
                ref_fake_options:SetBool(3,false)
            
                -- if(ui.freestand_jitter:GetBool()) then
                --     if info.side == nil then
                --         ref_inverter:SetBool(true)
                --         ref_fake_options:SetBool(1,true)
                --         ref_freestanding:SetInt(0)
                --     elseif info.side == 0 then
                --         ref_freestanding:SetInt(1)
                --         ref_inverter:SetBool(false)
                --         ref_fake_options:SetBool(1,false)
        
                --     elseif info.side == 1 then
                --         ref_fake_options:SetBool(1,false)
                --         ref_freestanding:SetInt(1)
                --         ref_inverter:SetBool(true)
                --     elseif info.side == 2 then
                --         ref_fake_options:SetBool(1,false)
                --         ref_inverter:SetBool(true)
                --         ref_freestanding:SetInt(0)
                --     end
                if(ui.freestanding_mode:GetInt() == 1) then
                    if info.side == nil then
                        should_invert = true
                        if(should_invert == true) then
                            ref_inverter:SetBool(true)
                            should_invert = false
                        end
                        -- ref_fake_options:SetBool(1,true)
                        ref_freestanding:SetInt(0)
                    elseif info.side == 0 then
                        if(should_invert == false) then
                            ref_inverter:SetBool(false)
                            should_invert = true
                        elseif(should_invert == true) then
                            ref_inverter:SetBool(true)
                            should_invert = false
                        end
                        ref_freestanding:SetInt(1)
                        
                        -- ref_fake_options:SetBool(1,false)
        
                    elseif info.side == 1 then
                        -- ref_fake_options:SetBool(1,false)
                        ref_freestanding:SetInt(1)
                        ref_inverter:SetBool(true)
                    elseif info.side == 2 then
                        -- ref_fake_options:SetBool(1,false)
                        ref_inverter:SetBool(true)
                        ref_freestanding:SetInt(0)
                    end
                elseif(ui.freestanding_mode:GetInt() == 2) then
                    if info.side == nil then
                        ref_inverter:SetBool(true)
                        -- ref_fake_options:SetBool(1,true)
                        ref_freestanding:SetInt(0)
                    elseif info.side == 0 then
                        ref_freestanding:SetInt(2)
                        ref_inverter:SetBool(false)
                        -- ref_fake_options:SetBool(1,false)
        
                    elseif info.side == 1 then
                        -- ref_fake_options:SetBool(1,false)
                        ref_freestanding:SetInt(2)
                        ref_inverter:SetBool(true)
                    elseif info.side == 2 then
                        -- ref_fake_options:SetBool(1,false)
                        ref_inverter:SetBool(true)
                        ref_freestanding:SetInt(0)
                    end
                end
            elseif(ui.aa_modes:GetInt() == 2) then
                --rotation\
                
                if has_killed == nil or has_killed == false then
                    dormantoff = true
                    if(data.id == nil) then
                        if(ui.dormant_switch:GetBool()) then    
                            if(ui.dormant_option:GetInt() == 0) then
                                brute.yaw_status = "JITTER"
                                notdormant = true
                                ref_fake_options:SetInt(2)
                                ref_yaw_modifier:SetInt(1)
                                ref_yaw_modifier_degree:SetInt(-10)
                            
                            elseif(ui.dormant_option:GetInt() == 1) then
                                brute.yaw_status = "OFFENCE"
                                if(ref_fake_options:GetInt() == 2) then
                                    ref_fake_options:SetInt(0)
                                end
                                notdormant = true
                                ref_yaw_modifier:SetInt(2)
                                ref_yaw_modifier_degree:SetInt(-3)
                            
                            
                            end
                        else
                            brute.yaw_status = "ROTATION"
                        end
                    elseif(data.id ~= nil) then
                        brute.yaw_status = "ROTATION"

                        if(ui.dormant_switch:GetBool()) then

                            if(ui.dormant_option:GetInt() == 0) then
                                
                                ref_fake_options:SetInt(dormat_data[1])
                                ref_yaw_modifier:SetInt(4)
                                ref_yaw_modifier_degree:SetInt(31)
                                notdormant = false
                            elseif(ui.dormant_option:GetInt() == 1) then
                                ref_yaw_modifier:SetInt(4)
                                ref_yaw_modifier_degree:SetInt(31)
                                notdormant = false
                            end
                        else
                            if(ui.dormant_option:GetInt() == 0 and dormantoff == true) then
                                
                                ref_fake_options:SetInt(dormat_data[1])
                                ref_yaw_modifier:SetInt(4)
                                ref_yaw_modifier_degree:SetInt(31)
                                dormantoff = false
                            elseif(ui.dormant_option:GetInt() == 1 and dormantoff == true) then
                                ref_yaw_modifier:SetInt(4)
                                ref_yaw_modifier_degree:SetInt(31)
                                dormantoff = false
    
                            end
                        end
-- ["..brute.misses.."]
                        if(brute.shootermisses >= 1)then
                            brute.yaw_status = "INDEXED"
                            if (clock < 10) then
                                ref_yaw_add:SetInt(-3)
                            elseif (clock > 10 and clock < 25)then

                                ref_yaw_add:SetInt(3)
                            elseif( clock >25 and clock <40) then
                                ref_yaw_add:SetInt(3)
                            elseif (clock > 40)then

                                ref_yaw_add:SetInt(-3)
                            end
                            if(ui.dormant_option:GetInt() == 0) then
                                
                                if(ui.dormant_switch:GetBool()) then
                                    ref_fake_options:SetInt(dormat_data[1])
                                    ref_yaw_modifier:SetInt(4)
                                    ref_yaw_modifier_degree:SetInt(31)
                                    notdormant = false
                                end


                            elseif(ui.dormant_option:GetInt() == 1) then
                                if(ui.dormant_switch:GetBool()) then
                                    ref_yaw_modifier:SetInt(4)
                                    ref_yaw_modifier_degree:SetInt(31)
                                    notdormant = false
                                end
                            

                            end
                            -- ["..brute.misses.."]
                        elseif(brute.shootermisses == 3 )then
                            brute.yaw_status = "INDEXED"
                            if (clock < 10) then
                                ref_yaw_add:SetInt(-8)
                            elseif (clock > 10 and clock < 25)then

                                ref_yaw_add:SetInt(-5)
                            elseif( clock >25 and clock <40) then
                                ref_yaw_add:SetInt(8)
                            elseif (clock > 40)then

                                ref_yaw_add:SetInt(5)
                            end
                            if(ui.dormant_option:GetInt() == 0) then
                                
                                if(ui.dormant_switch:GetBool()) then
                                    ref_fake_options:SetInt(dormat_data[1])
                                    ref_yaw_modifier:SetInt(dormat_data[2])
                                    ref_yaw_modifier_degree:SetInt(dormat_data[3])
                                    notdormant = false
                                end


                            elseif(ui.dormant_option:GetInt() == 1) then
                                if(ui.dormant_switch:GetBool()) then
                                    ref_yaw_modifier:SetInt(4)
                                    ref_yaw_modifier_degree:SetInt(31)
                                    notdormant = false
                                end
                            

                            end
                            -- ["..brute.misses.."]
                        elseif(brute.shootermisses > 3)then
                            brute.yaw_status = "INDEXED"
                            ref_yaw_add:SetInt(25)

                            if(ui.dormant_option:GetInt() == 0) then
                                
                                if(ui.dormant_switch:GetBool()) then
                                    ref_fake_options:SetInt(dormat_data[1])
                                    ref_yaw_modifier:SetInt(4)
                                    ref_yaw_modifier_degree:SetInt(31)
                                    notdormant = false
                                end


                            elseif(ui.dormant_option:GetInt() == 1) then
                                if(ui.dormant_switch:GetBool()) then
                                    ref_yaw_modifier:SetInt(4)
                                    ref_yaw_modifier_degree:SetInt(31)
                                    notdormant = false
                                end
                        

                            end
                        end 
                    
                        
                    end
                else
         
                    if(has_killed == true) then
                        distortion = (math.random(-5,5))
                        desync_amount = brute.playermode + distortion
                        aa_base(desync_amount, 0, false)
                        brute.yaw_status = "FLICK"
                        -- status == flicker
                        if(clock == 0) then
                            ref_yaw_add:SetInt(-17)
                        elseif(clock == 1)then

                            ref_yaw_add:SetInt(17)
                        elseif(clock == 2) then
                            ref_yaw_add:SetInt(-17)
                        elseif (clock == 3)then

                            ref_yaw_add:SetInt(17)
                        end
                    end
                    
                end 
                
                ref_fake_options:SetBool(3,false)
                -- if(ui.freestand_jitter:GetBool()) then
                --     if info.side == nil then
                --         ref_inverter:SetBool(true)
                --         ref_fake_options:SetBool(1,true)
                --         ref_freestanding:SetInt(0)
                --     elseif info.side == 0 then
                --         ref_freestanding:SetInt(1)
                --         ref_inverter:SetBool(false)
                --         ref_fake_options:SetBool(1,false)
        
                --     elseif info.side == 1 then
                --         ref_fake_options:SetBool(1,false)
                --         ref_freestanding:SetInt(1)
                --         ref_inverter:SetBool(true)
                --     elseif info.side == 2 then
                --         ref_fake_options:SetBool(1,false)
                --         ref_inverter:SetBool(true)
                --         ref_freestanding:SetInt(0)
                --     end
                if(ui.freestanding_mode:GetInt() == 1) then
                    if info.side == nil then
                        should_invert = true
                        if(should_invert == true) then
                            ref_inverter:SetBool(true)
                            should_invert = false
                        end
                        -- ref_fake_options:SetBool(1,true)
                        ref_freestanding:SetInt(0)
                    elseif info.side == 0 then
                        if(should_invert == false) then
                            ref_inverter:SetBool(false)
                            should_invert = true
                        elseif(should_invert == true) then
                            ref_inverter:SetBool(true)
                            should_invert = false
                        end
                        ref_freestanding:SetInt(1)
                        
                        -- ref_fake_options:SetBool(1,false)
        
                    elseif info.side == 1 then
                        -- ref_fake_options:SetBool(1,false)
                        ref_freestanding:SetInt(1)
                        ref_inverter:SetBool(true)
                    elseif info.side == 2 then
                        -- ref_fake_options:SetBool(1,false)
                        ref_inverter:SetBool(true)
                        ref_freestanding:SetInt(0)
                    end
                elseif(ui.freestanding_mode:GetInt() == 2) then
                    if info.side == nil then
                        ref_inverter:SetBool(true)
                        -- ref_fake_options:SetBool(1,true)
                        ref_freestanding:SetInt(0)
                    elseif info.side == 0 then
                        ref_freestanding:SetInt(2)
                        ref_inverter:SetBool(false)
                        -- ref_fake_options:SetBool(1,false)
        
                    elseif info.side == 1 then
                        -- ref_fake_options:SetBool(1,false)
                        ref_freestanding:SetInt(2)
                        ref_inverter:SetBool(true)
                    elseif info.side == 2 then
                        -- ref_fake_options:SetBool(1,false)
                        ref_inverter:SetBool(true)
                        ref_freestanding:SetInt(0)
                    end
                end
                ref_on_shot:SetInt(3)
                handle_fake_yaw(info.side,target,me)
    
            end
           
            

            if(ui.fakelag_switch:GetBool()) then
                if(ui.fakelag_mode:GetInt() == 0) then -- dynamic
                    if(data.id == nil or ref_fd:GetBool()) then
                        ref_fakelag_limit:SetInt(14)
                        ref_fakelag_rand:SetInt(0)
                        brute.fl_mode = "Dynamic"
                    elseif brute.misses >= 1 and brute.tick_miss < 150 then
                        ref_fakelag_limit:SetInt(14)
                        ref_fakelag_rand:SetInt(0)
                        brute.fl_mode = "Fluctuate"
                        local random1 = math.random(11, 14)
                        local random2 = math.random(9, 14)
                        local random3 = math.random(3, 14)
                        local random4 = math.random(6, 14)
                        if(clock == 0) then
                            ref_fakelag_limit:SetInt(random1)
                        elseif(clock == 1) then
                            ref_fakelag_limit:SetInt(random2)
                        elseif(clock == 2) then
                            ref_fakelag_limit:SetInt(random3)                                                                                                                                                                                                                                                                                                                                                                                                                               
                        elseif(clock == 3) then
                            ref_fakelag_limit:SetInt(random4)
                        end
                    else

                        local player = g_EntityList:GetClientEntity(g_EngineClient:GetLocalPlayer()):GetPlayer()
                        local local_pos = player:GetEyePosition()                      
                        local extrapolated_pos = extrapolate_pos(local_pos, player, 17)

                        local player_pos = data.id:GetPlayer():GetHitboxCenter(0) 
                        local player_pos_2 = data.id:GetPlayer():GetHitboxCenter(4) 
                        local player_pos_3 = data.id:GetPlayer():GetHitboxCenter(2)  

                        if choke_cycle == 1 then
                            ref_fakelag_limit:SetInt(1)
                            ref_fakelag_rand:SetInt(0)
                            brute.fl_mode = "Minimal"
                            choke_cycle = 2
                        elseif trace_positions(player_pos,player_pos_2,player_pos_3, player) then
                            if choke_cycle ~= 2 then
                                choke_cycle = 1
                            else
                                ref_fakelag_limit:SetInt(14)
                                ref_fakelag_rand:SetInt(0)
                                brute.fl_mode = "Maximum"
                            end
                        else
                            choke_cycle = 0
                            ref_fakelag_limit:SetInt(14)
                            ref_fakelag_rand:SetInt(14)
                            brute.fl_mode = "Dynamic"
                        end
                    end   
                elseif(ui.fakelag_mode:GetInt() == 1) then -- fluctuate
                    local random1 = 0
                    local random2 = 0
                    local used = false
                
                    if used then 
                        random1 = math.random(1, ui.fakelag_fluc_amount:GetInt())
                        used = false
                    else
                        random1 = math.random(1, ui.fakelag_fluc_amount:GetInt())
                        used = true
                    end
                
                    if random1 == 1 then 
                        ref_fakelag_limit:SetInt(3)
                        ref_fakelag_rand:SetInt(0)
                    else
                        ref_fakelag_limit:SetInt(14)
                        ref_fakelag_rand:SetInt(3)
                    end 
                end
            end
        
            if(ui.Jitter_legs_switch:GetBool())then--jitter legs
                local legs_int = math.random(0, 10)
                if legs_int <= 4 then
                  ref_legs:SetInt(1)
                
                elseif(legs_int >= 5 and legs_int < 7) then
                    ref_legs:SetInt(2)
                elseif(legs_int >= 7) then
                    ref_legs:SetInt(0)
                end
            end
            if(ui.aa_multimodes:GetBool(2) and get_delta(me) >= 25)then--avoid high delta
                delta_string = get_delta(me)
                highdelta = true
                antiaim.OverrideLimit(22)
            else
                if(highdelta == true) then
                    ref_limit_right:SetInt(60)
                    ref_limit_left:SetInt(60)
                    highdelta = false 
                end
            end
    

        end
        if(health == 0 and notdormant == true)then
            ref_fake_options:SetInt(dormat_data[1])
            ref_yaw_modifier:SetInt(dormat_data[2])
            ref_yaw_modifier_degree:SetInt(dormat_data[3])
            notdormant = false
        end
        if me == nil then
            return nil
        end

    end
    



    function disable_fakelag_knife()
        local me = g_EntityList:GetClientEntity(g_EngineClient:GetLocalPlayer()):GetPlayer()
        local wpn = me:GetActiveWeapon():GetClassName()
        if(ui.fakelag_disable:GetBool()) then
            if wpn == "CKnife" then
                fakelagdisable = true
                ref_fakelag:SetBool(false)

            else
                if(fakelagdisable == true) then
                    if(ref_fakelag:GetBool() == false) then
                        ref_fakelag:SetBool(true)
                        fakelagdisable = false
                    end
                end
            end
        end
    end
    local dtautostopdata = {
        ref_dt_autostop:GetInt()
    }
    function idealtick_handle() 
        if(ui.idealtick_switch:GetBool()) then
            idealticking = true
            ref_autopeek:SetBool(true)
            ref_dt:SetBool(true)
            ref_dt_autostop:SetBool(0, true)
            ref_dt_autostop:SetBool(1, true)
            if(exploits.GetCharge() == 1) then
                ref_fakelag_limit:SetInt(1)
            else
                ref_fakelag_limit:SetInt(14)
            end
        else
            if(idealticking == true) then
                ref_autopeek:SetBool(false)
                ref_dt:SetBool(false)
                ref_dt_autostop:SetInt(dtautostopdata[1])
                if(ref_fakelag_limit:GetInt() ~= 14) then
                    ref_fakelag_limit:SetInt(14)
                end
                idealticking = false
            end
        end
    end

    function handle_dt()

        local GetNetChannelInfo = g_EngineClient:GetNetChannelInfo()
        local ping = GetNetChannelInfo:GetAvgLatency(0) * 1000
        if(ui.dt_enable_switch:GetBool()) then 
            if(ui.dtmode:GetBool(0)) then
                activedtmode = "Latency"
                if(ping <= 50) then
                    tickbase = "17"
                    exploits.OverrideDoubleTapSpeed(17)
                    g_CVar:FindVar("cl_clock_correction"):SetInt(0)
                    g_CVar:FindVar("cl_clock_correction_adjustment_max_amount"):SetInt(450)
                end
                if(ping >= 60 and ping < 60) then
                    tickbase = "14"
                    exploits.OverrideDoubleTapSpeed(14)
                    g_CVar:FindVar("cl_clock_correction"):SetInt(0)
                    g_CVar:FindVar("cl_clock_correction_adjustment_max_amount"):SetInt(300)
                end
                if(ping >= 60) then
                    tickbase = "13"
                    exploits.OverrideDoubleTapSpeed(13)
                    g_CVar:FindVar("cl_clock_correction"):SetInt(1)
                    g_CVar:FindVar("cl_clock_correction_adjustment_max_amount"):SetInt(200)
                end
            end
            if(ui.dtmode:GetBool(1)) then
                local me = g_EntityList:GetLocalPlayer()
                local health = me:GetProp("m_iHealth")
                if health < 40 then
                    activedtmode = "Vulnerability"
                    if(ui.vul_mode:GetInt() == 0) then -- safe
                        tickbase = "14"
                        exploits.OverrideDoubleTapSpeed(14)
                        g_CVar:FindVar("cl_clock_correction"):SetInt(1)
                        g_CVar:FindVar("cl_clock_correction_adjustment_max_amount"):SetInt(200)
                    elseif(ui.vul_mode:GetInt() == 1) then  --unsafe
                        tickbase = "17"
                        exploits.OverrideDoubleTapSpeed(17)
                        g_CVar:FindVar("cl_clock_correction"):SetInt(0)
                        g_CVar:FindVar("cl_clock_correction_adjustment_max_amount"):SetInt(450)
                    end
                end
            end

        end
    end
    local automddata = {
        ref_v_md:GetInt(), ref_aw_md:GetInt()
    }
    local predicton
    local predicdamge = ""
    function dt_damage_predict()
        local me = g_EntityList:GetLocalPlayer()
        local data = get_target()
        if(ui.dt_prediction_switch:GetBool()) then 
            predicton = true
            if(ref_dt:GetBool())then  

                if(me:GetProp("m_iHealth") > 0)then
                    local player = g_EntityList:GetClientEntity(g_EngineClient:GetLocalPlayer()):GetPlayer()
                    local local_pos = player:GetEyePosition()
                    if(data.id ~= nil)then 
                        if(data.id:GetPlayer():GetProp("m_iHealth") > 0) then 
                            local wpn = me:GetActiveWeapon():GetClassName()
                            if(wpn == "CWeaponSCAR20" or wpn == "CWeaponG3SG1" or wpn == "CDEagle")  then 
                                if local_pos ~= nil then 
                                    local extrapolated_pos = extrapolate_pos(local_pos, player, 24)
                                    local hitbox = data.id:GetPlayer():GetHitboxCenter(2)
                                    if local_pos ~= nil or extrapolated_pos ~= nil then 
                                        local hitboxarray = {1,2,3,4,5,6}
                                        -- local hitbox = data.id:GetPlayer():GetHitboxCenter(v)
                                        local vec_end = extend_vector(hitbox,50,data.yaw)
                                        -- local trace = cheat.FireBullet(player, player:GetEyePosition(), hitbox)
                                        -- local damage = round(trace.damage, 0)
                                        safety_hitboxes = {}
                                        local hitboxesused = {18,17,16,15,14,13,12,11,10,9,8,7,6,5,4,3,2,0}

                                        
                                    

                                        if data.id:GetPlayer():m_iHealth() > 0 and not data.id:GetPlayer():IsTeamMate() and canseeentity(player, data.id:GetPlayer()) then
                                            
                                            --UpdateClientSideAnims(ffi.cast("void***", ffi_helpers.get_entity_address(entity:EntIndex())))
                                            -- for k,v in pairs(safety_hitboxes) do
                                            --     ragebot.ForceHitboxSafety(entity:EntIndex(), v)
                                            -- end
                                            
                                            local biggestdamage = 0
                                            local health = data.id:GetPlayer():GetProp("m_iHealth")
                                            local besthitboxfound = -1
                                            for k,v in pairs(hitboxesused) do
                                                local trace = cheat.FireBullet(player, player:GetEyePosition(), data.id:GetPlayer():GetHitboxCenter(v))
                                                local damage = round(trace.damage, 0)
                                                if damage > biggestdamage then
                                                    biggestdamage = damage
                                                    besthitboxfound = v
                                                end
                                
                                                if damage >= health and damage < 100 then
                                                    predicmode = "default"
                                                    biggestdamage = damage
                                                    besthitboxfound = v
                                                    break
                                                elseif damage >= health / 2 then
                                                    predicmode = "hp/2"
                                                    biggestdamage = health / 2
                                                    besthitboxfound = v
                                                end
                                                
                                            end
                                       
                                            ragebot.ForceHitboxSafety(data.id:EntIndex(), besthitboxfound, 10000)
                                            roundeddamage = round(biggestdamage, 0)
                                            ref_v_md:SetInt(roundeddamage)
                                            ref_aw_md:SetInt(roundeddamage)
                                            best_hitbox[data.id:EntIndex()] = besthitboxfound
                                            best_damage[data.id:EntIndex()] = biggestdamage
                                           
                                            -- if(biggestdamage >= enemyhealth and enemyhealth < 100) then
                                            --     predicdamge = biggestdamage
                                            --     -- print("predicting ".. enemyhealth.. " Damage ".. data.id:GetPlayer():GetName())
                                            --     ref_v_md:SetInt(predicdamge)
                                            --     ref_aw_md:SetInt(predicdamge)
                                            -- elseif(biggestdamage == enemyhealth / 2) then
                                            --     predicdamge = enemyhealth /2
                                            --     -- print("predicting ".. (enemyhealth/2).. " Damage hp/2 "..data.id:GetPlayer():GetName())
                                            --     ref_v_md:SetInt(math.floor(enemyhealth / 2 - 14))
                                            --     ref_aw_md:SetInt(math.floor(enemyhealth / 2 - 10))
                                    
                                            -- elseif(damage <= 0) then
                                            --     ref_v_md:SetInt(automddata[1])
                                            --     ref_aw_md:SetInt(automddata[2])

                                            
                                        else
                                            best_damage[data.id:EntIndex()] = 0
                                            best_hitbox[data.id:EntIndex()] = -1
                                            ref_v_md:SetInt(automddata[1])
                                            ref_aw_md:SetInt(automddata[2]) 
                                        end
                                       
                                        
                                    end
                                end
                            else
                                -- if(predicton == true) then
                                --     ref_v_md:SetInt(automddata[1])
                                --     ref_aw_md:SetInt(automddata[2]) 
                                --     predicton = false
                                -- end
                            end
                                
                        end
                    end
                end
            end
        else
            if(predicton == true) then
                ref_v_md:SetInt(automddata[1])
                ref_aw_md:SetInt(automddata[2]) 
                predicton = false
            end
        end
    end 
    function teleport_zues()
        local me = g_EntityList:GetClientEntity(g_EngineClient:GetLocalPlayer()):GetPlayer()
        local wpn = me:GetActiveWeapon():GetClassName()
        if(ui.zues_dt_enable_switch:GetBool() == true) then
            if wpn == "CWeaponTaser" then
                ticking = true
                local local_player = g_EntityList:GetClientEntity(g_EngineClient:GetLocalPlayer())
                local origin = local_player:GetProp("DT_BaseEntity", "m_vecOrigin")
                local entities = g_EntityList:GetPlayers()
                if (ref_dt:GetBool() == false) then
                    ref_dt:SetBool(true)
                end
                for i = 1, 64 do
                    local entity = g_EntityList:GetClientEntity(i)
                    if entity and entity:GetPlayer():GetProp("m_iHealth") > 0 and not entity:GetPlayer():IsTeamMate() then
                        local distance = origin:DistTo(entity:GetProp("DT_BaseEntity", "m_vecOrigin"))
                        if(distance <= 200 and ref_dt:GetBool() == true) then
                            exploits.ForceTeleport()
                            dtthing = false
                        end
                        if(dtthing == false) then 
                            ref_dt:SetBool(false)
                            dtthing = true
                        end
                    end
                    
                end
            else
                if(ticking == true) then
                    if(ref_dt:GetBool() == true) then
                        ref_dt:SetBool(false)
                        ticking = false
                    end
                end
            end
        end
    
    
    end
    bruteimpact = function(e)
    
        local me = g_EntityList:GetLocalPlayer()
        local health = me:GetProp("DT_BasePlayer", "m_iHealth")

        -- Since bullet_impact gets triggered even while we're dead having this check is a good idea.
        if health == 0 then return end
        if e:GetName() == "bullet_impact" then 
            local user_x = e:GetInt("x", -1)
            local user_y = e:GetInt("y", -1)
            local user_z = e:GetInt("z", -1)

            local user_id = e:GetInt("userid", -1)
            local shooter = g_EntityList:GetClientEntity(g_EngineClient:GetPlayerForUserId(user_id))
            if(shooter == nil)then return end

            if shooter:GetPlayer():IsTeamMate() == true or shooter:IsDormant() == true then return end
            local hitbox = shooter:GetPlayer():GetHitboxCenter(0)
            local pos = me:GetProp("DT_BaseEntity", "m_vecOrigin")

            local shooterpos = shooter:GetPlayer():GetProp("DT_BaseEntity", "m_vecOrigin")
            local distance = pos:DistTo(shooterpos)
            local dist = ((user_y - shooterpos.y)*hitbox.x - (user_x - shooterpos.x)*hitbox.y + user_x*shooterpos.y - user_y*shooterpos.x) / math.sqrt((user_y-shooterpos.y)^2 + (user_x-shooterpos.x)^2)
            if math.abs(distance) <= 300 and g_GlobalVars.curtime - brute.last_miss > 0.055 then
                brute.last_miss = g_GlobalVars.curtime
                

                if brute.shootermisses == 0 then
                    
                    brute.misses = brute.misses + 1
                    brute.shootermisses = brute.shootermisses + 1
                elseif brute.shootermisses >= 5 then
                    brute.shootermisses = 1
                    brute.misses = brute.misses + 1
                else
                    brute.misses = brute.misses + 1
                    brute.shootermisses = brute.shootermisses + 1

                end
                print("Miss "..brute.shootermisses.. " | Total Indexed "..brute.misses)

            end
        end
       
    
        -- Distance calculations can sometimes bug when the entity is dormant hence the 2nd check.
    
      
        
        -- 125 is our miss detection radius and the 2nd check is to avoid adding more than 1 miss for a singular bullet (bullet_impact gets called mulitple times per shot).
        
        -- print("total right misses "..brute.right_misses)
        -- print("total left misses "..brute.left_misses)
    end

    function legit_aa(cmd) 
        local data = get_target()
        local localplayer = g_EntityList:GetClientEntity(g_EngineClient:GetLocalPlayer())
        local player = localplayer:GetPlayer()
        if player == nil then return end
        local local_origin = localplayer:GetProp("DT_BaseEntity", "m_vecOrigin")
        local disable_aa = false
    
        if(ui.aa_multimodes:GetBool(1)) then
            if (cheat.IsKeyDown(0x45)) then
                yaw_base = true
                ref_fake_options:SetInt(1)
                ref_limit_right:SetInt(60)
                ref_limit_left:SetInt(60)
                ref_yaw_base:SetInt(0)
                ref_aa_pitch:SetInt(0)
                ref_yaw_modifier:SetInt(0)
                ref_yaw_add:SetInt(0)
            else
                if(yaw_base == true) then
                    ref_yaw_base:SetInt(legit_aa_data[1])
                    ref_aa_pitch:SetInt(legit_aa_data[2])
                    yaw_base = false
                end

            end

            local entities = {}
            table.insert(entities, g_EntityList:GetEntitiesByClassID(97))
            table.insert(entities, g_EntityList:GetEntitiesByClassID(129))
            table.insert(entities, g_EntityList:GetEntitiesByClassID(46))-- Deagle
            table.insert(entities, g_EntityList:GetEntitiesByClassID(1))-- AK
            table.insert(entities, g_EntityList:GetEntitiesByClassID(231)) -- aug
            table.insert(entities, g_EntityList:GetEntitiesByClassID(232)) -- awp
            table.insert(entities, g_EntityList:GetEntitiesByClassID(234)) -- Bizon
            table.insert(entities, g_EntityList:GetEntitiesByClassID(239)) -- famas
            table.insert(entities, g_EntityList:GetEntitiesByClassID(240)) -- fiveseven
            table.insert(entities, g_EntityList:GetEntitiesByClassID(241)) -- G3SG1
            table.insert(entities, g_EntityList:GetEntitiesByClassID(242)) -- GALIL
            table.insert(entities, g_EntityList:GetEntitiesByClassID(243)) -- galil
            table.insert(entities, g_EntityList:GetEntitiesByClassID(244)) --glock
            table.insert(entities, g_EntityList:GetEntitiesByClassID(245)) --usps
            table.insert(entities, g_EntityList:GetEntitiesByClassID(248)) --m4a1
            table.insert(entities, g_EntityList:GetEntitiesByClassID(249)) -- mac10
            table.insert(entities, g_EntityList:GetEntitiesByClassID(250)) -- mag7
            table.insert(entities, g_EntityList:GetEntitiesByClassID(251)) --mp5
            table.insert(entities, g_EntityList:GetEntitiesByClassID(252)) -- mp7
            table.insert(entities, g_EntityList:GetEntitiesByClassID(253)) -- mp9
            table.insert(entities, g_EntityList:GetEntitiesByClassID(254)) -- negev
            table.insert(entities, g_EntityList:GetEntitiesByClassID(256)) -- p228
            table.insert(entities, g_EntityList:GetEntitiesByClassID(257)) -- p250
            table.insert(entities, g_EntityList:GetEntitiesByClassID(258)) -- p90
            table.insert(entities, g_EntityList:GetEntitiesByClassID(260)) -- scar20
            table.insert(entities, g_EntityList:GetEntitiesByClassID(261)) -- scout
            table.insert(entities, g_EntityList:GetEntitiesByClassID(262)) -- sg550
            table.insert(entities, g_EntityList:GetEntitiesByClassID(264)) -- sg556
            table.insert(entities, g_EntityList:GetEntitiesByClassID(266)) -- ssg08
            table.insert(entities, g_EntityList:GetEntitiesByClassID(268)) -- tec9
            table.insert(entities, g_EntityList:GetEntitiesByClassID(269)) -- tmp
            table.insert(entities, g_EntityList:GetEntitiesByClassID(270)) -- ump45
            table.insert(entities, g_EntityList:GetEntitiesByClassID(246)) -- m249
            table.insert(entities, g_EntityList:GetEntitiesByClassID(271)) -- usp
            table.insert(entities, g_EntityList:GetEntitiesByClassID(143)) -- usp

            -- local doors = g_EntityList:GetEntitiesByClassID(143)
            -- local final_dist = math.huge
            -- for k, v in pairs(doors) do 
            --     local curr_dist = math.abs(local_player:GetRenderOrigin():Length() - v:GetRenderOrigin():Length()) 
            --     if  curr_dist <= final_dist then final_dist = curr_dist end
            -- end

            for i in pairs(entities) do
                for j = 1, #entities[i] do
                    if(local_origin:DistTo(entities[i][j]:GetProp("DT_BaseEntity", "m_vecOrigin")) < 90) then
                        disable_aa = true
                    end
                end
            end
            if(player:GetActiveWeapon():GetClassName() == "CC4") then
                disable_aa = true  
            end
            
        
            if (disable_aa == false) then
                g_EngineClient:ExecuteClientCmd("-use")
                g_EngineClient:ExecuteClientCmd("unbind e")
            elseif(disable_aa == true) then
                g_EngineClient:ExecuteClientCmd("bind e +use")
            end    
    
        end
    end
    local max_ticks = 0

    --[[
        Visual
    ]]

    local verdana = g_Render:InitFont("Verdana", 13)
    local verdanadt = g_Render:InitFont("Verdana", 12)
    local verdanaOTHER = g_Render:InitFont("Verdana", 10)
    local small = g_Render:InitFont("smalle", 10)
    local arrowfont = g_Render:InitFont("Acta Symbols W95 Arrows",30)
    local pos1, pos2 = Vector2.new(400, 50), Vector2.new(500, 150)
    local x, y, w, h = 906, 1029, 20, 10
    local x2, y2, w2, h2 = 500, 200, 200, 200
    function watermark() 
        
        local me = g_EntityList:GetLocalPlayer()
        local health = me:GetProp("m_iHealth")
        
        local screen = g_EngineClient:GetScreenSize()
        pos = {
            screen.x/2,
            screen.y-50
        }
        if(ui.watermark_style:GetInt() == 0) then -- main
            
            local nexttext = "C&A"
            local GetNetChannelInfo = g_EngineClient:GetNetChannelInfo()
            local ping = GetNetChannelInfo:GetLatency(0)
            
            local text1 = "C&A | " .. info.username .. " | " .. round(ping*1000,0).."MS | " .. info.version .. ""
        
            ts = g_Render:CalcTextSize(text1, 10,small)
        
            clr_main = ui.colors.main:GetColor()
            clr_sec = ui.colors.other:GetColor()

            x, y = input:handle_dragging(2, x, y, ts.x + 10, ts.y +3)


            g_Render:BoxFilled(Vector2.new(x, y), Vector2.new(x + ts.x + 10, y+ ts.y +3), Color.new(0,0,0,0.5))
            g_Render:BoxFilled(Vector2.new(x, y), Vector2.new(x + ts.x + 10,y - 1), clr_main)
            g_Render_TextOutline(text1, Vector2.new(x + ts.x + 5 - ts.x, y + 1), Color.new(1,1,1,1), 10, small)
            g_Render:GradientBoxFilled(Vector2.new(x ,y+ts.y + 6), Vector2.new(x + ts.x/2, y+ ts.y +7), Color.new(clr_sec:r(),clr_sec:g(),clr_sec:b(),0), clr_sec, Color.new(clr_sec:r(),clr_sec:g(),clr_sec:b(),0), clr_sec)
            g_Render:GradientBoxFilled(Vector2.new(x +ts.x/2,y+ts.y + 6), Vector2.new(x + ts.x + 10, y+ ts.y +7), clr_sec, Color.new(clr_sec:r(),clr_sec:g(),clr_sec:b(),0), clr_sec, Color.new(clr_sec:r(),clr_sec:g(),clr_sec:b(),0))
        elseif(ui.watermark_style:GetInt() == 1)  then-- DT
            local chrg = exploits.GetCharge()
            if(ui.dt_enable_switch:GetBool()) then

                local nexttext = "C&A"
                local GetNetChannelInfo = g_EngineClient:GetNetChannelInfo()
                local ping = GetNetChannelInfo:GetLatency(0)
                
                local text1 = "C&Adt [" .. activedtmode .. "]  | tickbase:" .. tickbase .. ""
            
                ts = g_Render:CalcTextSize(text1, 10,small)
            
                clr_main = ui.colors.main:GetColor()
                clr_sec = ui.colors.other:GetColor()

                x, y = input:handle_dragging(2, x, y, ts.x + 10, ts.y +3)
                if(ref_dt:GetBool()) then

                    if exploits.GetCharge() ~= 1 and health > 0 then
                        g_Render:BoxFilled(Vector2.new(x, y), Vector2.new(x + ts.x + 10, y+ ts.y +3), Color.new(0,0,0,0.5))
                        g_Render:BoxFilled(Vector2.new(x, y), Vector2.new(x + chrg*80,y - 1), clr_main)
                        g_Render:BoxFilled(Vector2.new(x, y), Vector2.new(x + ts.x + 10,y - 1), Color.new(0,0,0,0.5))
                        g_Render_TextOutline(text1, Vector2.new(x + ts.x + 5 - ts.x, y + 1), Color.new(1,1,1,1), 10, small)
                    else
                        g_Render:BoxFilled(Vector2.new(x, y), Vector2.new(x + ts.x + 10, y+ ts.y +3), Color.new(0,0,0,0.5))
                        g_Render:BoxFilled(Vector2.new(x, y), Vector2.new(x + ts.x + 10,y - 1), clr_main)
                        g_Render_TextOutline(text1, Vector2.new(x + ts.x + 5 - ts.x, y + 1), Color.new(1,1,1,1), 10, small)
                    end
                else
                    g_Render:BoxFilled(Vector2.new(x, y), Vector2.new(x + ts.x + 10, y+ ts.y +3), Color.new(0,0,0,0.5))
                    g_Render:BoxFilled(Vector2.new(x, y), Vector2.new(x + ts.x + 10,y - 1), clr_main)
                    g_Render_TextOutline(text1, Vector2.new(x + ts.x + 5 - ts.x, y + 1), Color.new(1,1,1,1), 10, small)
                end
    

            else
                local nexttext = "C&A"
                local GetNetChannelInfo = g_EngineClient:GetNetChannelInfo()
                local ping = GetNetChannelInfo:GetLatency(0)
                
                local text1 = "C&Adt [Default]  | tickbase: 17"
            
                ts = g_Render:CalcTextSize(text1, 10,small)
            
                clr_main = ui.colors.main:GetColor()
                clr_sec = ui.colors.other:GetColor()

                x, y = input:handle_dragging(2, x, y, ts.x + 10, ts.y +3)

    
                g_Render:BoxFilled(Vector2.new(x, y), Vector2.new(x + ts.x + 10, y+ ts.y +3), Color.new(0,0,0,0.5))
                g_Render:BoxFsilled(Vector2.new(x, y), Vector2.new(x + ts.x + 10,y - 1), clr_main)
                g_Render_TextOutline(text1, Vector2.new(x + ts.x + 5 - ts.x, y + 1), Color.new(1,1,1,1), 10, small)
            end
        end


        -- g_Render:BoxFilled(Vector2.new(pos[1]- ts.x/2 - 5,pos[2] - 2), Vector2.new(pos[1] + ts.x/2 + 5,pos[2]+ ts.y +2), Color.new(0,0,0,0.5))
        -- g_Render:BoxFilled(Vector2.new(pos[1]- ts.x/2 - 5,pos[2] - 2), Vector2.new(pos[1] + ts.x/2 + 5,pos[2] - 1), clr_main)
        -- g_Render_TextOutline(text1,Vector2.new(pos[1]- ts.x/2,pos[2] ),Color.new(1,1,1,1),10,small)
    
        -- g_Render:GradientBoxFilled(Vector2.new(pos[1]- ts.x/2,pos[2]+ts.y + 6), Vector2.new(pos[1],pos[2]+ts.y + 7), Color.new(clr_sec:r(),clr_sec:g(),clr_sec:b(),0), clr_sec, Color.new(clr_sec:r(),clr_sec:g(),clr_sec:b(),0), clr_sec)
        -- g_Render:GradientBoxFilled(Vector2.new(pos[1],pos[2]+ts.y + 6), Vector2.new(pos[1] + ts.x/2,pos[2]+ts.y + 7), clr_sec, Color.new(clr_sec:r(),clr_sec:g(),clr_sec:b(),0), clr_sec, Color.new(clr_sec:r(),clr_sec:g(),clr_sec:b(),0))

    end
    local logdamage = ""
    local logdt = ""
    local debuglogs = function(shot)
        local me = g_EntityList:GetClientEntity(g_EngineClient:GetLocalPlayer()):GetPlayer()
        local health = me:GetProp("m_iHealth")
        if(health <= 0)then return end
        local wpn = me:GetActiveWeapon():GetClassName()
        local data = get_target()
        local entity = g_EntityList:GetClientEntity(shot.target_index)
        local player = entity:GetPlayer()
        if(ui.dt_prediction_log_switch:GetBool() and wpn == "CWeaponSCAR20" or wpn == "CWeaponG3SG1" or wpn == "CDEagle" )then
            if(ref_dt:GetBool() and roundeddamage ~= nil)then  
                coloredPrint(clr_main,"c&a prediction",Color.new(1,1,1,1)," | damage: ".. (roundeddamage).. " | mode: "..predicmode.." | player: "..player:GetName().."\n")
            end
        end
        if(ui.debug_logs:GetBool(2)) then 
            local entity = g_EntityList:GetClientEntity(shot.target_index)
            local player = entity:GetPlayer()
            local reason = ""
            hitbox = "unknown"
            if(shot.reason == 0) then
                if((shot.hitgroup > -1 and shot.hitgroup < 8) or shot.hitgroup == 10) then                    hitbox = hitgroups[shot.hitgroup]
    
                end
        
                
     
                logdamage = "Damage "..shot.damage
                
                if(ref_dt:GetBool()) then
                    if(ui.dt_enable_switch:GetBool()) then
                        logdt = activedtmode
                    else
                        logdt = "Default"
                    end 
                else
                    logdt = "none"               
                end
            end
            
            coloredPrint(clr_main, "c&a",Color.new(1,1,1,1),": Fired at "..player:GetName().. " | "..logdamage.." | DT Mode: "..logdt.. " | Hitbox: "..hitbox.. " | BT ticks: "..shot.backtrack.."\n")         
            -- print("C&A: Fired at "..player:GetName().. " | "..logdamage.." | DT Mode: "..logdt.. " | Hitbox: "..hitbox.. " | BT ticks: "..shot.backtrack)
        end
        
    end

    cheat.RegisterCallback("registered_shot", debuglogs);
    function handle_indicators() 
        local screen = g_EngineClient:GetScreenSize()
        local dt_text_size = g_Render:CalcTextSize("DT", 12)
        local data = get_target()

        local idc_1_text_size = g_Render:CalcTextSize(name, 10)
        local idc_2_text_size = g_Render:CalcTextSize(name, 13)
    
        local x = screen.x / 2
        local y = screen.y / 2
        pos = {
            screen.x/2,
            screen.y-50
        }
        local real_rotation = antiaim.GetCurrentRealRotation()
        local desync_rotation = antiaim.GetFakeRotation()
        local max_desync_delta = antiaim.GetMaxDesyncDelta()
        local min_desync_delta = antiaim.GetMinDesyncDelta()
        local maincolor = ui.colors.main:GetColor()
        local secondarycolor = ui.colors.other:GetColor()
        local dtactivecolor = ui.colors.dt:GetColor()
        local arrowactive = ui.colors.arrow:GetColor()
        local arrowinactive = ui.colors.arrowinactive:GetColor()

        local desync_delta = real_rotation - desync_rotation
        if (desync_delta > max_desync_delta) then
            desync_delta = max_desync_delta
        elseif (desync_delta < min_desync_delta) then
            desync_delta = min_desync_delta
        end
        local dtpos = Vector2.new((screen.x/2)-(dt_text_size.x/2),screen.y/2+(dt_text_size.y/2)+40)
        local idc_1_mid_pos = Vector2.new((screen.x/2)-(idc_1_text_size.x/2),screen.y/2+(idc_1_text_size.y/2) +5)
        local idc_2_mid_pos = Vector2.new((screen.x/2)-(idc_2_text_size.x/2),screen.y/2+(idc_2_text_size.y/2) +25)
        
        if(ui.indicators_check:GetBool()) then
            if(ui.indicator_style:GetInt() == 0) then
                local player = g_EntityList:GetLocalPlayer()
                t_size1 = g_Render:CalcTextSize("C & A", 12)
                
                g_Render:Text("C & A", Vector2:new(screen.x/2 - t_size1.x/2,screen.y/2 - t_size1.y/2 + 20), maincolor,12,true)
                dttext = "DT"

      

                bottom = brute.yaw_status

                t_size2 = g_Render:CalcTextSize(bottom, 10,small)
                if(bottom == "JITTER") then
                    if(ref_dt:GetBool()) then
                        if exploits.GetCharge() ~= 1  then
                            g_Render_TextOutline(dttext,Vector2:new(screen.x/2 +9 - t_size2.x/2,screen.y/2 + t_size1.y/2 + 30),Color.new(255,255,255,0.3),10,small)
                            -- g_Render:Text("DT",Vector2:new(screen.x/2 + 13 - t_size2.x/2,screen.y/2 + t_size1.y/2 + 30),Color.new(255,255,255,0.3),10,small,true)
                        else
                            g_Render_TextOutline(dttext,Vector2:new(screen.x/2 + 9 - t_size2.x/2,screen.y/2 + t_size1.y/2 + 30),secondarycolor,10,small)
                            -- g_Render:Text("DT",Vector2:new(screen.x/2 + 13 - t_size2.x/2,screen.y/2 + t_size1.y/2 + 30),secondarycolor,10,small,true)
                        end
                        
                    else
                        g_Render_TextOutline(dttext,Vector2:new(screen.x/2 + 9 - t_size2.x/2,screen.y/2 + t_size1.y/2 + 30),Color.new(255,255,255,0.3),10,small)
                        -- g_Render:Text("DT",Vector2:new(screen.x/2 + 13 - t_size2.x/2,screen.y/2 + t_size1.y/2 + 30),secondarycolor,10,small,true)
                    end
                    g_Render_TextOutline(bottom,Vector2:new(screen.x/2 - t_size2.x/2,screen.y/2 + t_size1.y/2 + 20),secondarycolor,10,small)
                    -- g_Render:Text(bottom, Vector2:new(screen.x/2 - t_size2.x/2,screen.y/2 + t_size1.y/2 + 20), secondarycolor,10,small,true)
    
                    t_size3 = g_Render:CalcTextSize(round(desync_delta,0).."°", 12)
                    if (desync_delta > 0 and desync_delta <= 58) then
                        g_Render:Text(round(desync_delta,0).."°", Vector2:new(screen.x/2 - 30 - t_size3.x, screen.y/2 + 25 - t_size3.y/2), Color:new(1,1,1,1),12,true)
                        g_Render:BoxFilled(Vector2:new(screen.x/2 - 23,screen.y/2 + 23 - body_yaw/4), Vector2:new(screen.x/2 - 26,screen.y/2 + 29 + body_yaw/4), secondarycolor)
                    elseif(desync_delta < 0) then
                        g_Render:Text(round(desync_delta,0).."°", Vector2:new(screen.x/2 + 26, screen.y/2 + 25 - t_size3.y/2), Color:new(1,1,1,1),12,true)
                        g_Render:BoxFilled(Vector2:new(screen.x/2 + 23,screen.y/2 + 25 - body_yaw/4), Vector2:new(screen.x/2 + 26,screen.y/2 + 29+ body_yaw/4), secondarycolor)
                    end
                elseif(bottom == "DEFAULT") then
                    if(ref_dt:GetBool()) then
                        if exploits.GetCharge() ~= 1  then
                            g_Render_TextOutline(dttext,Vector2:new(screen.x/2 + 12 - t_size2.x/2,screen.y/2 + t_size1.y/2 + 30),Color.new(255,255,255,0.3),10,small)
                            -- g_Render:Text("DT",Vector2:new(screen.x/2 + 13 - t_size2.x/2,screen.y/2 + t_size1.y/2 + 30),Color.new(255,255,255,0.3),10,small,true)
                        else
                            g_Render_TextOutline(dttext,Vector2:new(screen.x/2 + 12 - t_size2.x/2,screen.y/2 + t_size1.y/2 + 30),secondarycolor,10,small)
                            -- g_Render:Text("DT",Vector2:new(screen.x/2 + 13 - t_size2.x/2,screen.y/2 + t_size1.y/2 + 30),secondarycolor,10,small,true)
                        end
                        
                    else
                        g_Render_TextOutline(dttext,Vector2:new(screen.x/2 + 12 - t_size2.x/2,screen.y/2 + t_size1.y/2 + 30),Color.new(255,255,255,0.3),10,small)
                        -- g_Render:Text("DT",Vector2:new(screen.x/2 + 13 - t_size2.x/2,screen.y/2 + t_size1.y/2 + 30),secondarycolor,10,small,true)
                    end
                    g_Render_TextOutline(bottom,Vector2:new(screen.x/2 - t_size2.x/2,screen.y/2 + t_size1.y/2 + 20),secondarycolor,10,small)
                    -- g_Render:Text(bottom, Vector2:new(screen.x/2 - t_size2.x/2,screen.y/2 + t_size1.y/2 + 20), secondarycolor,10,small,true)
    
                    t_size3 = g_Render:CalcTextSize(round(desync_delta,0).."°", 12)
                    if (desync_delta > 0 and desync_delta <= 58) then
                        g_Render:Text(round(desync_delta,0).."°", Vector2:new(screen.x/2 - 30 - t_size3.x, screen.y/2 + 25 - t_size3.y/2), Color:new(1,1,1,1),12,true)
                        g_Render:BoxFilled(Vector2:new(screen.x/2 - 23,screen.y/2 + 23 - body_yaw/4), Vector2:new(screen.x/2 - 26,screen.y/2 + 29 + body_yaw/4), secondarycolor)
                    elseif(desync_delta < 0) then
                        g_Render:Text(round(desync_delta,0).."°", Vector2:new(screen.x/2 + 26, screen.y/2 + 25 - t_size3.y/2), Color:new(1,1,1,1),12,true)
                        g_Render:BoxFilled(Vector2:new(screen.x/2 + 23,screen.y/2 + 25 - body_yaw/4), Vector2:new(screen.x/2 + 26,screen.y/2 + 29+ body_yaw/4), secondarycolor)
                    end
                elseif(bottom == "OFFENCE") then
                    if(ref_dt:GetBool()) then
                        if exploits.GetCharge() ~= 1  then
                            g_Render_TextOutline(dttext,Vector2:new(screen.x/2 + 13 - t_size2.x/2,screen.y/2 + t_size1.y/2 + 30),Color.new(255,255,255,0.3),10,small)
                            -- g_Render:Text("DT",Vector2:new(screen.x/2 + 13 - t_size2.x/2,screen.y/2 + t_size1.y/2 + 30),Color.new(255,255,255,0.3),10,small,true)
                        else
                            g_Render_TextOutline(dttext,Vector2:new(screen.x/2 + 13 - t_size2.x/2,screen.y/2 + t_size1.y/2 + 30),secondarycolor,10,small)
                            -- g_Render:Text("DT",Vector2:new(screen.x/2 + 13 - t_size2.x/2,screen.y/2 + t_size1.y/2 + 30),secondarycolor,10,small,true)
                        end
                        
                    else
                        g_Render_TextOutline(dttext,Vector2:new(screen.x/2 + 13 - t_size2.x/2,screen.y/2 + t_size1.y/2 + 30),Color.new(255,255,255,0.3),10,small)
                        -- g_Render:Text("DT",Vector2:new(screen.x/2 + 13 - t_size2.x/2,screen.y/2 + t_size1.y/2 + 30),secondarycolor,10,small,true)
                    end
                    g_Render_TextOutline(bottom,Vector2:new(screen.x/2 - t_size2.x/2,screen.y/2 + t_size1.y/2 + 20),secondarycolor,10,small)
                    -- g_Render:Text(bottom, Vector2:new(screen.x/2 - t_size2.x/2,screen.y/2 + t_size1.y/2 + 20), secondarycolor,10,small,true)
    
                    t_size3 = g_Render:CalcTextSize(round(desync_delta,0).."°", 12)
                    if (desync_delta > 0 and desync_delta <= 58) then
                        g_Render:Text(round(desync_delta,0).."°", Vector2:new(screen.x/2 - 30 - t_size3.x, screen.y/2 + 25 - t_size3.y/2), Color:new(1,1,1,1),12,true)
                        g_Render:BoxFilled(Vector2:new(screen.x/2 - 23,screen.y/2 + 23 - body_yaw/4), Vector2:new(screen.x/2 - 26,screen.y/2 + 29 + body_yaw/4), secondarycolor)
                    elseif(desync_delta < 0) then
                        g_Render:Text(round(desync_delta,0).."°", Vector2:new(screen.x/2 + 26, screen.y/2 + 25 - t_size3.y/2), Color:new(1,1,1,1),12,true)
                        g_Render:BoxFilled(Vector2:new(screen.x/2 + 23,screen.y/2 + 25 - body_yaw/4), Vector2:new(screen.x/2 + 26,screen.y/2 + 29+ body_yaw/4), secondarycolor)
                    end
                elseif(bottom == "INDEXED") then
                    if(ref_dt:GetBool()) then
                        if exploits.GetCharge() ~= 1  then
                            g_Render_TextOutline(dttext,Vector2:new(screen.x/2 + 12 - t_size2.x/2,screen.y/2 + t_size1.y/2 + 30),Color.new(255,255,255,0.3),10,small)
                            -- g_Render:Text("DT",Vector2:new(screen.x/2 + 13 - t_size2.x/2,screen.y/2 + t_size1.y/2 + 30),Color.new(255,255,255,0.3),10,small,true)
                        else
                            g_Render_TextOutline(dttext,Vector2:new(screen.x/2 + 12 - t_size2.x/2,screen.y/2 + t_size1.y/2 + 30),secondarycolor,10,small)
                            -- g_Render:Text("DT",Vector2:new(screen.x/2 + 13 - t_size2.x/2,screen.y/2 + t_size1.y/2 + 30),secondarycolor,10,small,true)
                        end
                        
                    else
                        g_Render_TextOutline(dttext,Vector2:new(screen.x/2 + 12 - t_size2.x/2,screen.y/2 + t_size1.y/2 + 30),Color.new(255,255,255,0.3),10,small)
                        -- g_Render:Text("DT",Vector2:new(screen.x/2 + 13 - t_size2.x/2,screen.y/2 + t_size1.y/2 + 30),secondarycolor,10,small,true)
                    end
                    g_Render_TextOutline(bottom,Vector2:new(screen.x/2 - t_size2.x/2,screen.y/2 + t_size1.y/2 + 20),secondarycolor,10,small)
                    -- g_Render:Text(bottom, Vector2:new(screen.x/2 - t_size2.x/2,screen.y/2 + t_size1.y/2 + 20), secondarycolor,10,small,true)
    
                    t_size3 = g_Render:CalcTextSize(round(desync_delta,0).."°", 12)
                    if (desync_delta > 0 and desync_delta <= 58) then
                        g_Render:Text(round(desync_delta,0).."°", Vector2:new(screen.x/2 - 30 - t_size3.x, screen.y/2 + 25 - t_size3.y/2), Color:new(1,1,1,1),12,true)
                        g_Render:BoxFilled(Vector2:new(screen.x/2 - 23,screen.y/2 + 23 - body_yaw/4), Vector2:new(screen.x/2 - 26,screen.y/2 + 29 + body_yaw/4), secondarycolor)
                    elseif(desync_delta < 0) then
                        g_Render:Text(round(desync_delta,0).."°", Vector2:new(screen.x/2 + 26, screen.y/2 + 25 - t_size3.y/2), Color:new(1,1,1,1),12,true)
                        g_Render:BoxFilled(Vector2:new(screen.x/2 + 23,screen.y/2 + 25 - body_yaw/4), Vector2:new(screen.x/2 + 26,screen.y/2 + 29+ body_yaw/4), secondarycolor)
                    end
                elseif(bottom == "FLICK") then
                    if(ref_dt:GetBool()) then
                        if exploits.GetCharge() ~= 1  then
                            g_Render_TextOutline(dttext,Vector2:new(screen.x/2 + 8 - t_size2.x/2,screen.y/2 + t_size1.y/2 + 30),Color.new(255,255,255,0.3),10,small)
                            -- g_Render:Text("DT",Vector2:new(screen.x/2 + 13 - t_size2.x/2,screen.y/2 + t_size1.y/2 + 30),Color.new(255,255,255,0.3),10,small,true)
                        else
                            g_Render_TextOutline(dttext,Vector2:new(screen.x/2 + 8 - t_size2.x/2,screen.y/2 + t_size1.y/2 + 30),secondarycolor,10,small)
                            -- g_Render:Text("DT",Vector2:new(screen.x/2 + 13 - t_size2.x/2,screen.y/2 + t_size1.y/2 + 30),secondarycolor,10,small,true)
                        end
                        
                    else
                        g_Render_TextOutline(dttext,Vector2:new(screen.x/2 + 8 - t_size2.x/2,screen.y/2 + t_size1.y/2 + 30),Color.new(255,255,255,0.3),10,small)
                        -- g_Render:Text("DT",Vector2:new(screen.x/2 + 13 - t_size2.x/2,screen.y/2 + t_size1.y/2 + 30),secondarycolor,10,small,true)
                    end
                    g_Render_TextOutline(bottom,Vector2:new(screen.x/2 - t_size2.x/2,screen.y/2 + t_size1.y/2 + 20),secondarycolor,10,small)
                    -- g_Render:Text(bottom, Vector2:new(screen.x/2 - t_size2.x/2,screen.y/2 + t_size1.y/2 + 20), secondarycolor,10,small,true)
    
                    t_size3 = g_Render:CalcTextSize(round(desync_delta,0).."°", 12)
                    if (desync_delta > 0 and desync_delta <= 58) then
                        g_Render:Text(round(desync_delta,0).."°", Vector2:new(screen.x/2 - 30 - t_size3.x, screen.y/2 + 25 - t_size3.y/2), Color:new(1,1,1,1),12,true)
                        g_Render:BoxFilled(Vector2:new(screen.x/2 - 23,screen.y/2 + 23 - body_yaw/4), Vector2:new(screen.x/2 - 26,screen.y/2 + 29 + body_yaw/4), secondarycolor)
                    elseif(desync_delta < 0) then
                        g_Render:Text(round(desync_delta,0).."°", Vector2:new(screen.x/2 + 26, screen.y/2 + 25 - t_size3.y/2), Color:new(1,1,1,1),12,true)
                        g_Render:BoxFilled(Vector2:new(screen.x/2 + 23,screen.y/2 + 25 - body_yaw/4), Vector2:new(screen.x/2 + 26,screen.y/2 + 29+ body_yaw/4), secondarycolor)
                    end
                elseif(bottom == "ROTATION") then
                    if(ref_dt:GetBool()) then
                        if exploits.GetCharge() ~= 1  then
                            g_Render_TextOutline(dttext,Vector2:new(screen.x/2 + 14 - t_size2.x/2,screen.y/2 + t_size1.y/2 + 30),Color.new(255,255,255,0.3),10,small)
                            -- g_Render:Text("DT",Vector2:new(screen.x/2 + 13 - t_size2.x/2,screen.y/2 + t_size1.y/2 + 30),Color.new(255,255,255,0.3),10,small,true)
                        else
                            g_Render_TextOutline(dttext,Vector2:new(screen.x/2 + 14 - t_size2.x/2,screen.y/2 + t_size1.y/2 + 30),secondarycolor,10,small)
                            -- g_Render:Text("DT",Vector2:new(screen.x/2 + 13 - t_size2.x/2,screen.y/2 + t_size1.y/2 + 30),secondarycolor,10,small,true)
                        end
                        
                    else
                        g_Render_TextOutline(dttext,Vector2:new(screen.x/2 + 14 - t_size2.x/2,screen.y/2 + t_size1.y/2 + 30),Color.new(255,255,255,0.3),10,small)
                        -- g_Render:Text("DT",Vector2:new(screen.x/2 + 13 - t_size2.x/2,screen.y/2 + t_size1.y/2 + 30),secondarycolor,10,small,true)
                    end
                    g_Render_TextOutline(bottom,Vector2:new(screen.x/2 - t_size2.x/2,screen.y/2 + t_size1.y/2 + 20),secondarycolor,10,small)
                    -- g_Render:Text(bottom, Vector2:new(screen.x/2 - t_size2.x/2,screen.y/2 + t_size1.y/2 + 20), secondarycolor,10,small,true)
    
                    t_size3 = g_Render:CalcTextSize(round(desync_delta,0).."°", 12)
                    if (desync_delta > 0 and desync_delta <= 58) then
                        g_Render:Text(round(desync_delta,0).."°", Vector2:new(screen.x/2 - 30 - t_size3.x, screen.y/2 + 25 - t_size3.y/2), Color:new(1,1,1,1),12,true)
                        g_Render:BoxFilled(Vector2:new(screen.x/2 - 23,screen.y/2 + 23 - body_yaw/4), Vector2:new(screen.x/2 - 26,screen.y/2 + 29 + body_yaw/4), secondarycolor)
                    elseif(desync_delta < 0) then
                        g_Render:Text(round(desync_delta,0).."°", Vector2:new(screen.x/2 + 26, screen.y/2 + 25 - t_size3.y/2), Color:new(1,1,1,1),12,true)
                        g_Render:BoxFilled(Vector2:new(screen.x/2 + 23,screen.y/2 + 25 - body_yaw/4), Vector2:new(screen.x/2 + 26,screen.y/2 + 29+ body_yaw/4), secondarycolor)
                    end
                end
                
            elseif(ui.indicator_style:GetInt() == 1) then--simple

                dttext = "DT"
                bottom = brute.yaw_status
                bottomcolor = 255,255,255,0.3
                t_size1 = g_Render:CalcTextSize("C&A", 10)
                t_size2 = g_Render:CalcTextSize(bottom, 10)
                t_sizef = g_Render:CalcTextSize("f", 30, arrowfont)
                t_size3 = g_Render:CalcTextSize(dttext, 10)
                g_Render:GradientBoxFilled(Vector2.new(screen.x/2, screen.y/2+30), Vector2.new(screen.x/2+(math.max(3,math.abs(desync_delta*58/70))), screen.y/2+32), maincolor, Color.new(maincolor:r(),maincolor:g(),maincolor:b(),0), maincolor, Color.new(maincolor:r(),maincolor:g(),maincolor:b(),0))

                if(bottom == "JITTER") then
                    g_Render_TextOutline(bottom,Vector2:new(screen.x/2,screen.y/2 + t_size1.y/2 + 26),secondarycolor,10,small)
                elseif(bottom == "DEFAULT") then
                    g_Render_TextOutline(bottom,Vector2:new(screen.x/2,screen.y/2 + t_size1.y/2 + 26),secondarycolor,10,small)
                elseif(bottom == "OFFENCE") then
                    g_Render_TextOutline(bottom,Vector2:new(screen.x/2,screen.y/2 + t_size1.y/2 + 26),secondarycolor,10,small)
                elseif(bottom == "INDEXED") then
                    g_Render_TextOutline(bottom,Vector2:new(screen.x/2,screen.y/2 + t_size1.y/2 + 26),secondarycolor,10,small)
                elseif(bottom == "FLICK") then
                    g_Render_TextOutline(bottom,Vector2:new(screen.x/2,screen.y/2 + t_size1.y/2 + 26),secondarycolor,10,small)
                elseif(bottom == "ROTATION") then
                    g_Render_TextOutline(bottom,Vector2:new(screen.x/2,screen.y/2 + t_size1.y/2 + 26),secondarycolor,10,small)
                end
                t_size3 = g_Render:CalcTextSize(round(desync_delta,0).."°", 10)
                if (desync_delta > 0 and desync_delta <= 58) then
                    g_Render_TextOutline(round(desync_delta,0).."°", Vector2:new(screen.x/2,screen.y/2 + t_size1.y/2 + 5), Color:new(1,1,1,1),10,small)
                elseif(desync_delta < 0) then
                    g_Render_TextOutline(round(desync_delta,0).."°", Vector2:new(screen.x/2,screen.y/2 + t_size1.y/2 + 5), Color:new(1,1,1,1),10,small)
                end
                g_Render_TextOutline("C&A", Vector2:new(screen.x/2,screen.y/2 + t_size1.y/2 + 15), maincolor,10,small)

               
                if(ref_dt:GetBool()) then
                    if exploits.GetCharge() ~= 1  then
                        g_Render_TextOutline(dttext,Vector2:new(screen.x/2,screen.y/2 + t_size1.y/2 + 34),Color.new(255,255,255,0.3),10,small)
                        -- g_Render:Text("DT",Vector2:new(screen.x/2 + 13 - t_size2.x/2,screen.y/2 + t_size1.y/2 + 30),Color.new(255,255,255,0.3),10,small,true)
                    else
                        g_Render_TextOutline(dttext,Vector2:new(screen.x/2,screen.y/2 + t_size1.y/2 + 34),secondarycolor,10,small)
                        -- g_Render:Text("DT",Vector2:new(screen.x/2 + 13 - t_size2.x/2,screen.y/2 + t_size1.y/2 + 30),secondarycolor,10,small,true)
                    end
                
                else
                    g_Render_TextOutline(dttext,Vector2:new(screen.x/2,screen.y/2 + t_size1.y/2 + 34),Color.new(255,255,255,0.3),10,small)
                end
    
            elseif(ui.indicator_style:GetInt() == 2) then--other
                t_size1 = g_Render:CalcTextSize("C&A", 10)

                -- if(ref_dt:GetBool()) then
                --     if exploits.GetCharge() ~= 1  then
                --         g_Render:Text(name,idc_1_mid_pos,Color.new(255,255,255,0.3),10,true)
                --     else
                --         g_Render:Text(name,idc_1_mid_pos,maincolor,10,true)
                --     end
                    
                -- else
                --     g_Render:Text(name,idc_1_mid_pos,maincolor,10,true)
                -- end
           

                t_size3 = g_Render:CalcTextSize(round(desync_delta,0).."°", 10)
                if (desync_delta > 0 and desync_delta <= 58) then
                    g_Render_TextOutline(round(desync_delta,0).."°", Vector2:new(screen.x/2 - t_size1.x/2 +3,screen.y/2 + t_size1.y/2 + 5), Color:new(1,1,1,1),10,verdanaOTHER)
                elseif(desync_delta < 0) then
                    g_Render_TextOutline(round(desync_delta,0).."°", Vector2:new(screen.x/2 - t_size1.x/2 +2,screen.y/2 + t_size1.y/2 + 5), Color:new(1,1,1,1),10,verdanaOTHER)
                end
                g_Render_TextOutline(name,Vector2:new(screen.x/2 - t_size1.x/2 - 2,screen.y/2 + t_size1.y/2 + 22),maincolor,10,verdanaOTHER)
              

                g_Render:GradientBoxFilled(Vector2.new(screen.x/2, screen.y/2+23), Vector2.new(screen.x/2+(math.max(3,math.abs(desync_delta*58/100))), screen.y/2+26    ), clr_sec, Color.new(clr_sec:r(),clr_sec:g(),clr_sec:b(),0), clr_sec, Color.new(clr_sec:r(),clr_sec:g(),clr_sec:b(),0))
                g_Render:GradientBoxFilled(Vector2.new(screen.x/2, screen.y/2+23), Vector2.new(screen.x/2+(-math.max(3,math.abs(desync_delta*58/100))), screen.y/2+26), clr_sec, Color.new(clr_sec:r(),clr_sec:g(),clr_sec:b(),0), clr_sec, Color.new(clr_sec:r(),clr_sec:g(),clr_sec:b(),0))
            end
            if(ui.arrow_check:GetBool())then

                t_sizef = g_Render:CalcTextSize("f", 30, arrowfont)
                t_sizeg = g_Render:CalcTextSize("g", 30, arrowfont)
                t_sizeh = g_Render:CalcTextSize("h", 30, arrowfont)
                if(ui.arrow_style:GetInt() == 0) then --main style

                    if(ui.arrowside_style:GetInt() == 0) then --manuel
                        if(ui.arrow_vis_check:GetBool()) then
                            if(ref_yaw_base:GetInt() == 1) then --back
                                g_Render:Text("f", Vector2:new(screen.x/2 - 10,screen.y/2 + t_sizef.y/2 + 15), arrowactive,30, arrowfont)
                            elseif(ref_yaw_base:GetInt() == 2) then --right
                                g_Render:Text("h", Vector2:new(screen.x/2 + 35,screen.y/2 + t_sizeh.y/2 -30), arrowactive,30, arrowfont)
                            elseif(ref_yaw_base:GetInt() == 3) then --left
                                g_Render:Text("g", Vector2:new(screen.x/2 - 60,screen.y/2 + t_sizeg.y/2 -30), arrowactive,30, arrowfont)
                            end
                        else
                            if(ref_yaw_base:GetInt() == 1) then --back
                                g_Render:Text("f", Vector2:new(screen.x/2 - 10,screen.y/2 + t_sizef.y/2 + 15), arrowactive,30, arrowfont)
                                g_Render:Text("h", Vector2:new(screen.x/2 + 35,screen.y/2 + t_sizeh.y/2 -30), arrowinactive,30, arrowfont)
                                g_Render:Text("g", Vector2:new(screen.x/2 - 60,screen.y/2 + t_sizeg.y/2 -30), arrowinactive,30, arrowfont)
                            elseif(ref_yaw_base:GetInt() == 2) then --right
                                g_Render:Text("f", Vector2:new(screen.x/2 - 10,screen.y/2 + t_sizef.y/2 + 15), arrowinactive,30, arrowfont)
                                g_Render:Text("h", Vector2:new(screen.x/2 + 35,screen.y/2 + t_sizeh.y/2 -30), arrowactive,30, arrowfont)
                                g_Render:Text("g", Vector2:new(screen.x/2 - 60,screen.y/2 + t_sizeg.y/2 -30), arrowinactive,30, arrowfont)
                            elseif(ref_yaw_base:GetInt() == 3) then --left
                                g_Render:Text("f", Vector2:new(screen.x/2 - 10,screen.y/2 + t_sizef.y/2 + 15), arrowinactive,30, arrowfont)
                                g_Render:Text("h", Vector2:new(screen.x/2 + 35,screen.y/2 + t_sizeh.y/2 -30), arrowinactive,30, arrowfont)
                                g_Render:Text("g", Vector2:new(screen.x/2 - 60,screen.y/2 + t_sizeg.y/2 -30), arrowactive,30, arrowfont)
                            else
                                g_Render:Text("f", Vector2:new(screen.x/2 - 10,screen.y/2 + t_sizef.y/2 + 15), arrowinactive,30, arrowfont)
                                g_Render:Text("h", Vector2:new(screen.x/2 + 35,screen.y/2 + t_sizeh.y/2 -30), arrowinactive,30, arrowfont)
                                g_Render:Text("g", Vector2:new(screen.x/2 - 60,screen.y/2 + t_sizeg.y/2 -30), arrowinactive,30, arrowfont)
                            end
                        end
                    elseif(ui.arrowside_style:GetInt() == 1) then --Freestand        
                        if(ui.arrow_vis_check:GetBool()) then
                            if(info.side == 1) then --right
                                g_Render:Text("h", Vector2:new(screen.x/2 + 35,screen.y/2 + t_sizeh.y/2 -30), arrowactive,30, arrowfont)
    
                            elseif(info.side == 0) then --left
                                g_Render:Text("g", Vector2:new(screen.x/2 - 60,screen.y/2 + t_sizeg.y/2 -30), arrowactive,30, arrowfont)
                            else
                                
                            end
                        else
                            if(info.side == 1) then --right
                                -- g_Render:Text("f", Vector2:new(screen.x/2 - 10,screen.y/2 + t_sizef.y/2 + 15), arrowinactive,30, arrowfont)
                                g_Render:Text("h", Vector2:new(screen.x/2 + 35,screen.y/2 + t_sizeh.y/2 -30), arrowactive,30, arrowfont)
                                g_Render:Text("g", Vector2:new(screen.x/2 - 60,screen.y/2 + t_sizeg.y/2 -30), arrowinactive,30, arrowfont)
                            elseif(info.side == 0) then --left                                
                                -- g_Render:Text("f", Vector2:new(screen.x/2 - 10,screen.y/2 + t_sizef.y/2 + 15), arrowinactive,30, arrowfont)
                                g_Render:Text("h", Vector2:new(screen.x/2 + 35,screen.y/2 + t_sizeh.y/2 -30), arrowinactive,30, arrowfont)
                                g_Render:Text("g", Vector2:new(screen.x/2 - 60,screen.y/2 + t_sizeg.y/2 -30), arrowactive,30, arrowfont)
                            else
                                -- g_Render:Text("f", Vector2:new(screen.x/2 - 10,screen.y/2 + t_sizef.y/2 + 15), arrowinactive,30, arrowfont)
                                g_Render:Text("h", Vector2:new(screen.x/2 + 35,screen.y/2 + t_sizeh.y/2 -30), arrowinactive,30, arrowfont)
                                g_Render:Text("g", Vector2:new(screen.x/2 - 60,screen.y/2 + t_sizeg.y/2 -30), arrowinactive,30, arrowfont)
                            end
                        end            
                    end
                    
                    
                    
                elseif(ui.arrow_style:GetInt() == 1) then --flat style
                    if(ui.arrowside_style:GetInt() == 0) then --manuel
                        if(ui.arrow_vis_check:GetBool()) then
                            if(ref_yaw_base:GetInt() == 1) then --back
                                g_Render:Text("P", Vector2:new(screen.x/2 - 10,screen.y/2 + t_sizef.y/2 + 15), arrowactive,30, arrowfont)
                            elseif(ref_yaw_base:GetInt() == 2) then --right
                                g_Render:Text("R", Vector2:new(screen.x/2 + 35,screen.y/2 + t_sizeh.y/2 -30), arrowactive,30, arrowfont)
                            elseif(ref_yaw_base:GetInt() == 3) then --left
                                g_Render:Text("Q", Vector2:new(screen.x/2 - 60,screen.y/2 + t_sizeg.y/2 -30), arrowactive,30, arrowfont)
                            end
                        else
                            if(ref_yaw_base:GetInt() == 1) then --back
                                g_Render:Text("P", Vector2:new(screen.x/2 - 10,screen.y/2 + t_sizef.y/2 + 15), arrowactive,30, arrowfont)
                                g_Render:Text("R", Vector2:new(screen.x/2 + 35,screen.y/2 + t_sizeh.y/2 -30), arrowinactive,30, arrowfont)
                                g_Render:Text("Q", Vector2:new(screen.x/2 - 60,screen.y/2 + t_sizeg.y/2 -30), arrowinactive,30, arrowfont)
                            elseif(ref_yaw_base:GetInt() == 2) then --right
                                g_Render:Text("P", Vector2:new(screen.x/2 - 10,screen.y/2 + t_sizef.y/2 + 15), arrowinactive,30, arrowfont)
                                g_Render:Text("R", Vector2:new(screen.x/2 + 35,screen.y/2 + t_sizeh.y/2 -30), arrowactive,30, arrowfont)
                                g_Render:Text("Q", Vector2:new(screen.x/2 - 60,screen.y/2 + t_sizeg.y/2 -30), arrowinactive,30, arrowfont)
                            elseif(ref_yaw_base:GetInt() == 3) then --left
                                g_Render:Text("P", Vector2:new(screen.x/2 - 10,screen.y/2 + t_sizef.y/2 + 15), arrowinactive,30, arrowfont)
                                g_Render:Text("R", Vector2:new(screen.x/2 + 35,screen.y/2 + t_sizeh.y/2 -30), arrowinactive,30, arrowfont)
                                g_Render:Text("Q", Vector2:new(screen.x/2 - 60,screen.y/2 + t_sizeg.y/2 -30), arrowactive,30, arrowfont)
                            else
                                g_Render:Text("P", Vector2:new(screen.x/2 - 10,screen.y/2 + t_sizef.y/2 + 15), arrowinactive,30, arrowfont)
                                g_Render:Text("R", Vector2:new(screen.x/2 + 35,screen.y/2 + t_sizeh.y/2 -30), arrowinactive,30, arrowfont)
                                g_Render:Text("Q", Vector2:new(screen.x/2 - 60,screen.y/2 + t_sizeg.y/2 -30), arrowinactive,30, arrowfont)
                            end
                        end
                    elseif(ui.arrowside_style:GetInt() == 1) then --Freestand        
                        if(ui.arrow_vis_check:GetBool()) then
                            if(info.side == 1) then --right
                                g_Render:Text("R", Vector2:new(screen.x/2 + 35,screen.y/2 + t_sizeh.y/2 -30), arrowactive,30, arrowfont)
    
                            elseif(info.side == 0) then --left
                                g_Render:Text("Q", Vector2:new(screen.x/2 - 60,screen.y/2 + t_sizeg.y/2 -30), arrowactive,30, arrowfont)
                            else
                                
                            end
                        else
                            if(info.side == 1) then --right
                                -- g_Render:Text("f", Vector2:new(screen.x/2 - 10,screen.y/2 + t_sizef.y/2 + 15), arrowinactive,30, arrowfont)
                                g_Render:Text("R", Vector2:new(screen.x/2 + 35,screen.y/2 + t_sizeh.y/2 -30), arrowactive,30, arrowfont)
                                g_Render:Text("Q", Vector2:new(screen.x/2 - 60,screen.y/2 + t_sizeg.y/2 -30), arrowinactive,30, arrowfont)
                            elseif(info.side == 0) then --left                                
                                -- g_Render:Text("f", Vector2:new(screen.x/2 - 10,screen.y/2 + t_sizef.y/2 + 15), arrowinactive,30, arrowfont)
                                g_Render:Text("R", Vector2:new(screen.x/2 + 35,screen.y/2 + t_sizeh.y/2 -30), arrowinactive,30, arrowfont)
                                g_Render:Text("Q", Vector2:new(screen.x/2 - 60,screen.y/2 + t_sizeg.y/2 -30), arrowactive,30, arrowfont)
                            else
                                -- g_Render:Text("f", Vector2:new(screen.x/2 - 10,screen.y/2 + t_sizef.y/2 + 15), arrowinactive,30, arrowfont)
                                g_Render:Text("R", Vector2:new(screen.x/2 + 35,screen.y/2 + t_sizeh.y/2 -30), arrowinactive,30, arrowfont)
                                g_Render:Text("Q", Vector2:new(screen.x/2 - 60,screen.y/2 + t_sizeg.y/2 -30), arrowinactive,30, arrowfont)
                            end
                        end            
                    end
                end
            end
        end
        -- if(ui.get), "Debug panel") then
        --     renderer.text(x - 800, y + -33, 255, 255, 255, 255, nil, 0, "<>> gogi debug panel <<>")
        --     if best_enemy == nil then
        --         renderer.text(x - 800, y + -22, 255, 255, 255, 255, nil, 0, "{ index: " ..round(gogi.miss_radius).. " [" ..gogi.left_miss.. ":" ..gogi.right_miss.. "]")
        --         renderer.text(x - 800, y + -11, 255, 255, 255, 255, nil, 0, "{ side: " ..gogi.side.. " / " ..gogi.best_angle.. "")
        --         renderer.text(x - 800, y + 0, 255, 255, 255, 255, nil, 0, "{ state: " ..gogi.yaw_status.. " / " ..gogi.fl_status.. "")
        --         renderer.text(x - 800, y + 11, 255, 255, 255, 255, nil, 0, "{ status: " ..ui.get(ref_fakelimit).. " / " ..ui.get(ref_bodyyawadd).. " / " ..globals.chokedcommands().. "%")
        --         renderer.text(x - 800, y + 22, 255, 255, 255, 255, nil, 0, "{ timer: " ..gogi.last_miss.. " / " ..gogi.tick_miss.. "")
        --     else
        --         renderer.text(x - 800, y + -22, 255, 255, 255, 255, nil, 0, "{ target: " ..entity.get_player_name(best_enemy).. "")
        --         renderer.text(x - 800, y + -11, 255, 255, 255, 255, nil, 0, "{ index: " ..round(gogi.miss_radius).. " [" ..gogi.left_miss.. ":" ..gogi.right_miss.. "]")
        --         renderer.text(x - 800, y + 0, 255, 255, 255, 255, nil, 0, "{ side: " ..gogi.side.. " / " ..gogi.best_angle.. "")
        --         renderer.text(x - 800, y + 11, 255, 255, 255, 255, nil, 0, "{ state: " ..gogi.yaw_status.. " / " ..gogi.fl_status.. "")
        --         renderer.text(x - 800, y + 22, 255, 255, 255, 255, nil, 0, "{ status: " ..ui.get(ref_fakelimit).. " / " ..ui.get(ref_bodyyawadd).. " / " ..globals.chokedcommands().. "%")
        --         renderer.text(x - 800, y + 33, 255, 255, 255, 255, nil, 0, "{ timer: " ..gogi.last_miss.. " / " ..gogi.tick_miss.. "")
        --     end
        -- end
    end
    local quest = function(cond , T , F )
        if cond then return true else return false end
    end
    cheat.RegisterCallback("createmove", function ()
        if (g_EngineClient:IsConnected()) then

            local me = g_EntityList:GetLocalPlayer()
            local health = me:GetProp("m_iHealth")
            if health > 0 then
              

                -- dt_damage_predict()
            end
    
        end
    end)
    function clantagChanger()
        if ui.clantagswitch:GetBool() then
            if(ui.clantag_style:GetInt() == 0)then
                local curtime = math.floor(g_GlobalVars.curtime * 2)
                if old_time ~= curtime then
                    set_clantag(statictag[curtime % #statictag+1], statictag[curtime % #statictag+1])
                end
                old_time = curtime
            elseif(ui.clantag_style:GetInt() == 1)then 
                local curtime = math.floor(g_GlobalVars.curtime * 1.5)
                if old_time ~= curtime then
                    set_clantag(animatedclantag[curtime % #animatedclantag+1], animatedclantag[curtime % #animatedclantag+1])
                end
                old_time = curtime
            end
        end
    end
    
    local function events(e)
        
        if (g_EngineClient:IsConnected()) then

            local me = g_EntityList:GetLocalPlayer()
            local health = me:GetProp("m_iHealth")
            local data = get_target()
            local closest_enemy = get_enemy()
        
            if health > 0 then
                if e:GetName() == "player_death" then 
                    local me = g_EngineClient:GetLocalPlayer()
                    local victim = g_EngineClient:GetPlayerForUserId(e:GetInt("userid"))
                    local attacker = g_EngineClient:GetPlayerForUserId(e:GetInt("attacker"))
                    if me == attacker and attacker ~= victim then
                        if(has_killed == nil or has_killed == false) then has_killed = true end                                                                          
                    elseif(me == victim and attacker ~= victim) then
                        brute.right_misses = 0
                        brute.left_misses = 0
                        brute.misses = 0
                        brute.shootermisses = 0
                    end        
                end
                bruteimpact(e)
            
            else
                if(has_killed == true)then 
                    has_killed = false 
                end
                if(ref_yaw_add:GetInt() ~= 0)then
                    ref_yaw_add:SetInt(0)
                end
            
               
              
            end


        end
    
    end
    local function pre_predictione()
        
        if (g_EngineClient:IsConnected()) then

            local me = g_EntityList:GetLocalPlayer()
            local health = me:GetProp("m_iHealth")
            if health > 0 then
                -- handle_aa()
                -- legit_aa()
                -- dt_damage_predict()
                -- print(has_killed)
                -- dt_damage_predict()   
            end
    
        end
    
    end
    cheat.RegisterCallback("events", events)
    cheat.RegisterCallback("pre_prediction", pre_prediction)
    body_yaw = 57
    local count = 0                                     -- don't touch
    local tick = 1 / g_GlobalVars.interval_per_tick     -- don't touch
    
    local duration = 3                                 -- Time in seconds (10)
    
    local timer = duration * tick   
    cheat.RegisterCallback("createmove", function(tick_count) -- this script works with the tickrate of the current server the player is on. It won't work if the player is not ingame.
        if(has_killed == true) then
            if tick == 64 then
            
                count = count + 1 -- Every tick it adds 1
        
                if count == timer then
               
                    has_killed = false
                    count = 0
                end
        
            elseif tick == 128 then
                count = count + 0.5 -- Every tick it adds 0.5 since it has twice as more ticks as before
        
                if count == timer then
        
                    has_killed = false
                    count = 0
                end
            end
        end
        
    end)
    cheat.RegisterCallback("draw", function ()
        local screen = g_EngineClient:GetScreenSize()

        local indicatorswitch = quest(ui.indicators_check:GetBool())
        local dormantswitch = quest(ui.dormant_switch:GetBool())
        local dtswitch = quest(ui.dt_enable_switch:GetBool())
        local dtpredicswitch = quest(ui.dt_prediction_switch:GetBool())
        local dtvul = quest(ui.dtmode:GetBool(1))
        local arrow = quest(ui.arrow_check:GetBool())
        local fakelag = quest(ui.fakelag_mode:GetInt() == 1)
        local clantag = quest(ui.clantagswitch:GetBool())
        local debug = quest(ui.debug_check:GetBool())
        --MENU SELECTION
        --aa
        ui.dormant_option:SetVisible(dormantswitch)
        --fl
        ui.fakelag_fluc_amount:SetVisible(fakelag)
        --dt
        ui.dtmode:SetVisible(dtswitch)
        if(ui.dt_enable_switch:GetBool()) then

            ui.vul_mode:SetVisible(dtvul)
        else
            ui.vul_mode:SetVisible(false)
        end
        ui.dt_prediction_log_switch:SetVisible(dtpredicswitch)
        -- visual
        ui.debug_logs:SetVisible(debug)
        ui.arrow_style:SetVisible(arrow)
        ui.arrowside_style:SetVisible(arrow)
        ui.arrow_vis_check:SetVisible(arrow)
        ui.clantag_style:SetVisible(clantag)
        ui.indicator_style:SetVisible(indicatorswitch)

        ui.x_pos_slider:SetVisible(false)
        ui.y_pos_slider:SetVisible(false)


        -- ui.dt_hp_switch:SetVisible(dtswitch)
        
    
        clantagChanger()
        if (g_EngineClient:IsConnected()) then
            watermark() 
            local me = g_EntityList:GetLocalPlayer()
            local health = me:GetProp("m_iHealth")
            if health > 0 then
                handle_dt()
                handle_indicators()   
                teleport_zues()
                disable_fakelag_knife()
                idealtick_handle()
                handle_aa()
                legit_aa()
                dt_damage_predict()
                get_best_angle()
                -- dt_damage_predict()
            end
    
        end
    
        
        
        
    
    
    
        -- local GetNetChannelInfo = g_EngineClient:GetNetChannelInfo()
        -- local ping = GetNetChannelInfo:GetLatency(0)
        
        -- local text1 = "C&A | " .. info.username .. " | " .. round(ping*1000,0).."MS"
    
        -- -- ts = g_Render:CalcTextSize(text1, 10,small)
    
        -- clr_main = ui.colors.main:GetColor()
        -- clr_sec = ui.colors.other:GetColor()
    
       
    
        --g_Render:GradientBoxFilled(Vector2.new(pos[1]- ts.x/2 - 5,pos[2]- ts.y - 5), Vector2.new(pos[1],pos[2]), Color.new(0,0,0,0), Color.new(0,0,0,0.5), Color.new(0,0,0,0), Color.new(0,0,0,0.5))
        --g_Render:GradientBoxFilled(Vector2.new(pos[1],pos[2]- ts.y - 5), Vector2.new(pos[1] + ts.x/2 + 5,pos[2]),Color.new(0,0,0,0.5), Color.new(0,0,0,0), Color.new(0,0,0,0.5), Color.new(0,0,0,0))
        -- g_Render:BoxFilled(Vector2.new(pos[1]- ts.x/2 - 5,pos[2] - 2), Vector2.new(pos[1] + ts.x/2 + 5,pos[2]+ ts.y +2), Color.new(0,0,0,0.5))
        -- g_Render:BoxFilled(Vector2.new(pos[1]- ts.x/2 - 5,pos[2] - 2), Vector2.new(pos[1] + ts.x/2 + 5,pos[2] - 1), clr_main)
        -- g_Render_TextOutline(text1,Vector2.new(pos[1]- ts.x/2,pos[2] ),Color.new(1,1,1,1),10,small)
    
        -- g_Render:GradientBoxFilled(Vector2.new(pos[1]- ts.x/2,pos[2]+ts.y + 6), Vector2.new(pos[1],pos[2]+ts.y + 7), Color.new(clr_sec:r(),clr_sec:g(),clr_sec:b(),0), clr_sec, Color.new(clr_sec:r(),clr_sec:g(),clr_sec:b(),0), clr_sec)
        -- g_Render:GradientBoxFilled(Vector2.new(pos[1],pos[2]+ts.y + 6), Vector2.new(pos[1] + ts.x/2,pos[2]+ts.y + 7), clr_sec, Color.new(clr_sec:r(),clr_sec:g(),clr_sec:b(),0), clr_sec, Color.new(clr_sec:r(),clr_sec:g(),clr_sec:b(),0))
    end)
    settings_button:RegisterCallback(function()
        ui.freestanding_mode:SetInt(1)
        ui.dormant_switch:SetBool(true)
        ui.dormant_option:SetInt(0)
        ui.brute_switch:SetBool(true)
        ui.aa_multimodes:SetBool(1, true)
        ui.aa_multimodes:SetBool(2, true)
        ui.aa_multimodes:SetBool(3, true)
        ui.dt_enable_switch:SetBool(true)
        ui.dtmode:SetBool(0, true)
        ui.dtmode:SetBool(1, true)
        ui.vul_mode:SetInt(1)
        ui.zues_dt_enable_switch:SetBool(true)
        ui.fakelag_switch:SetBool(true)
        ui.fakelag_mode:SetInt(0)
        ui.indicators_check:SetBool(true)
        ui.watermark_style:SetInt(1)
        ui.dt_prediction_switch:SetBool(true)

    end)
    cheat.RegisterCallback("destroy", function () 
        local data = get_target()
        if(ui.dormant_option:GetInt() == 0 and data.id == nil) then
                        
            ref_fake_options:SetInt(dormat_data[1])
            ref_yaw_modifier:SetInt(dormat_data[2])
            ref_yaw_modifier_degree:SetInt(dormat_data[3])
    
        elseif(ui.dormant_option:GetInt() == 1 and data.id == nil) then
            ref_yaw_modifier:SetInt(dormat_data[2])
            ref_yaw_modifier_degree:SetInt(dormat_data[3])
        end
        if(notdormant == true)then 
            ref_fake_options:SetInt(dormat_data[1])
            ref_yaw_modifier:SetInt(dormat_data[2])
            ref_yaw_modifier_degree:SetInt(dormat_data[3])
        end
    
    end)
    
    --[[
    local last = 0
    local state = true
    
    
    cheat.RegisterCallback("createmove", function()
        local cur = g_GlobalVars.curtime
        local me = g_EntityList:GetClientEntity(g_EngineClient:GetLocalPlayer())
        me:SetProp("m_flPoseParameter",1, 0)
    
        if cur > last then
            state = not state
            last = cur + 0.01
            legs:SetInt(state and 1 or 2)
         end
    end)
    ]]

end

if buff == "" then
    ffi.C.WriteFile(pfile, ffi.cast("char*", cheat.GetCheatUserName()), #cheat.GetCheatUserName(), nil, 0)
    local text = menu.Text("C&A", "Add Crow#5151 for getting access to our buyer discord\nOnce you Have added Crow, Reload the Script To Proceed")
    local textbox = menu.TextBox("C&A", "Copy", 64, "Crow#5151")
    ffi.C.CloseHandle(pfile)
else
    ffi.C.CloseHandle(pfile)
    startlua()
end 