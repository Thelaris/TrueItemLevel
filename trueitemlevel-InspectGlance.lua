--things to do--------------------------------------------
----------------------------------------------------------

	--[[

		- add addons option page
			- add options and function to handle option changes

		- Mists todo list:
			- might need to mod titan's grip code to verify specific weapon type in main hand (ie Two-Handed Axe)
			- check for new boa items (85-90) to calculate
			- work on group scan code (needs testing)
	--]]

--set public variables------------------------------------
----------------------------------------------------------

	--saved options (default values)
		local defaultConfig = {};
			defaultConfig.debugMode = false;
			defaultConfig.cacheSize = 1000;
			defaultConfig.cacheAge = 604800;	-- 7 days (in seconds)
			defaultConfig.inspectFreq = 2;
			defaultConfig.timeout = 5;			-- seconds to wait for data before failing the request
			defaultConfig.showSpec = true;
			defaultConfig.showTil = true;
			defaultConfig.showIcon = true;
			defaultConfig.showGlance = true;

	--colors
		local spec_c =		"ffffff";
		local til_c =		"00ccff";
		local boa_c =		"e6cc80";
		local pvp_c =		"a335ee";
		local miss_c =		"ff0000";
		local disabled_c =	"333333";

--set protected variables---------------------------------
----------------------------------------------------------

	--constants
		local version = "21MEI2014";
		local tag_prefix = "TIL";
		local tag_mouse = "TIL-MOUSE";
		local tag_statpage = "TIL-PLAYERSTATS";
		local tag_addon = "TIL[MOD]-";

		local msg_prefix = "|cff00ccff[TIL]:|r";
		local dbg_prefix = "|cff00ccff[TIL.DBG]:|r";
		local ttspec_prefix = "|cffffcc00Spec: |r".."|cffffffff";
		local ttilvl_prefix = "|cffffcc00TiL:|r".."|cffffffff ";
		local stats_description = "Your TIL value is the average item level of all equipped gear. It differs from Blizzard's calculations in that it also includes the approximate item level of BOA gear and can tell if a main-hand / off-hand is not equipped properly based on Talents such as Titan's Grip and other factors.";

		local gtt = GameTooltip;
		local GetTalentTabInfo = GetTalentTabInfo;

		local serverName = GetRealmName();

		local boa_cache = {
			[80] = {44102,42944,44096,42943,42950,48677,42946,42948,42947,42992,50255,44103,44107,44095,44098,44097,44105,42951,48683,48685,42949,48687,42984,44100,44101,44092,48718,44091,42952,48689,44099,42991,42985,48691,44094,44093,42945,48716},
			["sooflex"] = {105679,105673,105677,105672,105678,105671,105675,105670,105674,105680},
			["soonormal"] ={104405,104403,104406,104404,104401,104400,104402,104399,104409,104407},
			["sooheroic"]={105692,105686,105690,105685,105691,105684,105688,105683,105687,105693},
		};

		--[[
		local slots = {};
			slots[1] = 'head'; slots[2] = 'neck'; slots[3] = 'shoulder'; slots[4] = 'shirt'; slots[5] = 'chest'; slots[6] = 'belt'; slots[7] = 'legs'; slots[8] = 'feet'; slots[9] = 'wrist'; slots[10] = 'gloves'; slots[11] = 'finger1'; slots[12] = 'finger2'; slots[13] = 'trinket1'; slots[14] = 'trinket2'; 	slots[15] = 'back'; slots[16] = 'main hand'; slots[17] = 'off hand'; slots[18] = 'extra';
		--]]

		local slots = {};
			slots[1] = 'CharacterHeadSlot'; slots[2] = 'CharacterNeckSlot'; slots[3] = 'CharacterShoulderSlot';
			slots[5] = 'CharacterChestSlot'; slots[6] = 'CharacterWaistSlot'; slots[7] = 'CharacterLegsSlot'; slots[8] = 'CharacterFeetSlot';
			slots[9] = 'CharacterWristSlot'; slots[10] = 'CharacterHandsSlot'; slots[11] = 'CharacterFinger0Slot'; slots[12] = 'CharacterFinger1Slot';
			slots[13] = 'CharacterTrinket0Slot'; slots[14] = 'CharacterTrinket1Slot'; slots[15] = 'CharacterBackSlot'; slots[16] = 'CharacterMainHandSlot';
			slots[17] = 'CharacterSecondaryHandSlot'; slots[18] = 'CharacterRangedSlot';

	--other
		if (not cache) then
			cache = {};
		end

		local current = {};

		local addoncontrol = -1;
		local last_misscount = -1;
		local firedTalents, firedStarted = false, false;

		local lastInspectRequest = 0;
		local lastInspectTime;
		local scanning = false;
		local scanQueue = {};

		local tilStatFrame = nil;
		local searchText = "FILTER";

		local returnTable = {};
		local myCache = {};
		local returnCache = {};
		local tableCache = {};
		local timerstart = 0;
		local lastTime = -1;
		local timeoutCallbackFunc;
		local returnData;

--options page--------------------------------------------
----------------------------------------------------------

	--[[

	--register the page with the interface
		til_optionpage = {};
			til_optionpage.panel 		= 	CreateFrame("Frame", "til_optionpage1", UIParent);
			til_optionpage.panel.name 	= 	"True Item Level";
			til_optionpage.panel.okay 	= 	function (self) til_optionpageOnOkay(); end;
			til_optionpage.panel.cancel	= 	function (self)  til_optionpageOnCancel();  end;
			InterfaceOptions_AddCategory(til_optionpage.panel);

	--place objects into the options frame
		--coming soon notice
			local comingsoon = til_optionpage1:CreateFontString("comingsoon_label","OVERLAY");
			comingsoon:SetFontObject(GameFontNormalSmall);
			comingsoon:SetJustifyH("Center");
			comingsoon:ClearAllPoints();
			comingsoon:SetParent("til_optionpage1");
			comingsoon:SetPoint("CENTER", "til_optionpage1", "CENTER", 0, 0);
			comingsoon:SetText("Options page for 'True Item Level' is coming soon...");

	--handle button events
		function til_optionpageOnOkay(panel)
			--okay button was pressed (this also triggers the same event for the child addons)
		end

		function til_optionpageOnCancel(panel)
			--cancel button was pressed (this also triggers the same event for the child addons)
		end

	--]]

--configure addon frames----------------------------------
----------------------------------------------------------

	--frame wrapper for public functions
		tilpub = CreateFrame("Frame","tilpub");

	--font strings for "at a glance" option
	function AtAGlanceStrings()
		for i = 1,17 do
 			local reference = slots[i];
 			if (reference and _G[reference]) then
 				local entryString = _G[reference]:CreateFontString("tilGlanceText"..i,"OVERLAY","ListEntryStringTemplate");
					entryString:SetJustifyH("Left");
					entryString:SetPoint("BOTTOM",_G[reference],"BOTTOM");
					entryString:SetFont("Fonts\\FRIZQT__.TTF", 9, "THICKOUTLINE")
					entryString:SetText("|cff00ccff397|r");
					entryString:Show();
			end
		end
	end
	
	function AtAGlanceStringsInspect()
		for i = 1,19 do
 			local reference = GetInventoryItemLink("Target", i);
 			if (reference) then
 				local entryString = reference:CreateFontString("tilGlanceText"..i,"OVERLAY","ListEntryStringTemplate");
					entryString:SetJustifyH("Left");
					entryString:SetPoint("BOTTOM",reference,"BOTTOM");
					entryString:SetFont("Fonts\\FRIZQT__.TTF", 9, "THICKOUTLINE")
					entryString:SetText("|cff00ccff397|r");
					entryString:Show();
			end
		end
	end
	
	AtAGlanceStrings();

	--inspection frames (invisible)
		local til_inspect_timer = CreateFrame("Frame","til_inspect_timer");
		local til_inspect_ready = CreateFrame("Frame","til_inspect_ready");
		local til_inspect_timeout = CreateFrame("Frame","til_inspect_timeout");
		til_inspect_timer:Hide();
		til_inspect_ready:Hide();
		til_inspect_timeout:Hide();

		--configure the timeout frame
		til_inspect_timeout:SetScript("OnShow", function(self, ...)
			--start the timeout timer
			timerstart = time();
			tilpub:tildbg('|cff00ff00timer started|r');
		end);

		til_inspect_timeout:SetScript("OnHide", function(self, ...)
			tilpub:tildbg('|cff00ccfftimer hidden|r');
		end);

		til_inspect_timeout:SetScript("OnUpdate", function(self, ...)
			if(lastTime ~= time() - timerstart) then
				lastTime = time() - timerstart;
			end

			if (time() - timerstart >= tilConfig.timeout) then
				self:Hide();
				addoncontrol = -1;
				doCallback(addonTag,timeoutCallbackFunc,'failed','timeout',addoncontrol);
			end
		end);

		--add 'browse cache' tab to the til panel
		local tabIndexCache = tilui:addTab("|cff00ccffMy Cache|r");
			_G["tilFramePage"..tabIndexCache.."Header"]:SetText("|cff00ccffView My Cache|r");

		--add the 'characters' tab to the til panel
		local tabIndexCharacters = tilui:addTab("|cffe6cc80My Characters|r");
			_G["tilFramePage"..tabIndexCharacters.."Header"]:SetText("|cffe6cc80View My Characters|r");

		--[[
		--add 'my favorites' tab to the til panel
		local tabIndexFavorites = tilui:addTab("|cffffcc00My Favorites|r");
			_G["tilFramePage"..tabIndexFavorites.."Header"]:SetText("|cffffcc00View My Favorites|r");
		--]]

		--create the tables
		local tableSchema = {
		   {7,			7,			31,			15,			8,			8,			8,			8,			8		},	--column width percent
		   {"Lvl",		"Cls",		"Name",		"Spec",		"TIL",		"BOA", 		"PVP",		"MIA",		"AGE"	},	--column header
		   {"lvl",		"class",	"name",		"spec",		"til",		"boa",		"pvp",		"mia",		"stamp"	},	--what keys the column is looking for
		   {"level",	"class",	"class",	"aaaaaa",	til_c,		boa_c,		pvp_c,		miss_c,		"aaaaaa"},	--the color for each column in hex or special tag

		   { --table configuration options
			   sortCol		=	9,
			   sortMode		=	"desc",
			   classCol		=	2,
			   levelCol		=	1,
			   stampCol		=	9
		   }
		};

		tilui:createTable(tabIndexCache,tableSchema);

		local tableSchemaCharacters = {
		   {7,			7,			35,			19,			8,			8,			8,			8,			},	--column width percent
		   {"Lvl",		"Cls",		"Name",		"Spec",		"TIL",		"BOA", 		"PVP",		"MIA",		},	--column header
		   {"lvl",		"class",	"name",		"spec",		"til",		"boa",		"pvp",		"mia",		},	--what keys the column is looking for
		   {"level",	"class",	"class",	"aaaaaa",	til_c,		boa_c,		pvp_c,		miss_c,		},	--the color for each column in hex or special tag

		   { --table configuration options
			   sortCol		=	5,
			   sortMode		=	"desc",
			   classCol		=	2,
			   levelCol		=	1
		   }
		};
		tilui:createTable(tabIndexCharacters,tableSchemaCharacters);

		--tilui:createTable(tabIndexFavorites,tableSchema);

		--add ui elements to the tab page
		local parentName = ("tilFramePage"..tabIndexCache);

		-- string
		local cachelabel = _G[parentName]:CreateFontString("cachesizelabel","OVERLAY","ListEntryStringTemplate");
			cachelabel:SetJustifyH("Left");
			cachelabel:SetPoint("TOPLEFT","tilFramePage1ListRegion","BOTTOMLEFT",3,-10);
			cachelabel:Show();

		--search box (filter box)
		local searchBox = CreateFrame("EditBox","iconicSearchBox1",UIParent,"iconicSearchBoxTemplate");
			searchBox:SetParent(parentName);
			searchBox:SetPoint("TOPLEFT","tilFramePage"..tabIndexCache,"TOPLEFT",70,-42);
			local iconFrameName = ("iconicSearchBox1SearchIcon");
			searchBox:SetScript("OnShow",function(self,...)
				cachelabel:SetText('|cffffcc00Cache Size:|r |cff00ccff'..#cache..'|r |cffffcc00/'..tilConfig.cacheSize.."|r");
				self:SetTextInsets(16, 0, 0, 0);
				editBoxChanged(self,iconFrameName,true);
				self:HighlightText(0,0);
			end);
			searchBox:SetScript("OnEditFocusLost",function(self,...)
				editBoxChanged(self,iconFrameName,true);
			end);
			searchBox:SetScript("OnEditFocusGained",function(self,...)
				editBoxChanged(self,iconFrameName);
			end);
			searchBox:SetScript("OnTextChanged",function(self,...)
				--was OnEnterPressed
				tilSlashHandler(self:GetText(),"tilFrame");
			end);
			searchBox:SetScript("OnEnterPressed", function(self,...)
				self:ClearFocus();
			end);
			searchBox:SetScript("OnEscapePressed",function(self,...)
				self:ClearFocus();
			end);

			function editBoxChanged(frame,iconFrameName,focusLost)
				if (focusLost) then
					frame:SetTextColor(0.6,0.6,0.6);
					_G[iconFrameName]:SetVertexColor(0.6, 0.6, 0.6);
					if ( frame:GetText() == "" ) then
						frame:SetText(searchText);
					end
				else
					if ( frame:GetText() == searchText ) then
						frame:SetText("");
					else
						frame:HighlightText();
					end
					frame:SetTextColor(1,1,1);
					_G[iconFrameName]:SetVertexColor(1, 1, 1);
				end
			end;

			local refreshCacheViewButton = CreateFrame("Button","refreshCacheView",_G["tilFramePage"..tabIndexCache],"UIPanelButtonTemplate");
				refreshCacheViewButton:SetWidth(80);
				refreshCacheViewButton:SetHeight(20);
				refreshCacheViewButton:SetPoint("LEFT","iconicSearchBox1","RIGHT",0,0);
				refreshCacheViewButton:SetNormalFontObject("GameFontNormalSmall");
				refreshCacheViewButton:SetHighlightFontObject("GameFontNormalSmall");
				refreshCacheViewButton:SetDisabledFontObject("GameFontNormalSmall");
				refreshCacheViewButton:SetText("Refresh List");
				refreshCacheViewButton:SetScript("OnClick", function (self, ...)
					--show the frame
					tilFrame:Hide();
					tilFrame:Show();
				end)

			local clearCacheButton = CreateFrame("Button","clearCacheButton",_G["tilFramePage"..tabIndexCache],"UIPanelButtonTemplate");
				clearCacheButton:SetWidth(80);
				clearCacheButton:SetHeight(20);
				clearCacheButton:SetPoint("BOTTOMRIGHT","tilFramePage1ListRegion","BOTTOMRIGHT",25,-23);
				clearCacheButton:SetNormalFontObject("GameFontNormalSmall");
				clearCacheButton:SetHighlightFontObject("GameFontNormalSmall");
				clearCacheButton:SetDisabledFontObject("GameFontNormalSmall");
				clearCacheButton:SetText("Delete Cache");
				clearCacheButton:SetScript("OnClick", function (self, ...)
					--fill the data
					wipe(cache);

					--show the frame
					tilFrame:Hide();
					tilFrame:Show();
				end)

--set graphics--------------------------------------------
----------------------------------------------------------

	local tilicon_gfx1 = ("Interface\\AddOns\\TrueItemLevel\\gfx\\scanning1.tga");
	local tilicon_gfx2 = ("Interface\\AddOns\\TrueItemLevel\\gfx\\scanning2.tga");

	local tilicon = CreateFrame("Frame","tiliconframe",GameTooltip);
		tilicon:SetWidth(45);
		tilicon:SetHeight(45);
		local tilicon_texture = tilicon:CreateTexture(nil,"BACKGROUND");
			tilicon_texture:SetTexture(tilicon_gfx1);
			tilicon_texture:SetAllPoints(tilicon);
			tilicon.texture = tilicon_texture;
			tilicon:SetPoint("CENTER",GameTooltip,"BOTTOMLEFT",0,14);


--create stats page entry space---------------------------
----------------------------------------------------------

	local tilstatpage = CreateFrame("Frame", "tilstatpage", UIParent);
			tilstatpage:SetScript('OnEvent', function(self, event, ...) self[event](self, event, ...) end);
			tilstatpage:RegisterEvent("PLAYER_EQUIPMENT_CHANGED");
			tilstatpage:RegisterEvent("PLAYER_LOGIN");
			tilstatpage:RegisterEvent("VARIABLES_LOADED");

	function tilstatpage:VARIABLES_LOADED()
		--purge the cache of old entries
		purgeCache();

		--load defaults if not provided
		if (not tilConfig) then
			--tilConfig has not been set
			tilConfig = {};
			tilConfig = CopyTable(defaultConfig);
		else
			--tilConfig is set, but we should check to make sure each option has a value
			for key, value in pairs(defaultConfig) do
				if (not tilConfig[key] and tostring(tilConfig[key]) ~= "false") then
					--specific option was not set. load it from the defaults
					tilConfig[key] = defaultConfig[key];
				end
			end
		end
		tilpub:tilmsg("|cff00ccff[|r|cffee82ee"..version.."|r|cff00ccff]:|r Configuration Loaded");
	end

	function tilstatpage:PLAYER_LOGIN()
		--load any saved options and set ones not saved
		PAPERDOLL_STATINFO["TRUEITEMLEVEL"] = {
			updateFunc = function(statFrame, unit)
				tilStatFrame = statFrame;
				tilpub:gatherstats("player",tag_statpage,"statspage_scanupdate");
			end
		}
		tinsert(PAPERDOLL_STATCATEGORIES["GENERAL"].stats, "TRUEITEMLEVEL");

		tilpub:gatherstats("player",tag_statpage,"statspage_scanupdate");

		--show the cache in the cache window
		tilSlashHandler("", loadScreen)
	end

	function tilstatpage:PLAYER_EQUIPMENT_CHANGED()
		--hide all at a glance entries from the character panel
		for i = 1,17 do
 			if (_G["tilGlanceText"..i]) then
 				_G["tilGlanceText"..i]:Hide();
 			end
		end

		--regather player stats
		tilpub:gatherstats("player",tag_statpage,"statspage_scanupdate");
	end

--register slash commands---------------------------------
----------------------------------------------------------
	SLASH_trueitemlevelgroup1 = '/tilg';
	function groupilvl(msg)
		tilpub:gatherstats("player",tag_statpage,"statspage_scanupdate");
	end
	SlashCmdList["trueitemlevelgroup"] = groupilvl;

	SLASH_trueitemlevel_gui1 = '/tilw';
	function tilwSlashHandler(msg, editbox)
		if (_G["tilFrame"]:IsVisible()) then
			_G["tilFrame"]:Hide();
		else
			_G["tilFrame"]:Show();
		end
	end
	SlashCmdList["trueitemlevel_gui"] = tilwSlashHandler;


	SLASH_trueitemlevel1 = '/til';
	function tilSlashHandler(name, editbox)
		--we need to get a return on all matched data in the cache
		if (name == "" or name == searchText) then
			name = "%w";
		end

		if (editbox ~= "tilFrame" and name ~= "%w" and name ~= searchText) then
			iconicSearchBox1:SetText(name);
			tilui:tilFrameTabButtonHandler("tilFrameTab"..tabIndexCache);
		end

		tableCache = tilpub:matchCache(name,true);
		if (#tableCache > 0) then
			--matches found

			--fill the data
			tilui:fillTable(tabIndexCache,tableCache);
			wipe(tableCache);

			--show the frame
			tilFrame:Show();
		else
			--clear the table
			tilui:clearTable(tabIndexCache);
			if (not _G["tilFrame"]:IsVisible()) then
				tilpub:tilmsg('|cffffcc000 results for '..name..'|r');
			else
				--frame is visible - show results on frame?
			end
		end
	end
	SlashCmdList["trueitemlevel"] = tilSlashHandler;

	SLASH_trueitemlevel_cfg1 = '/tilcfg';
	local function handler_cfg(msg, editbox)
		if (msg == 'til') then
			if (not tilConfig.showTil) then
				tilConfig.showTil = true;
				tilpub:tilmsg('Tooltip TiL (|cff00ff00on|r)');
			else
				tilConfig.showTil = false;
				tilpub:tilmsg('Tooltip TiL (|cffff0000off|r)');
			end
		elseif (msg == 'spec') then
			if (not tilConfig.showSpec) then
				tilConfig.showSpec = true;
				tilpub:tilmsg('Tooltip Spec (|cff00ff00on|r)');
			else
				tilConfig.showSpec = false;
				tilpub:tilmsg('Tooltip Spec (|cffff0000off|r)');
			end
		elseif (msg == 'icon') then
			if (not tilConfig.showIcon) then
				tilConfig.showIcon = true;
				tilpub:tilmsg('Tooltip Scan Indicator Icon (|cff00ff00on|r)');
			else
				tilConfig.showIcon = false;
				tilpub:tilmsg('Tooltip Scan Indicator Icon (|cffff0000off|r)');
			end
		elseif (msg == 'glance') then
			if (not tilConfig.showGlance) then
				tilConfig.showGlance = true;
				tilpub:tilmsg('At A Glance Mode (|cff00ff00on|r)');
				tilpub:gatherstats("player",tag_statpage,"statspage_scanupdate");
			else
				tilConfig.showGlance = false;
				tilpub:tilmsg('At A Glance Mode (|cffff0000off|r)');
			for i =1,17 do
 					if (_G["tilGlanceText"..i]) then
 						_G["tilGlanceText"..i]:Hide();
 					end
				end
			end
		elseif (msg == 'debug') then
			if (not tilConfig.debugMode) then
				tilConfig.debugMode = true;
				tilpub:tilmsg('Debug Mode (|cff00ff00on|r)');
			else
				tilConfig.debugMode = false;
				tilpub:tilmsg('Debug Mode (|cffff0000off|r)');
			end
		end
	end
	SlashCmdList["trueitemlevel_cfg"] = handler_cfg;

	SLASH_trueitemlevel_help1 = '/tilhelp';
	local function handler_help(msg, editbox)
		tilpub:printHelp();
	end
	SlashCmdList["trueitemlevel_help"] = handler_help;

	function tilpub:printHelp()
		tilpub:tilmsg("|cffffcc00Slash Commands -----|r");
		tilpub:tilmsg("|cffffcc00/tilhelp|r : This Help Menu");
		tilpub:tilmsg("|cffffcc00/til <name>|r : Will show any cached TIL data for <name>");
		tilpub:tilmsg("|cffffcc00/tilw|r :|r Will toggle the TIL user interface on and off");
		tilpub:tilmsg("|cffffcc00/tilcfg til|r : Will toggle the visibility of the til on the unit tooltip");
		tilpub:tilmsg("|cffffcc00/tilcfg spec|r : Will toggle the visibility of the spec on the unit tooltip");
		tilpub:tilmsg("|cffffcc00/tilcfg icon|r : Will toggle the visibility of the inspection indicator icon on the unit tooltip");
		tilpub:tilmsg("|cffffcc00/tilcfg glance|r : Will toggle the visibility of the blue and orange 'at a glance' item levels located on the character panel");
		tilpub:tilmsg("|cffffcc00/tilt|r : Will display item level of a target");
		tilpub:tilmsg("|cffffcc00/tilr|r : Will display item level of all raid / party members");
		tilpub:tilmsg("|cffffcc00/tils|r : Will stop scanning item level of all raid / party members");
		tilpub:tilmsg("|cffffcc00/tilc|r : Will stop scanning item level of all raid / party members and clear the board");
	end

--create and manage hooks---------------------------------
----------------------------------------------------------

	gtt:HookScript("OnShow",function(self,...)
			tilicon:Hide();
	end);

	gtt:HookScript("OnTooltipSetUnit",function(self,...)
		tilpub:gatherstats("mouseover",tag_mouse,"mouse_scanupdate");
	end);

	hooksecurefunc("NotifyInspect", function(...)
		--this hook ensures that the inspections will always obey the inspecttion frequency we set
		--even if the notifyinspect is called by another addon
		lastInspectTime = (GetTime() - lastInspectRequest);
	end);

--scan event callbacks------------------------------------
----------------------------------------------------------

	function statspage_scanupdate(step, data)
		if (step == "items") then
			if (tilStatFrame and data.name and data.til and data.boa and data.mia and data.pvp) then
				PaperDollFrame_SetLabelAndText(tilStatFrame, "True Item Level (TiL)", "|cff00ccff"..data.til.."|r")
				tilStatFrame.tooltip = HIGHLIGHT_FONT_COLOR_CODE..format(PAPERDOLLFRAME_TOOLTIP_FORMAT, "|cffffffffTrue Item Level (TiL)|r")..FONT_COLOR_CODE_CLOSE.." |cff00ccff"..data.til.."|r";
				tilStatFrame.tooltip2 = stats_description;
				tilStatFrame:Show();

				--update at a glance entries with proper coloring
				for i = 1,17 do
 					if (_G["tilGlanceText"..i]) then
 						local glanceLevel = tonumber(_G["tilGlanceText"..i]:GetText());
 						if (glanceLevel and glanceLevel < data.til) then
							_G["tilGlanceText"..i]:SetTextColor(1,0.8,0,1);
						else
							_G["tilGlanceText"..i]:SetTextColor(0,0.8,1,1);
						end
					end
				end
			end
			tilpub:endControl(tag_statpage);
		end
	end

	function mouse_scanupdate(step, data, arg1)
		tilpub:tildbg(tag_mouse..": [|cff00ccff"..step.."|r] |cffffcc00fired|r")
		if (step ~= "failed") then
			if (step == "cache") then
				ttoutput(data);
			elseif (step == "started") then
				tilicon_texture:SetTexture(tilicon_gfx1);
				if (tilConfig.showIcon) then
					tilicon:Show();
				end
			elseif (step == 'rescanning') then
				tilicon_texture:SetTexture(tilicon_gfx2);
				if (tilConfig.showIcon) then
					tilicon:Show();
				end
			elseif (step == "talents") then
				ttoutput(data);
			elseif (step == "items") then
				ttoutput(data);
				tilicon:Hide();
			end
		else
			--something failed
			tilicon:Hide();

			if (data) then
				if (data == "interrupted" and arg1 == tag_mouse) then
					if (tilConfig.showIcon) then
						tilicon:Show();
					end
				end

				if (arg1) then
					tilpub:tildbg('failed: '..data..' ('..arg1..')');
				else
					tilpub:tildbg('failed: '..data);
				end
			end


			if (data == "busy") then
				--another addon has control, it's name is in the variable arg1
			elseif (data == "mismatch") then
				--the unit is no longer valid
				--gtt:SetUnit("mouseover");
			elseif (data == "inspectframe") then
				--the inspect frame is currently visable
			end

			tilpub:endControl(tag_mouse);
		end
	end

--primary function library--------------------------------
----------------------------------------------------------

	function resetVariables(reason,callbackFunc,unit)
		if (reason) then
			tilpub:tildbg("resetting variables: "..reason);
		end

		if (reason == "failed" or reason == "done") then
			--ensure we wipe the current unit when we are 100% done with them
			wipe(current);
			last_misscount = -1;
			firedTalents, firedStarted = false, false;
			til_inspect_timeout:Hide();
		else
			if (unit) then
				--a reset was done because a module has just requested a scan. We need to see if the unit needs to be reset
					if (UnitGUID(unit) ~= current.unit) then
						--the unit has changed, so we need to reset it
						wipe(current);
						current.unit = unit;
						_, current.class = UnitClass(unit);
						current.name = GetUnitName(unit,true);
						current.guid = UnitGUID(unit);
						last_misscount = -1;
						firedTalents, firedStarted = false, false;
					end
			end
		end
	end

	function configTag(addonTag)
		if (addonTag ~= tag_mouse and addonTag ~= tag_statpage) then
			-- look for "TIL[MOD]-" (tag_addon) at the beginning of the addon tag. if it isn't found then add it to the beginning
			local tagLoc = string.find(addonTag,tag_addon);
			if (tagLoc ~= 1) then
				--our tag hasn't been added to the addon tag yet
				addonTag = tag_addon..addonTag;
			end
		end

		return addonTag;
	end

	function tilpub:endControl(addonTag)
		addonTag = configTag(addonTag);
		if (addonTag == addoncontrol) then
			addoncontrol = -1;
			resetVariables("done");
			til_inspect_timeout:Hide();
		end
	end

	function tilpub:testcontrol(msg)
		addoncontrol = msg;
	end

	function tilpub:configTimer(unit,addonTag,callbackFunc)
		--setup the addon tag
		addonTag = configTag(addonTag);

		--prevent anything from happening if the inspect frame is up
			if (InspectFrame) then
				if (not InspectFrame.unit) then
					--fix a blizzard issue for when the inspectframe loses it's unit
					InspectFrame.unit = "player";
				end
				if (InspectFrame:IsVisible()) then
					doCallback(addonTag,callbackFunc,'failed','inspectframe');
					resetVariables('failed');
					return;
				end
				--AtAGlanceStrings();
				AtAGlanceStringsInspect();
				--gatherstats("player",tag_statpage,"statspage_scanupdate");
			end

		--configure timer for usage
			if (not firedStarted) then
				tilpub:tildbg('|cff00ccff--------------------------|r');
				tilpub:tildbg(addoncontrol..': |cff00ccffConfiguring timer for '..GetUnitName(unit,true).." - [|r|cffff8888"..UnitGUID(unit)..'|r|cff00ccff]|r');
			end

			til_inspect_ready:SetScript("OnEvent",function(event)
				self:Hide();
				til_inspect_timer:Hide();
				self:UnregisterEvent("INSPECT_READY");
				scanning = false;
				if (scanQueue.unit) then
					runScanQueue(callbackFunc);
					return;
				end

		--prevent anything from happening if the inspect frame is up
			if (InspectFrame) then
				if (not InspectFrame.unit) then
					--fix a blizzard issue for when the inspectframe loses it's unit
					InspectFrame.unit = "player";
				end
				if (InspectFrame:IsVisible()) then
					--this process cannot continue if the inspection frame is up. fire 'failed' and reset variables
					doCallback(addonTag,callbackFunc,'failed','inspectframe');
					resetVariables('failed');
					return;
				end
				AtAGlanceStringsInspect();
				--gatherstats("player",tag_statpage,"statspage_scanupdate");
			end

			if (UnitGUID(unit) == current.guid) then
				--here is where we start getting our details
				--let's get our talent tree first
				local specData = gatherspec(unit,addonTag,callbackFunc);
				if (specData.tree) then
					specData.level = UnitLevel(unit);
					cacheIt(specData,'talents');
				end

				if (callbackFunc and not firedTalents) then
					firedTalents = true;
					doCallback(addonTag,callbackFunc,'talents',specData);
				end

				--get the values of gathertil to figure out if we need to rescan or not
				local data = gathertil(unit,addonTag,callbackFunc);

				if (not data) then
					--nothing was returned?
				elseif (data.mia > 0) then
					--items may be missing
					if (last_misscount == -1) then
						--this is the first rescan
						last_misscount = data.mia;
						doCallback(addonTag,callbackFunc,'rescanning',data);
						tilpub:gatherstats(unit,addonTag,callbackFunc);
						return;
					else
						--this is a subsequent scan
						if (last_misscount ~= data.mia) then
							--missing data has changed
							last_misscount = data.mia;
							doCallback(addonTag,callbackFunc,'rescanning',data);
							tilpub:gatherstats(unit,addonTag,callbackFunc);
						else
							--no missing data, all missing gear is ACTUALLY mia

							--cache the data
							if (data.til and data.boa and data.pvp and data.mia) then
								data.level = UnitLevel(unit);
								cacheIt(data,'items');
							end

							--do callback
							doCallback(addonTag,callbackFunc,'items',data);

							return;
						end
						return
					end
				else
					--no missing items

					--cache the data
					if (data.til and data.boa and data.pvp and data.mia) then
						data.level = UnitLevel(unit);
						cacheIt(data,'items');
					end

					doCallback(addonTag,callbackFunc,'items',data);

					return;
				end
			else
				--will send callback 'mismatch', indicating to the module that the inspection data was tainted
				if (current.name and GetUnitName(unit,true)) then
					--print(current.name.." =/= "..GetUnitName(unit,true));
				elseif (current.name) then
					--print(current.name.." is no longer ID: '"..unit.."' (INSPECT_READY)");
				else
					--print("'"..unit.."' is nil");
				end
				resetVariables('failed',callbackFunc);
				doCallback(addonTag,callbackFunc,'failed','mismatch');
			end
		end);

		til_inspect_timer:SetScript("OnUpdate",function(self,elapsed)
			til_inspect_timer.nextUpdate = (til_inspect_timer.nextUpdate - elapsed);
			if (til_inspect_timer.nextUpdate <= 0) then
				self:Hide();

				if (UnitGUID(unit) == current.guid) then
					lastInspectRequest = GetTime();
					til_inspect_ready:RegisterEvent("INSPECT_READY");
					til_inspect_ready:Show();
					-- Fix the blizzard inspect copypasta code (Blizzard_InspectUI\InspectPaperDollFrame.lua @ line 23)
					if (current.unit) then
						--set timeout
						NotifyInspect(current.unit);
						scanning = true;
						til_inspect_timeout:Hide();
						til_inspect_timeout:Show();
					end

					if (callbackFunc and not firedStarted) then
						firedStarted = true;
						doCallback(addonTag,callbackFunc,'started');
					end
				else
					--will send callback 'mismatch', indicating to the module that the queued inspection failed
					if (current.name and GetUnitName(unit,true)) then
						--print(current.name.." =/= "..GetUnitName(unit,true));
					elseif (current.name) then
						--print(current.name.." is no longer ID: '"..unit.."' (NOTIFY_INSPECT)");
					else
						--print("'"..unit.."' is nil");
					end

					resetVariables('failed',callbackFunc);
					doCallback(addonTag,callbackFunc,'failed','mismatch');
				end
			end
		end);

		-- Queue an inspect request
		local isInspectOpen = (InspectFrame and InspectFrame:IsShown()) or (Examiner and Examiner:IsShown());
		if ((CanInspect(unit)) and (not isInspectOpen)) then
			current.unit = unit;
			_, current.class = UnitClass(unit);
			current.name = GetUnitName(unit,true);
			current.guid = UnitGUID(unit);
			lastInspectTime = (GetTime() - lastInspectRequest);
			til_inspect_timer.nextUpdate = (tilConfig.inspectFreq - lastInspectTime);
			til_inspect_timer:Show();
		else
			resetVariables('failed');
			doCallback(addonTag,callbackFunc,'failed','invalid');
		end
	end

	function runScanQueue(callbackFunc)
		if (scanQueue.addonTag ~= tag_mouse) then
			--print('running scanQueue for '..scanQueue.addonTag);
		end

		local scanGUID = scanQueue.guid;

		if (scanGUID and scanGUID == current.guid and scanQueue.unit == current.unit) then
			--queued unit is the same as the currently running unit
			local sUnit, sAddonTag, sCallback = scanQueue.unit, scanQueue.addonTag, scanQueue.callbackFunc;
			wipe(scanQueue);
			tilpub:gatherstats(sUnit, sAddonTag, sCallback);
		else
			--queued unit is different from the currently running unit
			resetVariables('failed');
			doCallback(addonTag,callbackFunc,'failed','interrupted',addoncontrol);
			local sUnit, sAddonTag, sCallback = scanQueue.unit, scanQueue.addonTag, scanQueue.callbackFunc;
			wipe(scanQueue);
			tilpub:gatherstats(sUnit, sAddonTag, sCallback);
		end
	end

	function tilpub:canControl(addonTag,callbackFunc,unit)
		--this function will decide if the requesting module can take control of the til engine

		--set variables
		addonTag = configTag(addonTag);
		local canControl = false;
		local resetVars = false;

		--can the module gain control? should we reset the variables?
		if (addoncontrol == addonTag) then
			--control is granted, but don't wipe the variables since the module has not changed
			canControl = true;
			resetVars = false;
		else
			--check to see if addon control is not set
			if (addoncontrol == -1) then
				--control is granted and variables are wiped since no modules are running
				canControl = true;
				resetVars = true;
			else
				--requesting module is competing for access
				--check to see if addoncontrol is our mouseover module
				if (addoncontrol == tag_mouse) then
					--control is granted and variables are wiped
					canControl = true;
					resetVars = true;
				end
			end
		end

		--reset variables if we need to
		if (resetVars) then
			resetVariables('setup',callbackFunc,unit);
		end

		--change control if we need to
		if ((canControl and not scanning) or (addoncontrol == -1)) then
			--pass control
			if (addoncontrol ~= addonTag) then
				tilpub:tildbg("control changed: |cff00ccff"..addoncontrol.."|r |cffffffff>|r |cff00ccff"..addonTag.."|r");
			end

			addoncontrol = addonTag;
			return true;
		elseif(scanning) then
			--we can attempt to queue the request to occur right after the current scan
			local canQueue = false;


			if (addonTag == tag_mouse) then
				--mouse module can only scan over itself or empty
				if (scanQueue.addonTag == tag_mouse or (not scanQueue.addonTag and addoncontrol == tag_mouse)) then
					canQueue = true;
				else
					canQueue = false;
				end
			elseif (not scanQueue or scanQueue.addonTag == addoncontrol) then
				--module is wanting to queue over itself or the queue was empty
				canQueue = true;
			elseif (addoncontrol == tag_mouse) then
				--modules can always queue over the mouse
				canQueue = true;
			end

			if (canQueue) then
				--we can queue a scan if the queue is empty or if the module wants to overwrite their own scan queue entry
				wipe(scanQueue);
				scanQueue.guid = UnitGUID(unit);
				scanQueue.unit = unit;
				scanQueue.addonTag = addonTag;
				scanQueue.callbackFunc = callbackFunc;
				tilpub:tildbg(addonTag..': queueing "'..scanQueue.unit..'" for when '..addoncontrol..' is done.');
			else
				doCallback(addonTag,callbackFunc,'failed','busy',addoncontrol);
					--print('busy, cant queue');
				return false;
			end
		end
	end


	function tilpub:gatherstats(unit,addonTag,callbackFunc)

		if (unit == "mouseover") then
			--if the unit requested is for the mouseover, then we need to make sure that the mouseover unit is set
			name, unit = GameTooltip:GetUnit();
			if (not unit) then
				local mFocus = GetMouseFocus();
				if (mFocus) and (mFocus.unit) then
					unit = mFocus.unit;
				end
			end
		end

		--attempt to load the unit from the cache before moving forward
		if (UnitExists(unit)) then
			--load cache if available
			if (myCache) then wipe(myCache); end
			myCache = tilpub:loadCache(unit,nil);
			if (myCache and myCache.name and callbackFunc) then
				doCallback(addonTag,callbackFunc,'cache',myCache);
			end
		end

		if (UnitExists(unit) and tilpub:canControl(addonTag,callbackFunc,unit)) then

			--kick the timeout timer into gear
			til_inspect_timeout:Show();
			timeoutCallbackFunc = callbackFunc;

			if (not UnitExists(unit)) then
				resetVariables("failed");
				doCallback(addonTag,callbackFunc,'failed','invalid');
			end

			if (UnitExists(unit) and CanInspect(unit)) then
				--we can safely assume that the requested unit is ready to be scanned
				if (UnitIsUnit(unit,"player")) then
					--we don't have to set up inspection queue, because player data is always available
					local specData, tilData;

					specData = gatherspec(unit,addonTag,callbackFunc);
					tilData = gathertil(unit,addonTag,callbackFunc);

					local lClass, eClass = UnitClass("player");

					local data = {
						["stamp"] = time(),
						["til"] = tilData.til,
						["boa"] = tilData.boa,
						["tree"] = specData.tree,
						["mia"] = tilData.mia,
						["name"] = (UnitName("player").." - "..serverName),
						["level"] = UnitLevel("player"),
						["class"] = eClass,
						["pvp"] = tilData.pvp
					};

					tilpub:getMyCharacters();
					doCallback(addonTag,callbackFunc,'items',data);
				else
					--the unit is not a player, so we need addon control to get inspection data
					tilpub:configTimer(unit,addonTag,callbackFunc);
				end
			else
				resetVariables("failed");
				doCallback(addonTag,callbackFunc,'failed','invalid');
			end
		else
			tilpub:tildbg(addonTag..' cannot take control from '..addoncontrol);
		end
	end

	function gatherspec(unit,addonTag,callbackFunc)
		local data;

		if (UnitIsUnit(unit,"player")) then
			--use a local data array instead of the global one
			data = {};
			isInspect = false;
		else
			--use the current unit (global array) data
			data = current;
			isInspect = true;
		end

		if (UnitLevel(unit) > 9) then
			if (UnitIsUnit(unit,"player")) then
				isInspect = false;
				currentSpec = GetSpecialization();
				specID = currentSpec and select(1, GetSpecializationInfo(currentSpec))
				_, specName = GetSpecializationInfoByID(specID);
			else
				isInspect = true;
				specID = GetInspectSpecialization(unit);
				_, specName = GetSpecializationInfoByID(specID);
			end

			data.tree = specName
 		end

		--if the unit was not the player, copy the data array variables into the currently scanning array
		if (not UnitIsUnit(unit,"player")) then
			current.tree = data.tree;
		else
			--unit is a player, so let's cache this info right away
			cacheIt(data,"talents",true);
		end

		--issue a callback with completed data
		if(callbackFunc) then
			--not player, so the callback is inside of our timer. Return the values
			return data;
		end
	end

	function gathertil(unit,addonTag,callbackFunc)
		local data = {};

		if (UnitIsUnit(unit,"player")) then
			--use a local data array instead of the global one
			isInspect = false;
		else
			--use the current unit (global array) data
			data = current;
			isInspect = true;
		end

		--set variables
		data.til = 0;
		data.boa = 0;
		data.pvp = 0;
		data.mia = 0;

		local link;
		local iLVL, count, mainHandILvl = 0,0,0; -- added mainHandILvl for Artifact OH weapon ilvl correction
		local twoHander, missingmain, missingoff, titansgrip = false, false, false, false;
		local lClass, eClass = UnitClass(unit);

		-- recursively look through equipment
		for i = 1,17 do
 			if (i ~= 4) then	--slot 4 is for a shirt which should not be counted
 				if (UnitIsUnit(unit,"player")) then
 					--we need to reference the unit by name
					link = GetInventoryItemLink(GetUnitName(unit,true),i);
				else
					--we need to reference the unit by the provided unitid
					link = GetInventoryItemLink(unit,i);
				end
				if (link) then
					--get the item info
					local iname,_,rarity,level,_,_,subtype,_,equiptype = GetItemInfo(link);
                    local ItemUpgradeInfo = LibStub("LibItemUpgradeInfo-1.0")
					level = ItemUpgradeInfo:GetUpgradedItemLevel(link);
					local stats = GetItemStats(link);

					--do two-handed check
					if (i == 16) then	--mainhand
						mainHandILvl = level;
						--is the item a two-hander?
						if (equiptype == "INVTYPE_2HWEAPON" or equiptype == "INVTYPE_RANGED" or equiptype == "INVTYPE_RANGEDRIGHT") then
							twoHander = true;
						else
							twoHander = false;
						end
 					end
					
					--7.X Artifact Off-Hand iLVL Fix
					if (i == 17 and rarity == 6) then 
						level = mainHandILvl;
					end


					--check other stats
					if (level) then
					print ("Slot=", i, " Level=", level, " Rarity=", rarity);
						--check for boa gear
						if (rarity == 7) then
							--boa gear
							level = boaILVL(UnitLevel(unit), link);
							data.boa = data.boa + 1;
							count = count + 1;
							iLVL = iLVL + level;
						else
							count = count + 1
							iLVL = iLVL + level

							--check if pvp (has resillience)
							for stat, value in pairs(stats) do
								if (stat == "ITEM_MOD_RESILIENCE_RATING_SHORT" or stat == "ITEM_MOD_PVP_POWER_SHORT") then
									data.pvp = data.pvp + 1;
									break;
								end
							end
						end
					end

					--TODO finish this
					if (UnitIsUnit(unit,"player") and _G["tilGlanceText"..i] and tilConfig.showGlance) then
						_G["tilGlanceText"..i]:SetText(level);
						_G["tilGlanceText"..i]:Show();
					end
				else
					--hide the glancetext data
					if (UnitIsUnit(unit,"player")) then
						_G["tilGlanceText"..i]:Hide();
					end

					--could not get item information, probably missing
					if (i==16) then
						missingmain = true;
					elseif (i==17) then
						missingoff = true;
					end

					--set titansGrip if available
					titansgrip = isTitansGrip(unit);

					--based on titansGrip, evaluate the equipped weapons
					if (i==17 and titansgrip) then
						--player has titan's grip, so we should count this as a missing item.
						count = count + 1;
						data.mia = data.mia + 1;
					else
						--player does not have titans grip. Check if they have a two-hander equipped.
						if (i==17 and twoHander == true) then
							--two hander equipped, so we can't ding them for the missing off-hand
						else
							--not a two hander so we need to ding them for missing a slot
							count = count + 1;
							data.mia = data.mia + 1;
						end
					end
				end
			end
		end
        --print("twohand",twoHander)
 		--make adjustments to the calculation based on above equipment evaluation
 		if (missingmain and missingoff and eClass ~= "ROGUE" and titansgrip == false) then
 			--if they are missing both main and offhand but can cover both by equipping a two-hander,
			--only count it against them once.
			data.mia = data.mia - 1;
			count = count - 1;
		end


		--set the item level average (TiL)
		if (count > 0) then
			data.til = floor((iLVL / count)*1)/1;
		else
			data.til = 0;
		end

		--if the unit was not the player, copy the data array variables into the currently scanning array
		if (not UnitIsUnit(unit,"player")) then
			current.til = data.til;
			current.boa = data.boa;
			current.pvp = data.pvp;
			current.mia = data.mia;
		else
			--unit is a player, so let's cache this info right away
			cacheIt(data,'items',true);
		end

		if(callbackFunc) then
			return data;
		end
	end

	function tilpub:GetActualItemLevel(link)
		--Credits for base table to: http://www.wowinterface.com/forums/showthread.php?t=45388
		local levelAdjust={ -- 11th item:id field and level adjustment
			["0"]=0,["1"]=8,["373"]=4,["374"]=8,["375"]=4,["376"]=4,
			["377"]=4,["379"]=4,["380"]=4,["445"]=0,["446"]=4,["447"]=8,
			["451"]=0,["452"]=8,["453"]=0,["454"]=4,["455"]=8,["456"]=0,
			["457"]=8,["458"]=0,["459"]=4,["460"]=8,["461"]=12,["462"]=16,
			["465"]=0,["466"]=4,["467"]=8,["469"]=4,["470"]=8,["471"]=12,
			["472"]=16,["491"]=0,["492"]=4,["493"]=8,["494"]=4,["495"]=8,
			["496"]=8,["497"]=12,["498"]=16,["504"]=12,["505"]=16,
		}
		local baseLevel = select(4,GetItemInfo(link))
		local upgrade = strmatch(link,":(%d+)\124h%[")
		if baseLevel and upgrade and levelAdjust[upgrade]  then
			return baseLevel + levelAdjust[upgrade]
		else
			return baseLevel
		end
	end

	function tilpub:getMyCharacters()
		--populates the my characters tab
		wipe(returnTable);
		returnTable = nil;
		returnTable = {}
		for i = #cache, 1, -1 do
			if (cache[i].locked == "PLAYER") then
				if (returnTable[#returnTable + 1]) then wipe(returnTable[#returnTable + 1]); end
				returnTable[#returnTable + 1] = {
		   			["lvl"] 	= 	cache[i].level,
					["class"]	=	cache[i].class,
					["name"]	=	cache[i].name,
					["til"]		=	cache[i].til,
					["spec"]	=	cache[i].tree,
					["boa"]		=	cache[i].boa,
					["pvp"]		=	cache[i].pvp,
					["mia"]		=	cache[i].mia,
				};
			end
		end

		tilui:fillTable(tabIndexCharacters,returnTable);
		wipe(returnTable);
	end

	function tilpub:matchCache(name,skipMyCharacters)
		--this function will return a table of search results
		wipe(returnTable);
		for i = #cache, 1, -1 do
			if (string.find(tilui:simpleString(cache[i].name), tilui:simpleString(name))) then

				--local sendName = string.gsub(cache[i].name," - "..serverName, "");

				if (cache[i].locked == "PLAYER" and skipMyCharacters) then
					--don't include my characters
				else
					returnTable[#returnTable + 1] = {
						["lvl"] 	= 	cache[i].level,
						["class"]	=	cache[i].class,
						["name"]	=	cache[i].name,
						["til"]		=	cache[i].til,
						["spec"]	=	cache[i].tree,
						["boa"]		=	cache[i].boa,
						["pvp"]		=	cache[i].pvp,
						["mia"]		=	cache[i].mia,
						["stamp"]	=	cache[i].stamp
					};
				end

				--if cached entry is on our server, remove the server text

			end
		end

		return returnTable;
	end

	function tilpub:loadCache(unit,name)

		--set variables
		local data = false;
		local matched = -1;
		local uName;
		local age;

		if (unit) then
			--the name was not provided, so we need to figure it out
			uName = GetUnitName(unit,true);
		else
			--the name was provided so let's make it capital
			uName = (name:gsub("^%l", string.upper));
		end

		--add our server name as a default
		local serverMatch = string.find(uName,' - ');
		if (serverMatch and serverMatch > 0) then
		else
			if serverName == nil then serverName="" end
			uName = (uName..' - '..serverName);
		end

		--purge outdated cache entries
		purgeCache();

		--look in the cache for the requested name
		for i = #cache, 1, -1 do
			if (string.lower(uName) == string.lower(cache[i].name)) then
				matched = i;
				break;
			end
		end

		if (matched ~= -1) then
			--get the current timestamp
			local nowStamp = tilpub:makeStamp();

			--return the stamp difference in seconds
			cache[matched].age = tilpub:GetStampDifference(cache[matched].stamp,nowStamp);

			--reformat the name for return purposes (without server name if they are on our server)
			uName = cache[matched].name;

			local serverFound = string.find(uName,serverName);
			if (serverFound and serverFound > 0) then
				sendName = strsub(uName,1,serverFound - 4);
			else
				sendName = uName;
			end

			wipe(returnCache);
			returnCache = CopyTable(cache[matched]);
			returnCache.name = sendName	;

			return returnCache;
		else
			return nil;
		end
	end

	function purgeCache()
		--remove all entries from the cache that are outdated
		for i = #cache, 1, -1 do
			if (not cache[i].locked) then
				local stampNow = tilpub:makeStamp();
				if (tilpub:GetStampDifference(cache[i].stamp,stampNow) >= tilConfig.cacheAge) then
					tremove(cache,i);
				end
			end
		end
	end

	function cacheIt(data,what,isPlayer)
		if (not (data.name) and not (isPlayer)) then
			return false;
		end

		--update the list if it's shown
		--[[ --too laggy, also could bother someone trying to scroll through a constantly updating list
		if (_G["tilFrame"]:IsVisible()) then
			tilSlashHandler(iconicSearchBox1:GetText(),"tilFrame");
		end
		--]]

		--handle the cache
		local unlockData = false;
		if (isPlayer) then
			--we need to fill in missing variables for the player
			data.name = GetUnitName("player",true);
			_, data.class = UnitClass("player");
			data.level = UnitLevel("player");

			--lock the data so the player can always til an alt
			data.locked = "PLAYER";
		else
			--set a flag to unlock the data if it's locked since it
			--isn't a player. IE: used a friends account and now
			--their data is always locked otherwise
			unlockData = true;
		end

		--get locked number
		local lockCount = 0;
		for i = #cache, 1, -1 do
			if (cache[i].locked) then
				lockCount = lockCount + 1;
			end
		end

		--purge outdated entries
		purgeCache();

		--set variables
		local matched = -1;
		local temp = {};

		--format the name
		local serverMatch = string.find(data.name,' - ');
		if (serverMatch and serverMatch > 0) then
			cachingName = data.name;
		else
			cachingName = (data.name..' - '..serverName);
		end

		--if the data is already in the cache, then update the cache's variables and copy it freshly to the cache
		for i = #cache, 1, -1 do
			if (cachingName == cache[i].name) then
				matched = i;
				cache[i].stamp = tilpub:makeStamp();
				cache[i].class = data.class;
				cache[i].name = cachingName;
				cache[i].level = data.level;

				if (unlockData) then
					cache[i].locked = nil;
				elseif (data.locked) then
					cache[i].locked = data.locked;
				end

				if (what == "talents") then
					if (data.tree) then
						cache[i].tree = data.tree;
					end
				elseif (what == "items") then
					if (data.til) then
						cache[i].til = data.til;
					end
					if (data.boa) then
						cache[i].boa = data.boa;
					end
					if (data.pvp) then
						cache[i].pvp = data.pvp;
					end
					if (data.mia) then
						cache[i].mia = data.mia;
					end
				end

				break;
			end
		end

		--remove the first cached entry if cache is oversized
		if (#cache > (tilConfig.cacheSize + lockCount)) then
			--recursively find the first unlocked entry
			local matched = false;

			for i = #cache, 1, -1 do
				if (not cache[i].locked) then
					matched = i;
				end
			end

			if (matched) then
				tremove(cache,matched);
			end
		end

		--manage the existing cache
		if (matched ~= -1) then
			--copy the cache into a temporary variable
			temp = cache[matched];

			--delete the old cache entry
			tremove(cache,matched);

			--add the temporary variable back into the cache freshly
			if (tilConfig.cacheSize > 0) then
				cache[#cache + 1] = CopyTable(temp);
			end
		else
			--add new data to the cache
			if (tilConfig.cacheSize > 0) then
				local index = #cache + 1;
				cache[index] = {};
				cache[index].class = data.class;
				cache[index].stamp = tilpub:makeStamp();
				cache[index].level = data.level;
				cache[index].name = cachingName;

				if (data.locked) then
					cache[index].locked = data.locked;
				end

				if (what == "talents") then
					if (data.tree) then
						cache[index].tree = data.tree;
					end
				elseif (what == "items") then
					if (data.til) then
						cache[index].til = data.til;
					end
					if (data.boa) then
						cache[index].boa = data.boa;
					end
					if (data.pvp) then
						cache[index].pvp = data.pvp;
					end
					if (data.mia) then
						cache[index].mia = data.mia;
					end
				end
			end
		end
	end

	function boaILVL(level, itemLink)
		local returnValue;
        if level == 100 then
            return 620;
        end

		if level > 80 then
			local _, _, _, _, itemId = string.find(itemLink, "|?c?f?f?(%x*)|?H?([^:]*):?(%d+):?(%d*):?(%d*):?(%d*):?(%d*):?(%d*):?(%-?%d*):?(%-?%d*):?(%d*):?(%d*)|?h?%[?([^%[%]]*)%]?|?h?|?r?");
			itemId = tonumber(itemId);

			-- Downgrade it to 80 if found
			for k,iid in pairs(boa_cache[80]) do
				if iid == itemId then
					level = 80;
				end
			end

			-- Check Garrosh BOA item
			for k,iid in pairs(boa_cache["sooflex"]) do
				if iid == itemId then
					return 556;
				end
			end
			for k,iid in pairs(boa_cache["soonormal"]) do
				if iid == itemId then
					return 569;
				end
			end
			for k,iid in pairs(boa_cache["sooheroic"]) do
				if iid == itemId then
					return 582;
				end
			end
		end

		if level > 80 then
			returnValue = (( level - 80) * 26.6) + 200;
		elseif level > 70 then
			returnValue = (( level - 70) * 10) + 100;
		elseif level > 60 then
			returnValue = (( level - 60) * 4) + 60;
		else
			returnValue = level;
		end
		return returnValue;
	end

	function isTitansGrip(unit)
		if (UnitClass(unit) == "Warrior" and UnitLevel(unit) >=37) then
			if (UnitIsUnit(unit,"player")) then
				isInspect = false;
				currentSpec = GetSpecialization();
				specID = currentSpec and select(1, GetSpecializationInfo(currentSpec))
			else
				isInspect = true;
				specID = GetInspectSpecialization(unit);
			end

			if (specID == "268") then --id 268 is the fury spec
				return true;
			end
		else
			return false;
		end
	end

--helper function library---------------------------------
----------------------------------------------------------

	function doCallback(addonTag, callbackFunc, step, data, arg1)
		returnData = nil;
		if (type(data) == "table") then
			returnData = {};
			returnData = CopyTable(data);
		else
			returnData = data;
		end

		if (returnData == 'timeout') then
			resetVariables('failed');
		elseif (step == "items") then
			resetVariables('done');
		end

		--[[
		if (addonTag == addoncontrol) then
			--reset the timeout frame since a callback was made
			til_inspect_timeout:Hide();
			til_inspect_timeout:Show();
		end
		--]]

		if (data and data.guid and UnitGUID(data.unit) ~= current.guid) then

		elseif (callbackFunc) then
			_G[callbackFunc](step, returnData, arg1);
		end
	end

	function tilpub:makeStamp()
		--get the current time since epoch in seconds
		return time();
	end

	function tilpub:GetStampDifference(providedStamp, nowStamp)
		local age = nowStamp - providedStamp;
		return age;
	end

-- output functions---------------------------------------
----------------------------------------------------------

	function ttoutput(data,what)
		local uName;
		local _, unit = GameTooltip:GetUnit();
		if (unit) then
			uName = GetUnitName(unit,true);
		end
		if (data.name and uName == data.name) then
			--the mouseover unit is still our unit, so begin output
			if (data and data.tree and tilConfig.showSpec) then
				local outputLine = (ttspec_prefix.."|cff"..spec_c..data.tree.."|r");

				--SPEC Line
				local matched = false;
				for i = 2, gtt:NumLines() do
					if ((_G["GameTooltipTextLeft"..i]:GetText() or ""):match("^"..ttspec_prefix)) then
						matched = true;
						index = i;
						break;
					else
						matched = false;
					end
				end

				if (matched) then
					_G["GameTooltipTextLeft"..index]:SetText(outputLine);
				else
					gtt:AddLine(outputLine);
 				end
 				GameTooltip:Show();
 			end

			if (data and data.til and data.boa and data.pvp and data.mia and tilConfig.showTil) then

				local til_l, boa_l, pvp_l, miss_l, outputLine;

				--TIL Line
				til_l = (ttilvl_prefix.."|cff"..til_c..data.til.."|r");

				--BOA Line
				if (data.boa > 0) then
					boa_l = (" |cff"..boa_c.." "..data.boa.." BOA|r");
				else
					boa_l = "";
				end

				--PVP Line
				if (data.pvp > 0) then
					pvp_l = (" |cff"..pvp_c.." "..data.pvp.." PVP|r");
				else
					pvp_l = "";
				end

				--MISS Line
				if (data.mia > 0) then
					miss_l = (" |cff"..miss_c.." "..data.mia.." MIA|r");
				else
					miss_l = "";
				end

				outputLine = (til_l..boa_l..pvp_l..miss_l);

				local matched = false;
				for i = 2, gtt:NumLines() do
					if ((_G["GameTooltipTextLeft"..i]:GetText() or ""):match("^"..ttilvl_prefix)) then
						matched = true;
						index = i;
						break;
					else
						matched = false;
					end
				end

				if (matched) then
					_G["GameTooltipTextLeft"..index]:SetText(outputLine);
				else
					gtt:AddLine(outputLine);
				end
				GameTooltip:Show();
			end
		end
	end

	function tilpub:tilmsg(msg)
		print(msg_prefix.." "..msg);
	end

	function tilpub:tildbg(msg)
		if (tilConfig.debugMode) then
			print(dbg_prefix.." "..msg);
		end
	end

	-- OT Check Raid Item Level
	SLASH_OTTIL_TILR1 = "/tilr"
	SLASH_OTTIL_TILS1 = "/tils"
	SLASH_OTTIL_TILT1 = "/tilt"
	SLASH_OTTIL_TILC1 = "/tilc"
	SLASH_OTTIL_TILSEND1 = "/tilsend"
	SLASH_OTTIL_TILSEND2 = "/tilsent"

	SlashCmdList["OTTIL_TILR"] = function()
		ottil(1);
	end

	SlashCmdList["OTTIL_TILS"] = function()
		ottil(0);
	end

	SlashCmdList["OTTIL_TILT"] = function()
		ottil2("target",1);
	end

	SlashCmdList["OTTIL_TILSEND"] = function(chatType)
		local otext = OTTILFrameText:GetText()
		if otext == nil then otext = "" end
		local otext2 = {strsplit("\n", otext)}
		for i = 1, #otext2 do
			if chatType == "" then SendChatMessage(otext2[i], "SAY")
			else SendChatMessage(otext2[i], chatType); end
		end
	end

	SlashCmdList["OTTIL_TILC"] = function()
		ottil(0);
		OTTILFrameText:SetText("")
	end

	local OTTIL = CreateFrame("Frame");
	local OTTIL_Unit="";
	local OTilvl=0;
	local OTmia=0;
	local OTTop=0;
	local OTCurrent=0;
	local OTRaidSW=false;
	function OTInspect(self,event,unit)
		OTTIL:UnregisterEvent("INSPECT_READY")
		if UnitExists(OTTIL_Unit) == 1 then
			OTilvl, OTmia = OTgathertil(OTTIL_Unit)
			if (OTmia == 0) then
				local ctext = OTilvl;
				local otext = OTTILFrameText:GetText();
				if otext == nil then otext = "" end
				OTTILFrameText:SetText(string.format("%s",otext..ctext.."\n"));
				if OTRaidSW then ottil(2); end
			else
				if (CanInspect(OTTIL_Unit)) then ottil2(OTTIL_Unit,0) end
			end
		end
	end

	OTTIL:SetScript("OnEvent", OTInspect)

	-- Condition
	-- 0: stop
	-- 1: restart
	-- 2: continue

	function ottil(condition)
		if IsInRaid() and condition ~= 0 then
			if (not OTRaidSW) or (condition == 1) then
				OTCurrent = 1;
				OTRaidSW = true;
				OTTILFrameText:SetText("Item level\n")
			else
				OTCurrent = OTCurrent + 1;
			end
			OTTop = GetNumGroupMembers();
			while (OTCurrent <=  OTTop) do
				OTTIL_Unit="raid"..OTCurrent;
				if CanInspect(OTTIL_Unit) then
					NotifyInspect(OTTIL_Unit);
					OTTIL:RegisterEvent("INSPECT_READY");
					local otext = OTTILFrameText:GetText();
					if otext == nil then otext = "" end
					OTTILFrameText:SetText(string.format("%s",otext..OTCurrent..". "..GetUnitName(OTTIL_Unit,""):gsub("%-.+", "")..":"));
					break;
				else
					local otext = OTTILFrameText:GetText();
					if otext == nil then otext = "" end
					OTTILFrameText:SetText(string.format("%s",otext..OTCurrent..GetUnitName(OTTIL_Unit,""):gsub("%-.+", "")..":failed\n"));
					OTCurrent = OTCurrent + 1;
				end
			end
			if (OTCurrent >  OTTop) then
				local otext = OTTILFrameText:GetText();
				if otext == nil then otext = "" end
				OTTILFrameText:SetText(string.format("%s",otext.."finished\n"));
				OTRaidSW = false;
			end
		else
			local inInstanceGroup = IsInGroup(LE_PARTY_CATEGORY_INSTANCE)
			if (inInstanceGroup or IsInGroup()) and condition ~= 0 then
				if (not OTRaidSW) or (condition == 1) then
					OTCurrent = 1;
					OTRaidSW = true;
					OTTILFrameText:SetText("Item level\n")
				else
					OTCurrent = OTCurrent + 1;
				end
				if inInstanceGroup then
					OTTop = GetNumGroupMembers(LE_PARTY_CATEGORY_INSTANCE)
				else
					OTTop = GetNumGroupMembers(LE_PARTY_CATEGORY_HOME)
				end
				while (OTCurrent <=  OTTop) do
					OTTIL_Unit="party"..OTCurrent;
					if OTCurrent == 5 then
						OTTIL_Unit = "player";
					end
					if CanInspect(OTTIL_Unit) then
						NotifyInspect(OTTIL_Unit);
						OTTIL:RegisterEvent("INSPECT_READY");
						local otext = OTTILFrameText:GetText();
						if otext == nil then otext = "" end
						OTTILFrameText:SetText(string.format("%s",otext..OTCurrent..". "..GetUnitName(OTTIL_Unit,""):gsub("%-.+", "")..":"));
						break;
					else
						local otext = OTTILFrameText:GetText();
						if otext == nil then otext = "" end
						OTTILFrameText:SetText(string.format("%s",otext..OTCurrent..". "..GetUnitName(OTTIL_Unit,""):gsub("%-.+", "")..":failed\n"));
						OTCurrent = OTCurrent + 1;
					end
				end
				if (OTCurrent >  OTTop) then
					local otext = OTTILFrameText:GetText();
					if otext == nil then otext = "" end
					OTTILFrameText:SetText(string.format("%s",otext.."finished\n"));
					OTRaidSW = false;
				end
			end
		end
		if (condition == 0) then
			--OTTILFrameText:SetText("")
			local otext = OTTILFrameText:GetText();
			if otext == nil then otext = "" end
			OTTILFrameText:SetText(string.format("%s",otext.."Stopped\n"));
			OTRaidSW=false
			OTTIL:UnregisterEvent("INSPECT_READY")
		end
	end
	-- condition:
	-- 1: target
	-- 0: normal
	function ottil2(unit, condition)
		local inInstanceGroup = IsInGroup(LE_PARTY_CATEGORY_INSTANCE)
		if not (IsInRaid() or inInstanceGroup or IsInGroup()) or (condition == 1) then OTRaidSW=false end
		OTTIL_Unit=unit;
		if CanInspect(OTTIL_Unit) then
			NotifyInspect(OTTIL_Unit);
			OTTIL:RegisterEvent("INSPECT_READY");
			if (condition == 1) then
				local otext = OTTILFrameText:GetText();
				if otext == nil then otext = "" end
				OTTILFrameText:SetText(string.format("%s",otext..GetUnitName(OTTIL_Unit,""):gsub("%-.+", "")..":"));
			end
		else
			local otext = OTTILFrameText:GetText();
			if otext == nil then otext = "" end
			OTTILFrameText:SetText(string.format("%s",otext.."failed\n"));
		end
	end

	function OTgathertil(unit)
		local data = {};

		if (UnitIsUnit(unit,"player")) then
			--use a local data array instead of the global one
			isInspect = false;
		else
			--use the current unit (global array) data
			data = current;
			isInspect = true;
		end

		--set variables
		data.til = 0;
		data.boa = 0;
		data.pvp = 0;
		data.mia = 0;

		local link;
		local iLVL, count = 0,0;
		local twoHander, missingmain, missingoff, titansgrip = false, false, false, false;
		local lClass, eClass = UnitClass(unit);

		-- recursively look through equipment
		for i = 1,17 do
 			if (i ~= 4) then	--slot 4 is for a shirt which should not be counted
 				if (UnitIsUnit(unit,"player")) then
 					--we need to reference the unit by name
					link = GetInventoryItemLink(GetUnitName(unit,true),i);
				else
					--we need to reference the unit by the provided unitid
					link = GetInventoryItemLink(unit,i);
				end
				if (link) then
					--get the item info
					local iname,_,rarity,level,_,_,subtype,_,equiptype = GetItemInfo(link);
					level = tilpub:GetActualItemLevel(link);
					local stats = GetItemStats(link);

					--do two-handed check
					if (i == 16) then	--mainhand
						--is the item a two-hander?
						if (equiptype == "INVTYPE_2HWEAPON" or equiptype == "INVTYPE_RANGED" or equiptype == "INVTYPE_RANGEDRIGHT") then
							twoHander = true;
						else
							twoHander = false;
						end
 					end


					--check other stats
					if (level) then
						--check for boa gear
						if (rarity == 7) then
							--boa gear
							level = boaILVL(UnitLevel(unit), link);
							data.boa = data.boa + 1;
							count = count + 1;
							iLVL = iLVL + level;
						else
							count = count + 1
							iLVL = iLVL + level

							--check if pvp (has resillience)
							for stat, value in pairs(stats) do
								if (stat == "ITEM_MOD_RESILIENCE_RATING_SHORT" or stat == "ITEM_MOD_PVP_POWER_SHORT") then
									data.pvp = data.pvp + 1;
									break;
								end
							end
						end
					end

					--TODO finish this
					if (UnitIsUnit(unit,"player") and _G["tilGlanceText"..i] and tilConfig.showGlance) then
						_G["tilGlanceText"..i]:SetText(level);
						_G["tilGlanceText"..i]:Show();
					end
				else
					--hide the glancetext data
					if (UnitIsUnit(unit,"player")) then
						_G["tilGlanceText"..i]:Hide();
					end

					--could not get item information, probably missing
					if (i==16) then
						missingmain = true;
					elseif (i==17) then
						missingoff = true;
					end

					--set titansGrip if available
					titansgrip = isTitansGrip(unit);

					--based on titansGrip, evaluate the equipped weapons
					if (i==17 and titansgrip) then
						--player has titan's grip, so we should count this as a missing item.
						count = count + 1;
						data.mia = data.mia + 1;
					else
						--player does not have titans grip. Check if they have a two-hander equipped.
						if (i==17 and twoHander == true) then
							--two hander equipped, so we can't ding them for the missing off-hand
						else
							--not a two hander so we need to ding them for missing a slot
							count = count + 1;
							data.mia = data.mia + 1;
						end
					end
				end
			end
		end
        --print("twohand",twoHander)
 		--make adjustments to the calculation based on above equipment evaluation
 		if (missingmain and missingoff and eClass ~= "ROGUE" and titansgrip == false) then
 			--if they are missing both main and offhand but can cover both by equipping a two-hander,
			--only count it against them once.
			data.mia = data.mia - 1;
			count = count - 1;
		end


		--set the item level average (TiL)
		if (count > 0) then
			data.til = floor((iLVL / count)*1)/1;
		else
			data.til = 0;
		end
		return data.til, data.mia;
	end
