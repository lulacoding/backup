--[[
    [gogi-yaw]
    - Neverlose
]]

--[[
	Menu
]]

-- Elements
menu.Text("Rage", "[gogi-yaw] settings")
local dt_mode = menu.Combo("Rage", "Doubletap Mode", {"Default", "Latency"}, 0, "Dicates how the script will modify your doubletap")
local dt_limit = menu.SliderFloat("Rage", "Maximum Tickbase", 16, 14, 18, "Maximum tickbase achievable before clamped")
local idt_bind = menu.Switch("Rage", "Ideal Tick", false, "Forces freestanding, doubletap, and auto peek")
local idt_dmg = menu.SliderFloat("Rage", "Ideal Tick Damage", 8, 0, 130, "Ideal tick minimum damage")

menu.Text("Antiaim", "[gogi-yaw] settings")
local aa_mode = menu.Combo("Antiaim", "Angle Dictation", {"Advanced Safety", "Bruteforce"}, 0, "Angle dictation for your antiaim")
local aa_limit = menu.Switch("Antiaim", "Avoid High Delta", false, "Limits your fake degree")
local aa_limit_dev = menu.SliderFloat("Antiaim", "Delta Deviation", 35, 0, 60, "Maximum delta achievable before clamped")
local aa_fl = menu.Switch("Antiaim", "Adaptive Fakelag", false, "Depicts the optimal limit and randomization per player conditions")
local aa_legs = menu.Switch("Antiaim", "Jitter Legs", false, "Jitter your feet model")

-- References
local ref_inv = g_Config:FindVar("Aimbot", "Anti Aim", "Fake Angle", "Inverter")
local ref_left_fake = g_Config:FindVar("Aimbot", "Anti Aim", "Fake Angle", "Left Limit")
local ref_lby = g_Config:FindVar("Aimbot", "Anti Aim", "Fake Angle", "LBY Mode")
local ref_right_fake = g_Config:FindVar("Aimbot", "Anti Aim", "Fake Angle", "Right Limit")
local ref_leg = g_Config:FindVar("Aimbot", "Anti Aim", "Misc", "Leg Movement")
local ref_fl_limit = g_Config:FindVar("Aimbot", "Anti Aim", "Fake Lag", "Limit")
local ref_fl_ovr = g_Config:FindVar("Aimbot", "Anti Aim", "Fake Lag", "Enable Fake Lag")
local ref_fl_rand = g_Config:FindVar("Aimbot", "Anti Aim", "Fake Lag", "Randomization")
local ref_base = g_Config:FindVar("Aimbot", "Anti Aim", "Main", "Yaw Base")
local ref_jitter_type = g_Config:FindVar("Aimbot", "Anti Aim", "Main", "Yaw Modifier")
local ref_jitter_range = g_Config:FindVar("Aimbot", "Anti Aim", "Main", "Modifier Degree")
local ref_fake = g_Config:FindVar("Aimbot", "Anti Aim", "Fake Angle", "Fake Options")
local ref_fs = g_Config:FindVar("Aimbot", "Anti Aim", "Fake Angle", "Freestanding Desync")
local ref_dsy = g_Config:FindVar("Aimbot", "Anti Aim", "Fake Angle", "Desync On Shot")

--[[
	Globals
]]

-- Objects
local brute = {
    yaw_status = "default",
    indexed_angle = 0,
    last_miss = 0,
    best_angle = 0,
    misses = 0,
}

-- Variables
local me = g_EntityList:GetLocalPlayer()
local screen_size = g_EngineClient:GetScreenSize()
local x = screen_size.x / 2
local y = screen_size.y / 2
local local_player = g_EntityList:GetClientEntity(g_EngineClient:GetLocalPlayer())
local localplayer = g_EntityList:GetClientEntity(g_EngineClient:GetLocalPlayer())

--[[
    Script Functions
]]
--[[
    exploits
]]
local function gogidt()
    if dt_mode:GetBool() then

    end
end

local function handle_aa()
    if aa_legs:GetBool() then
        if utils.RandomInt(0,10) > 4 then
            ref_leg:SetInt(1)
        else
            ref_leg:SetInt(2)
        end
    end

    if bestplayer == nil then
        brute.yaw_status = "jitter"
    else
        if indexed_angle == 1 then
            brute.yaw_status = "nervous"
        elseif indexed_angle == 2 then
            brute.yaw_status = "indexed"
        elseif indexed_angle == 3 then
            brute.yaw_status = "indexed"
        else  
            brute.yaw_status = "default"
        end
    end

    if (aa_limit:GetBool()) then
        
    end

    if (c_menu_anti_aim_helpers_desync:GetBool()) then

        if (c_menu_anti_aim_helpers_desync_mod:GetInt() == 0) then --smart
            menu_fake_option:SetInt(1)
            menu_freestand_desync:SetInt(2)
            antiaim.OverrideLimit(math.random(45, 80))
              menu_left_limit:SetInt(math.random(30, 80))
              menu_right_limit:SetInt(math.random(30, 80))
           
        
        end
        if (c_menu_anti_aim_helpers_desync_mod:GetInt() == 2) then --Multiple
            menu_fake_option:SetInt(utils.RandomInt(2, 3))
            menu_fake_options:SetInt(utils.RandomInt(1, 2))
              menu_left_limit:SetInt(utils.RandomInt(35, 60))
              menu_right_limit:SetInt(utils.RandomInt(35, 60))
        end
       if (c_menu_anti_aim_helpers_desync_mod:GetInt() == 1) then --prefer low delta 
          menu_fake_option:SetInt(1)
          menu_freestand_desync:SetInt(2)
          antiaim.OverrideLimit(math.random(15, 15))
          menu_left_limit:SetInt(math.random(15, 35))
          menu_right_limit:SetInt(math.random(15, 35))
        
        end     
    end


end



--[[
    Helper Functions
]]

local function normalize_yaw(yaw)
	while yaw > 180 do yaw = yaw - 360 end
	while yaw < -180 do yaw = yaw + 360 end
	return yaw
end

local function calc_angle(local_x, local_y, enemy_x, enemy_y)
	local ydelta = local_y - enemy_y
	local xdelta = local_x - enemy_x
	local relativeyaw = math.atan( ydelta / xdelta )
	relativeyaw = normalize_yaw( relativeyaw * 180 / math.pi )
	if xdelta >= 0 then
		relativeyaw = normalize_yaw(relativeyaw + 180)
	end
	return relativeyaw
end

local function ang_on_screen(x, y)
    if x == 0 and y == 0 then return 0 end

    return math.deg(math.atan2(y, x))
end

local vec_3 = function(_x, _y, _z) 
	return { x = _x or 0, y = _y or 0, z = _z or 0 } 
end

local function angle_vector(angle_x, angle_y)
	local sy = math.sin(math.rad(angle_y))
	local cy = math.cos(math.rad(angle_y))
	local sp = math.sin(math.rad(angle_x))
	local cp = math.cos(math.rad(angle_x))
	return cp * cy, cp * sy, -sp
end

function best_player()
    --distance = function(self, localplayer)
    local origin = localplayer:GetProp("DT_BaseEntity", "m_vecOrigin")
    local bestdistance = 8192.0
    local bestplayer = nil
    for i = 1, 64 do
        local player = g_EntityList:GetClientEntity(i)
        if player ~= nil then
            player = player:GetPlayer()
            if (player:IsTeamMate() ~= true or player:m_lifeState() ~= 0 or player:IsDormant() ~= true) then
                local distance = origin:DistTo(player:GetProp("DT_BaseEntity", "m_vecOrigin"))

                if(distance < bestdistance) then
                    bestdistance = distance
                    bestplayer = player
                end
            end
        end
        return bestplayer
    end
end

local function logic(e)
    if e:GetName() == "weapon_fire" then
        local user_id = e:GetInt("userid", -1)
        local user = g_EntityList:GetClientEntity(g_EngineClient:GetPlayerForUserId(user_id))
        local local_player = g_EntityList:GetClientEntity(g_EngineClient:GetLocalPlayer())
        local player = local_player:GetPlayer()
        local health = player:GetProp("DT_BasePlayer", "m_iHealth")
     

        if(health > 0) then
            local closest_enemy = best_player()
            if(closest_enemy ~= nil and user:EntIndex() == closest_enemy:EntIndex()) then 
                brute.misses = brute.misses + 1
                if (brute.misses % 3 == 0) then --Logic 1            
                    brute.indexed_angle = 1 
                else if (brute.misses % 3 == 1) then --Logic 2 
                    brute.indexed_angle = 2 
                else if (brute.misses % 3 == 2) then --Logic 3
                    brute.indexed_angle = 3 
                else
                    brute.indexed_angle = 0
                end
            end
        end
    end
end
end
end

--[[
    Callbacks
]]

local function draw()
    if (g_EngineClient:IsConnected()) then
        if (c_menu_watermarker:GetBool()) then
            watermarker()
        end

    end
end

local function pre_prediction(cmd)
end

local function prediction()
end

local function createmove()
    handle_aa()
end

local function events(e)
    logic(e)
end

cheat.RegisterCallback("draw", draw)
cheat.RegisterCallback("pre_prediction", pre_prediction)
cheat.RegisterCallback("prediction", prediction)
cheat.RegisterCallback("createmove", createmove)
cheat.RegisterCallback("events", events)