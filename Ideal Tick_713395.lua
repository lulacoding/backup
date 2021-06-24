

local idt_bind = menu.Switch("Rage", "Ideal Tick", false, "Forces freestanding, doubletap, and auto peek (set bind)")
local idt_otp = menu.MultiCombo("Rage", "Ideal Tick Options", {"Freestand", "Force Saftey", "Mindamage Overide"}, 0, "")
local idt_awp_dmg = menu.SliderInt("Rage", "Ideal Awp Damage", 25, 0, 130, "Ideal tick minimum Awp damage")
local idt_scout_dmg = menu.SliderInt("Rage", "Ideal Scout Damage", 25, 0, 130, "Ideal tick minimum Scout damage")


local ref_autopeek = g_Config:FindVar("Miscellaneous", "Main", "Movement", "Auto Peek")
local ref_dt = g_Config:FindVar("Aimbot", "Ragebot", "Exploits", "Double Tap")
local ref_awp_vmd = g_Config:FindVar("Aimbot", "Ragebot", "Min. Damage", "Visible", "AWP")
local ref_awp_awmd = g_Config:FindVar("Aimbot", "Ragebot", "Min. Damage", "Autowall", "AWP")
local ref_scout_vmd = g_Config:FindVar("Aimbot", "Ragebot", "Min. Damage", "Visible", "SSG-08")
local ref_scout_awmd = g_Config:FindVar("Aimbot", "Ragebot", "Min. Damage", "Autowall", "SSG-08")
local ref_left_fake = g_Config:FindVar("Aimbot", "Anti Aim", "Fake Angle", "Left Limit")
local ref_lby = g_Config:FindVar("Aimbot", "Anti Aim", "Fake Angle", "LBY Mode")
local ref_right_fake = g_Config:FindVar("Aimbot", "Anti Aim", "Fake Angle", "Right Limit")
local ref_fs = g_Config:FindVar("Aimbot", "Anti Aim", "Fake Angle", "Freestanding Desync")
local ticking = false


local freestandingdata = {
    ref_lby:GetInt(), ref_fs:GetInt(),
    ref_left_fake:GetInt(), ref_right_fake:GetInt(),
}
local awpmindamagedata = {
    ref_awp_vmd:GetInt(), ref_awp_awmd:GetInt()
}
local scoutmindamagedata = {
    ref_scout_vmd:GetInt(), ref_scout_awmd:GetInt()
}

local function handle_idt() 

    local me = g_EntityList:GetClientEntity(g_EngineClient:GetLocalPlayer()):GetPlayer()
    if me == nil then return end
    local wpn = me:GetActiveWeapon():GetClassName()
    if(idt_bind:GetBool() and ref_autopeek:GetBool()) then

        
        ticking = true
        if (idt_otp:GetInt() == 1) then
            ref_lby:SetInt(1)
            ref_fs:SetInt(1)
            antiaim.OverrideLimit(math.random(45, 80))
            ref_left_fake:SetInt(math.random(30, 80))
            ref_right_fake:SetInt(math.random(30, 80))
            
        elseif (idt_otp:GetInt() == 3) then
            ref_lby:SetInt(1)
            ref_fs:SetInt(1)
            antiaim.OverrideLimit(math.random(45, 80))
            ref_left_fake:SetInt(math.random(30, 80))
            ref_right_fake:SetInt(math.random(30, 80))
            ragebot.ForceSafety(1)
        elseif (idt_otp:GetInt() == 7) then
            ref_lby:SetInt(1)
            ref_fs:SetInt(1)
            antiaim.OverrideLimit(math.random(45, 80))
            ref_left_fake:SetInt(math.random(30, 80))
            ref_right_fake:SetInt(math.random(30, 80))
            ragebot.ForceSafety(1)
            if wpn == "CWeaponSSG08" then
                local damagev = g_Config:FindVar("Aimbot", "Ragebot", "Min. Damage", "Visible", "SSG-08")
                local damageaw = g_Config:FindVar("Aimbot", "Ragebot", "Min. Damage", "Autowall", "SSG-08")
                damagev:SetInt(idt_scout_dmg:GetInt())
                damageaw:SetInt(idt_scout_dmg:GetInt())
            elseif wpn == "CWeaponAWP" then
                local damagev = g_Config:FindVar("Aimbot", "Ragebot", "Min. Damage", "Visible", "AWP")
                local damageaw = g_Config:FindVar("Aimbot", "Ragebot", "Min. Damage", "Autowall", "AWP")
                damagev:SetInt(idt_awp_dmg:GetInt())
                damageaw:SetInt(idt_awp_dmg:GetInt())
            end
        end
        if (ref_dt:GetBool() == false) then
            ref_dt:SetBool(true)
        end
            
    else
        if(ticking == true) then
            if(ref_dt:GetBool() == true) then
                ref_dt:SetBool(false)
            end
            if (idt_otp:GetInt() == 1) then
                ref_lby:SetInt(freestandingdata[1])
                ref_fs:SetInt(freestandingdata[2])
                ref_left_fake:SetInt(freestandingdata[3])
                ref_right_fake:SetInt(freestandingdata[4])
            elseif (idt_otp:GetInt() == 3) then
                ref_lby:SetInt(freestandingdata[1])
                ref_fs:SetInt(freestandingdata[2])
                ref_left_fake:SetInt(freestandingdata[3])
                ref_right_fake:SetInt(freestandingdata[4])

            elseif (idt_otp:GetInt() == 7) then 
                
                ref_lby:SetInt(freestandingdata[1])
                ref_fs:SetInt(freestandingdata[2])
                ref_left_fake:SetInt(freestandingdata[3])
                ref_right_fake:SetInt(freestandingdata[4])
                if wpn == "CWeaponSSG08" then
                    local damagev = g_Config:FindVar("Aimbot", "Ragebot", "Min. Damage", "Visible", "SSG-08")
                    local damageaw = g_Config:FindVar("Aimbot", "Ragebot", "Min. Damage", "Autowall", "SSG-08")
                    damagev:SetInt(scoutmindamagedata[1])
                    damageaw:SetInt(scoutmindamagedata[2])
                elseif wpn == "CWeaponAWP" then
                    local damagev = g_Config:FindVar("Aimbot", "Ragebot", "Min. Damage", "Visible", "AWP")
                    local damageaw = g_Config:FindVar("Aimbot", "Ragebot", "Min. Damage", "Autowall", "AWP")
                    damagev:SetInt(awpmindamagedata[1])
                    damageaw:SetInt(awpmindamagedata[2])
                end

            end
            
            ticking = false
        end      
    end   
end
local function pre_prediction(cmd)
    handle_idt()

end
cheat.RegisterCallback("pre_prediction", pre_prediction)