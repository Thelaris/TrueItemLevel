--things to do--------------------------------------------
----------------------------------------------------------

	--[[
	
	--]]


--ui initialization---------------------------------------
----------------------------------------------------------

	--frame wrapper for public functions
		tilui = CreateFrame("Frame","tilui");


--set public variables------------------------------------
----------------------------------------------------------

	local sortarrow_gfx = ("Interface\\AddOns\\TrueItemLevel\\gfx\\sortarrow.tga");
	local classTexture = ("Interface\\Glues\\CharacterCreate\\UI-CharacterCreate-Classes");
	local schemaOptionsLine = 5;
	local displayData = {};

--set protected variables---------------------------------
----------------------------------------------------------

	local savedSchemas = {};
	savedData = {};
	local savedScrolls = {};
	local workingSchema = {};
	local data = {};

--chat publishing functions-------------------------------
----------------------------------------------------------


		
--scrollbar functions-------------------------------------
----------------------------------------------------------

	function tilui:scrollerUpdate(tabIndex,offset)
		for i = 1, tilui:getEntryCount(tabIndex) do
			for col = 1, tilui:getHeaderCount(tabIndex) do
				local entryName = ('tilFramePage'..tabIndex..'ListRegionEntry'..i);
				local colName = ("tilFramePage"..tabIndex.."ListRegionEntry"..i.."Col"..col);
				
				--set the width of the text field to the width of the header field
				local maxWidth = _G['tilFramePage'..tabIndex..'ListRegionCol'..col..'HeaderMiddle']:GetWidth() + 
						_G['tilFramePage'..tabIndex..'ListRegionCol'..col..'HeaderRight']:GetWidth();
						
				_G[colName]:SetWidth(maxWidth);
				
				if (offset and savedData[tabIndex] and savedData[tabIndex][i + offset]) then
					local selection = savedData[tabIndex][i + offset][col];
					
					if (tostring(selection) == "nil" or tostring(selection) == "0") then
						_G[colName]:SetText("");
						
						_G[entryName]:Show();
					else
						--calculate the age short hand if stampCol is set, and then hide the colName, while showing the shorthand in colNameB
						if (savedSchemas[tabIndex][schemaOptionsLine].stampCol and col == savedSchemas[tabIndex][schemaOptionsLine].stampCol) then
							_G[colName]:SetText(tilui:getAgeShort(selection));
						else
							_G[colName]:SetText(tostring(selection));
							
							_G[entryName]:Show();
						end
					end
					
					--hide the class column and replace it with the class icon if classCol is set
					if (savedSchemas[tabIndex][schemaOptionsLine].classCol and col == savedSchemas[tabIndex][schemaOptionsLine].classCol) then
						--hide the column name while keeping it's data
						_G[colName]:Hide();
						
						--show and place the class icon
						local icon = ('tilFramePage'..tabIndex..'ListRegionEntry'..i.."Icon");
						_G[icon]:SetTexture(classTexture);
						_G[icon]:SetTexCoord(unpack(CLASS_ICON_TCOORDS[savedData[tabIndex][i + offset][savedSchemas[tabIndex][schemaOptionsLine].classCol]]));
						_G[icon]:ClearAllPoints();
						_G[icon]:SetPoint("LEFT",_G[colName],"LEFT",0,0);
						_G[icon]:Show();
						
					end
										
					--modify the colors of the entry if they were provided
					if (savedSchemas[tabIndex][4][col]) then
						if(savedSchemas[tabIndex][4][col] == "level" and savedSchemas[tabIndex][schemaOptionsLine].levelCol) then
							--we need to color this column by the level difference of it's value to the player
							local red, green, blue = tilui:levelColor(savedData[tabIndex][i + offset][savedSchemas[tabIndex][schemaOptionsLine].levelCol]);
							_G[colName]:SetTextColor(red, green, blue);
						elseif (savedSchemas[tabIndex][4][col] == "class" and savedSchemas[tabIndex][schemaOptionsLine].classCol) then
							--we need to color this column by the class
							local color = RAID_CLASS_COLORS[savedData[tabIndex][i + offset][savedSchemas[tabIndex][schemaOptionsLine].classCol]];
							_G[colName]:SetTextColor(color.r, color.g, color.b);
						else
							--hex colors were provided, lets get the rgb percent value of the hex color
							local red, green, blue = tilui:HexToRGBPerc(savedSchemas[tabIndex][4][col]);
							_G[colName]:SetTextColor(red, green, blue);
						end
					end
				else
					_G[entryName]:Hide();
				end
			end
		end
	end

--tab & page functions------------------------------------
----------------------------------------------------------
		
	function tilui:tilFrameTabButtonHandler(name,reset)
		--get the number of currently active tabs
		local tabCount = tilui:getTabCount();
		
		--hide all pages
		for i = 1,tabCount do
			local pageString = tostring("tilFramePage"..i);
			_G[pageString]:Hide();
		end
		
		if (reset) then
			_G["tilFramePage1"]:Show();
			PanelTemplates_SetTab(tilFrame, 1);
		else
			--set the active page
			local activeTabIndex = string.gsub(name, "tilFrameTab", "");
			_G["tilFramePage"..activeTabIndex]:Show();
			PanelTemplates_SetTab(tilFrame, tonumber(activeTabIndex));
		end
	end
	
	function tilui:addTab(label)
		local tabIndex = (tilui:getTabCount() + 1);
		local prevTabIndex = tilui:getTabCount();
		local frameName = ("tilFramePage"..tabIndex);
		local tabName = ("tilFrameTab"..tabIndex);
		
		--create the Page and Tab
		local tilPage = CreateFrame("Frame",frameName,tilFrame,"tilFrameContentTemplate",tabIndex);
		local tilTab = CreateFrame("Button",tabName,tilFrame,"tilFrameTabTemplate",tabIndex);

		if (tabIndex == 1) then
			--first tab being added
				tilTab:SetPoint("CENTER","tilFrame","BOTTOMLEFT",60,-14);
		else
			local relativeFrame = ("tilFrameTab"..prevTabIndex);
				tilTab:SetPoint("LEFT",relativeFrame,"RIGHT",-16,0);
		end				   
				   
		_G[tabName]:SetText(label);
		
		if (tilui:getTabCount() > 0) then
			local setAmount = tilui:getTabCount()
			PanelTemplates_SetNumTabs(_G["tilFrame"], setAmount);
		
			tilui:tilFrameTabButtonHandler(nil,true);		
		end
		
			--configure the scrollbar scripts
			local scrollBar = ("tilFramePage"..tabIndex.."ListRegionScroll");
			
			_G[scrollBar]:SetScript('OnShow', function(self, ...)
				local config = {};
				
				if (not savedScrolls[tabIndex]) then
					config.numItems = 1;
					config.numToDisplay = 1;
					config.valueStep = 1;
				else
					config.numItems = savedScrolls[tabIndex].numItems;
					config.numToDisplay = savedScrolls[tabIndex].numToDisplay;
					config.valueStep = savedScrolls[tabIndex].valueStep;
				end
				FauxScrollFrame_Update(_G[self:GetName()],config.numItems,config.numToDisplay,config.valueStep);
				local myOffset = FauxScrollFrame_GetOffset(_G[self:GetName()]);
				tilui:scrollerUpdate(tabIndex,myOffset);
			end);
			_G[scrollBar]:SetScript('OnVerticalScroll', function(self, offset, ...)
				FauxScrollFrame_OnVerticalScroll(_G[scrollBar], offset, 19, function()
					local myOffset = FauxScrollFrame_GetOffset(_G[self:GetName()]);
					tilui:scrollerUpdate(tabIndex,myOffset);
				end);
			end);
						
			_G[scrollBar]:Show();

		  
		return tabIndex;
	end


--data list functions-------------------------------------
----------------------------------------------------------

	function tilui:clearTable(tabIndex)
		if (savedData[tabIndex]) then
			wipe(savedData[tabIndex]);
			tilui:scrollerUpdate(tabIndex);
		end
	end

	function tilui:fillTable(tabIndex,data,resorting)
		wipe(displayData);
		wipe(workingSchema);
		workingSchema = CopyTable(savedSchemas[tabIndex]);
		local entryCount = tilui:getEntryCount(tabIndex);
		local columnCount = tilui:getHeaderCount(tabIndex);
		
		--copy the data array into our saved data and then display it on page and then configure the scrollbar
		if (not resorting) then
			for i = 1, columnCount do
				--we have the column number, so reference the current schema to see what key we are looking for
				local searchKey = workingSchema[3][i];
				for dataIndex = 1, #data do
					if (not displayData[dataIndex]) then displayData[dataIndex] = {}; end
					if (not displayData[dataIndex][i]) then displayData[dataIndex][i] = {}; end
					displayData[dataIndex][i] = data[dataIndex][searchKey];
				end
			end
		else
			--we are resorting a table, so let's grab it
			displayData = CopyTable(savedData[tabIndex]);
		end
		
		if (not savedData[tabIndex]) then savedData[tabIndex] = {}; end
		
		if (displayData) then
		
			--sort the table if a sort method was provided
			if (workingSchema[schemaOptionsLine].sortCol) then
				--sorting option was found. set the mode to descending if sortMode is not ascending
				if (not workingSchema[schemaOptionsLine].sortMode == "asc") then workingSchema[schemaOptionsLine].sortMode = "desc"; end
				tilui:sortTable(displayData, workingSchema[schemaOptionsLine].sortCol, workingSchema[schemaOptionsLine].sortMode, tabIndex);
			end
			
			--copy it into our saved list data
			savedData[tabIndex] = CopyTable(displayData);
			
			--update the scrollbar
		
				--configure the settings
				if (not savedScrolls[tabIndex]) then
					savedScrolls[tabIndex] = {};
				end
				
				savedScrolls[tabIndex].numItems = #savedData[tabIndex];
				savedScrolls[tabIndex].numToDisplay = entryCount;
				savedScrolls[tabIndex].valueStep = 19;
				
			local scrollFrame = ("tilFramePage"..tabIndex.."ListRegionScroll");
			_G[scrollFrame]:Hide();
			_G[scrollFrame]:Show();
		end
		data = nil;
	end
	
	function tilui:createTable(tabIndex, schema)
		--will add columns into the frameName's tab frame list region (including headers)
		local pageName = tostring("tilFramePage"..tostring(tabIndex));
		local listRegionName = tostring("tilFramePage"..tostring(tabIndex).."ListRegion");
		
		local index = 0;
		
		--read the schema (and save it if it isn't saved yet to savedSchemas array)

			if (not savedSchemas[tabIndex]) then
				--save the schema to our ui array (this should only happen once)
				savedSchemas[tabIndex] = CopyTable(schema);
			end
			
			local workingSchema = savedSchemas[tabIndex];
			
			for key, value in ipairs(workingSchema[1]) do
				--schema[1]: headerWidth; schema[2]: headerName; schema[3]: searchKey;
				
				index = index + 1;
				local index2 = index;
				--set our reference variables (just makes it easier to read using variable names)
				local headerPercent = workingSchema[1][key];
					local listWidth = _G["tilFramePage"..tostring(tabIndex).."ListRegion"]:GetWidth();
					local headerWidth = (listWidth * (headerPercent/100) - 8);
				local headerName = workingSchema[2][key];
				local buttonName = (listRegionName.."Col"..index.."Header");
					local lastButtonName = (listRegionName.."Col"..(index - 1).."Header");
						local text = (buttonName.."text");
						local middle = (buttonName.."Middle");
						local left = (buttonName.."Left");
						local right = (buttonName.."Right");
						local gfx = ("Interface\\FriendsFrame\\WhoFrame-ColumnTabs");
				
				--create the header button
				local frame = CreateFrame("Button",buttonName,UIParent,"ColumnButtonTemplate");
				
				--place the header button
				if (index == 1) then
					--put the header in the first spot
					_G[buttonName]:SetPoint("BOTTOMLEFT",listRegionName,"TOPLEFT",-2,1);
				else
					--put the header next to the previous one
					_G[buttonName]:SetPoint("LEFT",lastButtonName,"Right",-2,0);
				end
				
				--set the details of the header button
				_G[text]:SetText(headerName);
				_G[middle]:SetWidth(headerWidth);
				_G[buttonName]:SetWidth(headerWidth+10);
				_G[middle]:SetTexture(gfx);
				_G[left]:SetTexture(gfx);
				_G[right]:SetTexture(gfx);
				_G[buttonName]:SetParent(listRegionName);
				
				--set the scripts of the header button
				_G[buttonName]:SetScript("OnClick", function(self, ...)
					PlaySound("igMainMenuOptionCheckBoxOn");
					tilui:tilFrameHeaderButtonHandler(tabIndex, index2);					
				end);
				
				--create the sort arrow for the header button
					local sortarrow = CreateFrame("Frame",buttonName.."Arrow",_G[buttonName]);
					sortarrow:SetWidth(15);
					sortarrow:SetHeight(15);	
					local sortarrow_texture = sortarrow:CreateTexture(nil,"BACKGROUND");
						sortarrow_texture:SetTexture(sortarrow_gfx);
						sortarrow_texture:SetAllPoints(sortarrow);
						sortarrow_texture:SetVertexColor(1,.8,0,1);
						sortarrow.texture = sortarrow_texture;
					sortarrow:SetPoint("BOTTOM",_G[buttonName],"BOTTOM",0,-3);
					sortarrow.texture:SetRotation(math.pi);
					sortarrow:Hide();
				
				--create the entry buttons
					--find out how many buttons we can fit
					local entryHeight = 18;
					local spacerHeight = 1;
					local listRegionHeight = _G[listRegionName]:GetHeight();
					local maxEntries = floor(listRegionHeight/(entryHeight+spacerHeight));
					local evenTexture = { ["r"] = 1, ["b"] = 1, ["g"] = 1, ["a"] = .05};
					local oddTexture = { ["r"] = 1, ["b"] = 1, ["g"] = 1, ["a"] = .1};
					local thisTexture;
					
					local lineToggle = 0;
					for i = 1, maxEntries do
						if (lineToggle == 0) then
							--odd line
							lineToggle = 1;
							thisTexture = evenTexture;
						else
							--even line
							lineToggle = 0;
							thisTexture = oddTexture;
						end
						
						local buttonName = (listRegionName.."Entry"..i);
						if (not _G[buttonName]) then
							local button = CreateFrame("Button",buttonName,_G[listRegionName],"tilListEntryButtonTemplate");
							button:SetWidth(button:GetParent():GetWidth());
							button:SetHeight(entryHeight);
							
							button:SetBackdrop({bgFile = "Interface/Tooltips/UI-Tooltip-Background"});
							button:SetBackdropColor(thisTexture.r, thisTexture.g, thisTexture.b, thisTexture.a);
							
							--set the positioning
							if (i == 1) then
								--first entry
								button:SetPoint("TOPLEFT",listRegionName,"TOPLEFT",0,0);
							else
								--subsequent entry
								button:SetPoint("TOPLEFT",listRegionName.."Entry"..(i - 1),"BOTTOMLEFT",0,-1);
							end
							button:Hide();
						end
					end
			end
			
						
			--create strings for the number of headers.
			local columnCount = tilui:getHeaderCount(tabIndex);
			local entryCount = tilui:getEntryCount(tabIndex);
			
			for entry = 1, entryCount do
				--gets the entry button
				for column = 1, columnCount do
					--create a string for each column available
					local headerName = (listRegionName.."Col"..column.."Headertext");
					local parentName = (listRegionName.."Entry"..entry);
					local stringName = (parentName.."Col"..column);
					
					local entryString = _G[parentName]:CreateFontString(stringName,"OVERLAY","ListEntryStringTemplate");
						entryString:SetJustifyH("Left");
					
						--set positioning of the text.
						--horizontal positioning should be handled by the position of the headers
						--vertical positioning should be handled by the position of the entry button
						entryString:SetPoint("LEFT",headerName,"LEFT",0,0);
						
						--find out what the "center" of the entry button would be as an offset from the top
						local entryHeight = _G[parentName]:GetHeight();
						local stringHeight = entryString:GetHeight();
						local centralPoint = entryHeight - stringHeight;
						local yoffset = (centralPoint/2)/2;
						
						
						entryString:SetPoint("TOP",parentName,"TOP",0, yoffset*-1);
						
						entryString:SetText('|cff555555-|r');
						entryString:Show();
				end
			end
	end

--sorting functions---------------------------------------
----------------------------------------------------------

	function tilui:sortTable(data,col,mode,tabIndex)
		local headerCount = tilui:getHeaderCount(tabIndex);
		local arrow, orientation;
		
		--set the color and direction of the header sort arrow based on the mode
			--hide all of the arrows first
			for i = 1, headerCount do
				arrow = _G[('tilFramePage'..tabIndex..'ListRegionCol'..i..'HeaderArrow')];
				arrow:Hide();
			end
			
			--set the orientation of the arrow
			arrow = _G[('tilFramePage'..tabIndex..'ListRegionCol'..col..'HeaderArrow')];
			
			if (mode == "asc") then
				orientation = 0;
			else
				orientation = math.pi;
			end
			
			--show the arrow and set it's orientation
			arrow.texture:SetRotation(orientation);
			arrow:Show();
		
		--set the header text font colors
			--reset all fonts
			for i = 1, headerCount do
				local headerRef = ("tilFramePage"..tabIndex.."ListRegionCol"..i.."Headertext");
				_G[headerRef]:SetTextColor(1,1,1,1);
			end
			
			--set our font
			local sortHeader = ("tilFramePage"..tabIndex.."ListRegionCol"..col.."Headertext");
			_G[sortHeader]:SetTextColor(0,0.8,1,1);			table.sort(data, function (a,b)
				--set our comparison variables
				local sortA = a[col];
				local sortB = b[col];
				
				--make sure we don't have nil values
				if (not sortA) then
					sortA = 0;
				end
				if (not sortB) then
					sortB = 0;
				end
				--strip ascii for sorting purposes
				if (type(sortA) == "string") then
					sortA = tilui:simpleString(sortA);
					
				end
				
				if (type(sortB) == "string") then
					sortB = tilui:simpleString(sortB);
				end
				
				
				--make sure the 2 entries are both of the same type
				if (type(sortA) ~= type(sortB)) then
					sortA = tostring(sortA);
					sortB = tostring(sortB);
				end
				
				--sort the data based on the mode
				if (mode == "asc") then
					return (sortA < sortB);
				else
					return (sortA > sortB);
				end
			end);
	end

--helper function library---------------------------------
----------------------------------------------------------

	function tilui:getTabCount()
		local searching = true;
		local count = 0;
		local tabString;
		
		while searching do
			tabID = tostring(count + 1);
			if (_G["tilFrameTab"..tabID]) then
				count = count + 1;
			else
				searching = false;
			end
		end
		
		return count;
	end

	function tilui:getHeaderCount(tabIndex)
		local searching = true;
		local count = 0;
		
		while searching do
		local header = ("tilFramePage"..tabIndex.."ListRegionCol"..(count + 1).."Header");
			if (_G[header]) then
				count = count + 1;
			else
				searching = false;
			end
		end
		
		return count;
	end
	
	function tilui:getEntryCount(tabIndex)
		--tilFramePage1ListRegionEntry1
		local searching = true;
		local count = 0;
		
		while searching do
		local lookingFor = ("tilFramePage"..tabIndex.."ListRegionEntry"..(count + 1));
			if (_G[lookingFor]) then
				count = count + 1;
			else
				searching = false;
			end
		end
		
		return count;
	end
	
	function tilui:tilFrameHeaderButtonHandler(tabIndex, colIndex, data)
		if (savedSchemas[tabIndex][schemaOptionsLine].sortCol == colIndex) then
			--already sorting by this column, so change the mode
			if(savedSchemas[tabIndex][schemaOptionsLine].sortMode == "asc") then
				savedSchemas[tabIndex][schemaOptionsLine].sortMode = "desc";
			else
				savedSchemas[tabIndex][schemaOptionsLine].sortMode = "asc";
			end;
		end
		--set the schema sort column
		savedSchemas[tabIndex][schemaOptionsLine].sortCol = colIndex;
		
		--display the data
		tilui:fillTable(tabIndex,nil,true);
	end
	
--helper functions----------------------------------------
----------------------------------------------------------

	function tilui:getAgeShort(timestamp)
		local age = time() - timestamp;
		
			if (age >= 86400) then
				--show days
				return (((floor(age/86400)*1)/1).."d");
			elseif (age >= 3600) then
				--show hours
				return (((floor(age/3600)*1)/1).."h")
			elseif (age >= 60) then
				--show minutes
				return (((floor(age/60)*1)/1).."m")
			else
				--show seconds
				return (age.."s");
			end
	end
	
	function tilui:simpleString(name)
		--[[ too much overhead to convert ascii codes
		
		name = string.gsub(name, "Ã", "A");
		name = string.gsub(name, "Ä", "A");
		name = string.gsub(name, "Å", "A");
		name = string.gsub(name, "Ǻ", "A");
		name = string.gsub(name, "À", "A");
		name = string.gsub(name, "Á", "A");
		name = string.gsub(name, "Â", "A");
		name = string.gsub(name, "Ă", "A");
		name = string.gsub(name, "Ā", "A");
		name = string.gsub(name, "Ǟ", "A");
		name = string.gsub(name, "â", "a");
		name = string.gsub(name, "ä", "a");		
		name = string.gsub(name, "à", "a");
		name = string.gsub(name, "å", "a");
		name = string.gsub(name, "á", "a");
		name = string.gsub(name, "ã", "a");
		name = string.gsub(name, "ā", "a");
		name = string.gsub(name, "ă", "a");
		name = string.gsub(name, "ǟ", "a");
		name = string.gsub(name, "ǻ", "a");
		
		name = string.gsub(name, "Æ", "AE");
		name = string.gsub(name, "Ǽ", "AE");
		name = string.gsub(name, "æ", "ae");
		name = string.gsub(name, "ǽ", "ae");
		
		name = string.gsub(name, "ß", "B");
		name = string.gsub(name, "Ḃ", "B");
		name = string.gsub(name, "ḃ", "b");
		
		name = string.gsub(name, "Ç", "C");
		name = string.gsub(name, "Č", "C");
		name = string.gsub(name, "Ĉ", "C");
		name = string.gsub(name, "Ć", "C");
		name = string.gsub(name, "Ċ", "C");
		name = string.gsub(name, "ç", "c");
		name = string.gsub(name, "¢", "c");
		name = string.gsub(name, "ć", "c");
		name = string.gsub(name, "č", "c");
		name = string.gsub(name, "ĉ", "c");
		name = string.gsub(name, "ċ", "c");
		
		name = string.gsub(name, "Đ", "D");
		name = string.gsub(name, "Ð", "D");
		name = string.gsub(name, "Ḑ", "D");
		name = string.gsub(name, "Ď", "D");
		name = string.gsub(name, "Ḋ", "D");	
		name = string.gsub(name, "ḑ", "d");	
		name = string.gsub(name, "ď", "d");	
		name = string.gsub(name, "ḋ", "d");	
		name = string.gsub(name, "đ", "d");
		name = string.gsub(name, "ð", "d");
		
		name = string.gsub(name, "Ǳ", "DZ");
		name = string.gsub(name, "Ǆ", "DZ");
		name = string.gsub(name, "ǅ", "Dz");
		name = string.gsub(name, "ǲ", "Dz");
		name = string.gsub(name, "ǳ", "dz");
		name = string.gsub(name, "ǆ", "dz");
		
		name = string.gsub(name, "É", "E");
		name = string.gsub(name, "È", "E");
		name = string.gsub(name, "Ě", "E");
		name = string.gsub(name, "Ê", "E");
		name = string.gsub(name, "Ë", "E");
		name = string.gsub(name, "Ē", "E");
		name = string.gsub(name, "Ę", "E");
		name = string.gsub(name, "Ė", "E");
		name = string.gsub(name, "é", "e");
		name = string.gsub(name, "ê", "e");
		name = string.gsub(name, "ě", "e");
		name = string.gsub(name, "ë", "e");
		name = string.gsub(name, "è", "e");
		name = string.gsub(name, "ē", "e");
		name = string.gsub(name, "ę", "e");
		name = string.gsub(name, "ė", "e");
		
		name = string.gsub(name, "Ʒ", "E");
		name = string.gsub(name, "Ǯ", "E");
		name = string.gsub(name, "ǯ", "e");
		
		name = string.gsub(name, "Ḟ", "F");
		name = string.gsub(name, "ḟ", "f");
		name = string.gsub(name, "ƒ", "f");
		
		name = string.gsub(name, "ﬁ", "fi");
		name = string.gsub(name, "ﬂ", "fl");
		
		name = string.gsub(name, "Ǵ", "G");
		name = string.gsub(name, "Ģ", "G");
		name = string.gsub(name, "Ġ", "G");
		name = string.gsub(name, "Ǧ", "G");
		name = string.gsub(name, "Ĝ", "G");
		name = string.gsub(name, "Ǥ", "G");
		name = string.gsub(name, "ǵ", "g");
		name = string.gsub(name, "ģ", "g");
		name = string.gsub(name, "ǧ", "g");
		name = string.gsub(name, "ĝ", "g");
		name = string.gsub(name, "ġ", "g");
		name = string.gsub(name, "ǥ", "g");
		
		name = string.gsub(name, "Ĥ", "H");
		name = string.gsub(name, "Ħ", "H");
		name = string.gsub(name, "ĥ", "h");
		name = string.gsub(name, "ħ", "h");
		
		name = string.gsub(name, "Ì", "I");
		name = string.gsub(name, "Í", "I");
		name = string.gsub(name, "Î", "I");
		name = string.gsub(name, "Ĩ", "I");
		name = string.gsub(name, "Ï", "I");
		name = string.gsub(name, "Ī", "I");
		name = string.gsub(name, "Ĭ", "I");
		name = string.gsub(name, "Į", "I");
		name = string.gsub(name, "İ", "I");
		name = string.gsub(name, "ï", "i");
		name = string.gsub(name, "î", "i");
		name = string.gsub(name, "ĭ", "i");
		name = string.gsub(name, "ì", "i");
		name = string.gsub(name, "í", "i");
		name = string.gsub(name, "ĩ", "i");
		name = string.gsub(name, "ī", "i");
		name = string.gsub(name, "į", "i");
		name = string.gsub(name, "ı", "i");
		
		name = string.gsub(name, "Ĳ", "IJ");
		name = string.gsub(name, "ĳ", "ij");
		
		name = string.gsub(name, "Ĵ", "J");
		name = string.gsub(name, "ĵ", "j");
		
		name = string.gsub(name, "Ḱ", "K");
		name = string.gsub(name, "Ķ", "K");
		name = string.gsub(name, "Ǩ", "K");
		name = string.gsub(name, "ĸ", "K");
		name = string.gsub(name, "ḱ", "k");
		name = string.gsub(name, "ķ", "k");
		name = string.gsub(name, "ǩ", "k");
		
		name = string.gsub(name, "Ĺ", "L");
		name = string.gsub(name, "Ļ", "L");
		name = string.gsub(name, "Ľ", "L");
		name = string.gsub(name, "Ŀ", "L");
		name = string.gsub(name, "Ł", "L");
		name = string.gsub(name, "£", "L");
		name = string.gsub(name, "ĺ", "l");
		name = string.gsub(name, "ļ", "l");
		name = string.gsub(name, "ľ", "l");
		name = string.gsub(name, "ŀ", "l");
		name = string.gsub(name, "ł", "l");
		
		name = string.gsub(name, "Ǉ", "LJ");
		name = string.gsub(name, "ǈ", "Lj");
		name = string.gsub(name, "ǉ", "lj");
		
		name = string.gsub(name, "Ṁ", "M");
		name = string.gsub(name, "ṁ", "m");
		
		name = string.gsub(name, "Ñ", "N");
		name = string.gsub(name, "Ń", "N");
		name = string.gsub(name, "Ņ", "N");
		name = string.gsub(name, "Ŋ", "N");
		name = string.gsub(name, "ñ", "n");
		name = string.gsub(name, "ń", "n");
		name = string.gsub(name, "ņ", "n");
		name = string.gsub(name, "ŉ", "n");
		name = string.gsub(name, "ŋ", "n");
		
		name = string.gsub(name, "Ǌ ", "NJ");
		name = string.gsub(name, "ǋ", "Nj");
		name = string.gsub(name, "ǌ", "nj");
		
		name = string.gsub(name, "Ö", "O");
		name = string.gsub(name, "ô", "o");		
		name = string.gsub(name, "ö", "o");
		name = string.gsub(name, "ò", "o");
		name = string.gsub(name, "ó", "o");
		
		name = string.gsub(name, "Ü", "U");
		name = string.gsub(name, "ü", "u");
		name = string.gsub(name, "û", "u");
		name = string.gsub(name, "ù", "u");
		name = string.gsub(name, "ú", "u");
		
		name = string.gsub(name, "Ý", "Y");
		name = string.gsub(name, "ÿ", "y");
		name = string.gsub(name, "¥", "Y");
		
		name = string.gsub(name, "ž", "z");
		--]]
		name = string.lower(name);
		return name;
	end
	
--color conversion functions------------------------------
----------------------------------------------------------

	function tilui:levelColor(level)
		level = tonumber(level);
		local color = GetQuestDifficultyColor(level);
		return color.r, color.g, color.b;
	end
	
	function tilui:HexToRGBPerc(hex)
		local rhex, ghex, bhex = string.sub(hex, 1, 2), string.sub(hex, 3, 4), string.sub(hex, 5, 6)
		return tonumber(rhex, 16)/255, tonumber(ghex, 16)/255, tonumber(bhex, 16)/255
	end
	
	function tilui:HexToRGB(hex)
		local rhex, ghex, bhex
		if strlen(hex) == 6 then
			rhex, ghex, bhex = strmatch('([a-fA-F0-9]{2})([a-fA-F0-9]{2})([a-fA-F0-9]{2})', hex)
		elseif strlen(hex) == 3 then
			rhex, ghex, bhex = strmatch('([a-fA-F0-9])([a-fA-F0-9])([a-fA-F0-9])', hex)
			if rhex and ghex and bhex then
				rhex = rhex .. rhex
				ghex = ghex .. ghex
				bhex = bhex .. bhex
			end
		end
		if not (rhex and ghex and bhex) then
			return 0, 0, 0
		else
			return tonumber(rhex, 16), tonumber(ghex, 16), tonumber(bhex, 16)
		end
	end

	function tilui:RGBPercToHex(r, g, b)
		r = r <= 1 and r >= 0 and r or 0
		g = g <= 1 and g >= 0 and g or 0
		b = b <= 1 and b >= 0 and b or 0
		return string.format("%02x%02x%02x", r*255, g*255, b*255)
	end
	
	function tilui:rgbPercToHex(r, g, b)
		r = r <= 1 and r >= 0 and r or 0
		g = g <= 1 and g >= 0 and g or 0
		b = b <= 1 and b >= 0 and b or 0
		return string.format("%02x%02x%02x", r*255, g*255, b*255)
	end