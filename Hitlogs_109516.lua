local UI = {
	clr = menu.ColorEdit("Hitlog", "Colour", Color.new(1, 1, 1, 1));
};

local drawlist = {
};

cheat.RegisterCallback("events", function(evnt)
	if (evnt:GetName() ~= "player_hurt") then
		return;
	end
	local userID = evnt:GetInt("userid", 0);
	local plyr = g_EngineClient:GetPlayerForUserId(userID);
	local rPlyr = g_EntityList:GetClientEntity(plyr):GetPlayer();
	local hitgroup = evnt:GetInt("hitgroup", 0);
	local hitboxes = { 0, 3, 3, 16, 18, 11, 10, 0 };
	local hitbox = hitboxes[hitgroup];
	local damageDone = evnt:GetInt("dmg_health", 0);
	table.insert(drawlist, {
		rPlyr:GetHitboxCenter(hitbox);
		1;
		damageDone;
	});
end);

cheat.RegisterCallback("draw", function()
	local themeColour = UI.clr:GetColor();
	for i = 1, table.getn(drawlist), 1 do
		drawlist[i][2] = drawlist[i][2] - 0.001;
		local worldBox = Vector.new(drawlist[i][1].x, drawlist[i][1].y + 50, drawlist[i][1].z + 20);
		local screenStart = g_Render:ScreenPosition(drawlist[i][1]);
		local screenBox = g_Render:ScreenPosition(worldBox);
		local boxSize = Vector2.new(70, 30);
		local endScreenBox = Vector2.new(boxSize.x + screenBox.x, boxSize.y + screenBox.y);
		g_Render:Line(screenStart, Vector2.new(screenBox.x, screenBox.y + (boxSize.y / 2)), Color.new(themeColour:r(), themeColour:g(), themeColour:b(), drawlist[i][2]));
		g_Render:BoxFilled(screenBox, endScreenBox, Color.new(0.05, 0.05, 0.05, drawlist[i][2]));
		g_Render:Box(screenBox, endScreenBox, Color.new(themeColour:r(), themeColour:g(), themeColour:b(), drawlist[i][2]));
		g_Render:Text("-" .. tostring(drawlist[i][3]) .. "hp", Vector2.new(screenBox.x + 5, screenBox.y + 5), Color.new(themeColour:r(), themeColour:g(), themeColour:b(), drawlist[i][2]), 15);
	end
end);