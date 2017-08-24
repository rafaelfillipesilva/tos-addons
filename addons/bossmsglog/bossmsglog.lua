_G["LUNAR"] = _G["LUNAR"] or {};
_G["LUNAR"]["BOSSMSGLOG"] = _G["LUNAR"]["BOSSMSGLOG"] or {};

local g = _G["LUNAR"]["BOSSMSGLOG"];

g.loaded = false;

g.interval = 30;

g.spawn = 10 * 60;

g.timer = imcTime.GetAppTime();
g.timeout = 15 * 60;

g.bosses = {};

g.demon_lords = {};

table.insert(g.demon_lords, {"Mirtis", "Rexipher", "Helgasercle", "Demon Lord Marnox"});
table.insert(g.demon_lords, {"Demon Lord Nuaele", "Demon Lord Zaura", "Demon Lord Blut"});

function BOSSMSGLOG_ON_INIT(addon, frame)
	if g.loaded == false then
		_G["_BOSSMSGLOG_NOTICE_ON_MSG"] = _G["NOTICE_ON_MSG"];
		g.loaded = true;
	end

	if _G["NOTICE_ON_MSG"] ~= BOSSMSGLOG_NOTICE_ON_MSG then
		_G["NOTICE_ON_MSG"] = BOSSMSGLOG_NOTICE_ON_MSG;
	end

	g.addon = addon;
	g.frame = frame;

	addon:RegisterMsg("FPS_UPDATE", "BOSSMSGLOG_UPDATE");

	BOSSMSGLOG_SETUP_UI(frame, 0);

	local acutil = require("acutil");
	acutil.slashCommand("/bosslog", BOSSMSGLOG_TOGGLE_UI);
	acutil.slashCommand("/bl", BOSSMSGLOG_TOGGLE_UI);
end

function BOSSMSGLOG_SETUP_UI(frame, visible)
	frame = frame or g.frame;
	frame:ShowWindow(visible);
end

function BOSSMSGLOG_TOGGLE_UI()
	if g.frame:IsVisible() == 0 then
		BOSSMSGLOG_SETUP_UI(g.frame, 1);
	else
		BOSSMSGLOG_SETUP_UI(g.frame, 0);
	end
end

function BOSSMSGLOG_MAP_NAME()
	local mapprop = session.GetCurrentMapProp();
	return mapprop:GetName();
end

function BOSSMSGLOG_GET_FIELDBOSSWILLAPPEAR_NAME(str)
	local bossName = str:sub(40);
	bossName = bossName:sub(0, bossName:find("#@!")-1);
	return dictionary.ReplaceDicIDInCompStr(bossName);
end

function BOSSMSGLOG_GET_TIME()
	return GET_XM_HM_BY_SYSTIME();
end

function BOSSMSGLOG_GET_DEMON_LORD_GROUP(bossName)
	for index, group in pairs(g.demon_lords) do
		for _, dl in pairs(group) do
			if dl == bossName then
				return index;
			end
		end
	end

	return nil;
end

function BOSSMSGLOG_NOTICE_ON_MSG(frame, msg, argStr, argNum)
	_G["_BOSSMSGLOG_NOTICE_ON_MSG"](frame, msg, argStr, argNum);

	if msg == "NOTICE_Dm_!" then
		if argStr:find("LocalFieldBossDie") then
			local mapName = BOSSMSGLOG_MAP_NAME();
			local time = BOSSMSGLOG_GET_TIME();

			CHAT_SYSTEM("[" .. time .. " - " .. mapName .. "] " .. argStr);
		end
	elseif msg == "NOTICE_Dm_Global_Shout" then
		if argStr:find("!@#$FieldBoss{Name}WillAppear") then
			local bossName = BOSSMSGLOG_GET_FIELDBOSSWILLAPPEAR_NAME(argStr);
			local bossGroup = BOSSMSGLOG_GET_DEMON_LORD_GROUP(bossName);

			if bossGroup ~= nil then
				local time = BOSSMSGLOG_GET_TIME();

				g.bosses[bossGroup] = {};
				g.bosses[bossGroup].time = time;
				g.bosses[bossGroup].notice = imcTime.GetAppTime();
				g.bosses[bossGroup].message = "[" .. time .. "] " .. argStr;
			end
		end
	end
end

function BOSSMSGLOG_UPDATE(frame, msg, argStr, argNum)
	if (imcTime.GetAppTime() - g.timer) < g.interval then
		return;
	end

	g.timer = imcTime.GetAppTime();

	local i_time = 0;

	for group, info in pairs(g.bosses) do
		if info.notice ~= nil then
			if (g.timer - info.notice) < g.timeout then
				if i_time == 0 or (info.notice + g.spawn - g.timer) < i_time then
					i_time = (info.notice + g.spawn - g.timer);
				end
			else
				g.bosses[group].notice = nil;
			end
		end
	end

	BOSSMSGLOG_REFRESH_BOSSES();

	local text = GET_CHILD_RECURSIVELY(g.frame, "boss_timer");

	if i_time > 0 then
		text:SetText("{@st41_red}" .. math.floor(i_time/60)+1 .. "m");
	else
		text:SetText("");
	end
end

function BOSSMSGLOG_REFRESH_BOSSES()
	local visible = false;
	local tooltip = "";

	for group, info in pairs(g.bosses) do
		if tooltip ~= "" then
			tooltip = tooltip .. "{nl}";
		end

		tooltip = tooltip .. info.message;

		if visible == false and info.notice ~= nil then
			visible = true;
		end
	end

	local image = GET_CHILD_RECURSIVELY(g.frame, "boss_battle");
	image:SetTextTooltip(tooltip);

	if visible then
		BOSSMSGLOG_SETUP_UI(g.frame, 1);
	else
		BOSSMSGLOG_SETUP_UI(g.frame, 0);
	end
end
