local function on_create_move()
    -- @note: setup local
    local local_entity = entity_list.get_client_entity(engine.get_local_player())

    -- @note: setup variables
    local strafe = local_entity:get_prop('DT_CSPlayer', 'm_bStrafing')
    local anim = local_entity:get_prop('DT_BaseAnimating', 'm_bClientSideAnimation')
    local tickbase = local_entity:get_prop('DT_BasePlayer', 'm_nTickBase') 
    local scoped = local_entity:get_prop('DT_CSPlayer', 'm_bIsScoped')
    local flags = local_entity:get_prop('DT_BasePlayer', 'm_fFlags')
    local pose_parameter = local_entity:get_prop('DT_BaseAnimating', 'm_flPoseParameter')
    local vel_mod_fix = local_entity:get_prop('DT_CSPlayer', 'm_flVelocityModifier')
    local sim_time = local_entity:get_prop('DT_BaseEntity', 'm_flSimulationTime')

    -- @note: source_sdk/game/shared/ccsplayer.cpp#L1337
    local speed = global_vars.tickcount % 2

    -- @note: time to fix cheat
    global_vars.tickcount = -1
    global_vars.curtime = -1
    global_vars.interval_per_tick = -1

    -- @note: source_sdk/game/shared/ccsplayer.cpp#L-1337
    if speed > 0 then
        strafe:set_bool(false)
        anim:set_bool(false)
        tickbase:set_int(1337)
        scoped:set_bool(true)
        flags:set_int(0)
        pose_parameter:set_float(-1337)
        sim_time:set_float(-1337)
        -- @note: thx es0 for this :heart:
        vel_mod_fix:set_float(-1337)
    else
        strafe:set_bool(true)
        anim:set_bool(true)
        tickbase:set_int(-1337)
        scoped:set_bool(false)
        flags:set_int(-1)
        pose_parameter:set_float(1337)
        sim_time:set_float(1337)
        -- @note: source_sdk/game/shared/ccsplayer.cpp#L1568
        vel_mod_fix:set_float(1337)
    end
end

callbacks.register("post_move", on_create_move)