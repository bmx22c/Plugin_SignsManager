namespace RenderLib
{
	bool InMapEditor() {
		CGameCtnEditorFree@ editor = cast<CGameCtnEditorFree>(GetApp().Editor);
		CGameCtnChallenge@ map = cast<CGameCtnChallenge>(GetApp().RootMap);

		if (map !is null && editor !is null) {
			return true;
		}
		return false;
	}

	void LoadingButton() {
		if (Time::get_Now() % 3000 > 2000) {
				UI::Button("Loading...");
		} else if (Time::get_Now() % 3000 > 1000) {
				UI::Button("Loading.. ");
		} else {
				UI::Button("Loading.  ");
		}
		if (UI::IsItemHovered()) infotext = "Parsing all blocks and items to generate the table. Please wait...";
	}

	void GenerateRow(Objects@ object) {
		UI::TableNextRow();
		UI::TableNextColumn();
		if(Setting_EnableCameraFocus){
			if (UI::Button(Icons::Search + "###" + object.name+object.id)) {
				if(individualList){
					FocusCam(object.name, object.positions[0]);
				}else{
					FocusCam(object.name);
				}
			}
			UI::SameLine();
		}

		UI::SameLine(); if (UI::IsItemHovered() && object.type == "Block" && cast<CGameEditorPluginMapMapType>(cast<CGameCtnEditorFree>(GetApp().Editor).PluginMapType) is null) infotext = "Editor plugins are disabled, the coordinates of the blocks are estimated and can be imprecise";
		UI::SameLine();
		switch(object.trigger){
			case CGameCtnBlockInfo::EWayPointType::Start:
				UI::Text("\\$9f9" + object.name);
				if (UI::IsItemHovered()) infotext = "It's a start block/item";
				break;
			case CGameCtnBlockInfo::EWayPointType::Finish:
				UI::Text("\\$f66" + object.name);
				if (UI::IsItemHovered()) infotext = "It's a finish block/item";
				break;
			case CGameCtnBlockInfo::EWayPointType::Checkpoint:
				UI::Text("\\$99f" + object.name);
				if (UI::IsItemHovered()) infotext = "It's a checkpoint block/item";
				break;
			case CGameCtnBlockInfo::EWayPointType::StartFinish:
				UI::Text("\\$ff6" + object.name);
				if (UI::IsItemHovered()) infotext = "It's a multilap block/item";
				break;
			default:
				UI::Text(object.name);
				break;
		}

		UI::TableNextColumn();
		// UI::Text("d");
		UI::SetNextItemWidth(250);
		if(!object.updateBg) UI::BeginDisabled();
		if(UI::BeginCombo("Background##"+object.name+object.id, GetFileName(object.bgSkin))){
			if(UI::Selectable("None", "None" == object.bgSkin)){
				object.bgSkin = "None";
				if(individualList){
					Skin skin;
					skin.bgSkin = object.bgSkin;
					skin.fgSkin = object.fgSkin;
					skin.updateBg = object.updateBg;
					skin.updateFg = object.updateFg;
					@skin.block = @object.block;
					if(object.updateBg) skin.Apply();
				}else{
					Sign sign;
					sign.bgSkin = object.bgSkin;
					sign.fgSkin = object.fgSkin;
					sign.updateBg = object.updateBg;
					sign.updateFg = object.updateFg;
					sign.objectName = object.name;
					@sign.obj = object;
					if(object.updateBg) startnew(CoroutineFunc(sign.ApplyOther));
				}
			}
			for(uint i=0;i<gameSkinList.Length;i++){
				if(object.type == "Item"){
					array<string> skinType = object.item.ItemModel.SkinDirectory.Split("\\");
					if((!gameSkinList[i].Contains("Skins\\Any\\Advertisement") || gameSkinList[i].StartsWith("Skins\\Any\\"+skinType[skinType.Length-2])) && (!gameSkinList[i].Contains("+111Y") || !gameSkinList[i].Contains("+111A"))){
						
						if(UI::Selectable(GetFileName(gameSkinList[i])+"##"+i, false)){
							object.bgSkin = gameSkinList[i];
							
							// if(individualList){
							// 	Skin skin;
							// 	skin.bgSkin = object.bgSkin;
							// 	skin.fgSkin = object.fgSkin; 
							// 	@skin.item = @object.item;
							// 	skin.Apply();
							// }
						}
					}
				}else{
					array<string> skinType = object.block.BlockModel.SkinDirectory.Split("\\");
					string dimensions = skinType[skinType.Length-2];
					bool isStage = false;
					if(object.block.BlockInfo.Name.StartsWith("Stand") || object.block.BlockInfo.Name.StartsWith("Stage")){
						isStage = true;
						dimensions = skinType[skinType.Length-3]+"\\"+skinType[skinType.Length-2];
					}
					if(((!isStage && !gameSkinList[i].Contains("Skins\\Any\\Advertisement")) || gameSkinList[i].StartsWith("Skins\\Any\\"+dimensions)) && (!gameSkinList[i].Contains("+111Y") || !gameSkinList[i].Contains("+111A"))){
						if(UI::Selectable(GetFileName(gameSkinList[i])+"##"+i, (gameSkinList[i] == object.bgSkin))){
							object.bgSkin = gameSkinList[i];
							if(object.bgSkin.ToLower().Contains(".zip")) object.bgSkin = "Skins\\Any\\"+dimensions+"\\"+GetFileName(object.bgSkin);

							if(individualList){
								Skin skin;
								skin.bgSkin = object.bgSkin;
								skin.fgSkin = object.fgSkin;
								skin.updateBg = object.updateBg;
								skin.updateFg = object.updateFg;
								@skin.block = @object.block;
								skin.Apply();
							}else{
								Sign sign;
								sign.bgSkin = object.bgSkin;
								sign.fgSkin = object.fgSkin;
								sign.updateBg = object.updateBg;
								sign.updateFg = object.updateFg;
								sign.objectName = object.name;
								@sign.obj = object;
								if(object.updateBg) startnew(CoroutineFunc(sign.ApplyOther));
							}
						}
					}
				}
			}
			for(uint i=0;i<userSkinList.Length;i++){
				if(object.type == "Item"){
					array<string> skinType = object.item.ItemModel.SkinDirectory.Split("\\");
					if((!userSkinList[i].Contains("Skins\\Any\\Advertisement") || userSkinList[i].StartsWith("Skins\\Any\\"+skinType[skinType.Length-2])) && (!userSkinList[i].Contains("+111Y") || !userSkinList[i].Contains("+111A"))){
						if(UI::Selectable(GetFileName(userSkinList[i])+"##"+i, false)){
							object.bgSkin = userSkinList[i];
						}
					}
				}else{
					array<string> skinType = object.block.BlockModel.SkinDirectory.Split("\\");string dimensions = skinType[skinType.Length-2];
					bool isStage = false;
					if(object.block.BlockInfo.Name.StartsWith("Stand") || object.block.BlockInfo.Name.StartsWith("Stage")){
						isStage = true;
						dimensions = skinType[skinType.Length-3]+"\\"+skinType[skinType.Length-2];
					}
					if(((!isStage && !userSkinList[i].Contains("Skins\\Any\\Advertisement")) || userSkinList[i].StartsWith("Skins\\Any\\"+dimensions)) && (!userSkinList[i].Contains("+111Y") || !userSkinList[i].Contains("+111A"))){
					// if((!userSkinList[i].Contains("Skins\\Any\\Advertisement") || userSkinList[i].StartsWith("Skins\\Any\\"+skinType[skinType.Length-2])) && (!userSkinList[i].Contains("+111Y") || !userSkinList[i].Contains("+111A"))){
						if(UI::Selectable(GetFileName(userSkinList[i])+"##"+i, (userSkinList[i] == object.bgSkin))){
							object.bgSkin = userSkinList[i];
							if(individualList){
								Skin skin;
								skin.bgSkin = object.bgSkin;
								skin.fgSkin = object.fgSkin;
								skin.updateBg = object.updateBg;
								skin.updateFg = object.updateFg;
								@skin.block = @object.block;
								if(object.updateBg) skin.Apply();
							}else{
								Sign sign;
								sign.bgSkin = object.bgSkin;
								sign.fgSkin = object.fgSkin;
								sign.updateBg = object.updateBg;
								sign.updateFg = object.updateFg;
								sign.objectName = object.name;
								@sign.obj = object;
								if(object.updateBg) startnew(CoroutineFunc(sign.ApplyOther));
							}
						}
					}
				}
			}
			UI::EndCombo();
		}
		if(!object.updateBg) UI::EndDisabled();
		UI::SameLine();
		object.updateBg = (UI::Checkbox("Update##"+object.name+object.id, object.updateBg));
		UI::TableNextColumn();
		
		UI::SetNextItemWidth(250);
		if(!object.updateFg) UI::BeginDisabled();
		if(UI::BeginCombo("Foreground##"+object.name+object.id, GetFileName(object.fgSkin))){
			if(UI::Selectable("None", "None" == object.fgSkin)){
				object.fgSkin = "None";
				if(individualList){
					Skin skin;
					skin.bgSkin = object.bgSkin;
					skin.fgSkin = object.fgSkin;
					skin.updateBg = object.updateBg;
					skin.updateFg = object.updateFg;
					@skin.block = @object.block;
					if(object.updateFg) skin.Apply();
				}else{
					Sign sign;
					sign.bgSkin = object.bgSkin;
					sign.fgSkin = object.fgSkin;
					sign.updateBg = object.updateBg;
					sign.updateFg = object.updateFg;
					sign.objectName = object.name;
					@sign.obj = object;
					if(object.updateFg) startnew(CoroutineFunc(sign.ApplyOther));
				}
			}
			for(uint i=0;i<gameSkinList.Length;i++){
				if(object.type == "Item"){
					array<string> skinType = object.item.ItemModel.SkinDirectory.Split("\\");
					if((!gameSkinList[i].Contains("Skins\\Any\\Advertisement") || gameSkinList[i].StartsWith("Skins\\Any\\"+skinType[skinType.Length-2])) && (gameSkinList[i].Contains("+111Y") || gameSkinList[i].Contains("+111A"))){
						if(UI::Selectable(GetFileName(gameSkinList[i]), false)){
							object.fgSkin = gameSkinList[i];

							// if(individualList){
							// 	Skin skin;
							// 	skin.bgSkin = object.bgSkin;
							// 	skin.fgSkin = object.fgSkin; 
							// 	@skin.item = object.item;
							// 	skin.Apply();
							// }
						}
					}
				}else{
					array<string> skinType = object.block.BlockModel.SkinDirectory.Split("\\");
					string dimensions = skinType[skinType.Length-2];
					bool isStage = false;
					if(object.block.BlockInfo.Name.StartsWith("Stand") || object.block.BlockInfo.Name.StartsWith("Stage")){
						isStage = true;
						dimensions = skinType[skinType.Length-3]+"\\"+skinType[skinType.Length-2];
					}
					if(((!isStage && !gameSkinList[i].Contains("Skins\\Any\\Advertisement")) || gameSkinList[i].StartsWith("Skins\\Any\\"+dimensions)) && (gameSkinList[i].Contains("+111Y") || gameSkinList[i].Contains("+111A"))){
						if(UI::Selectable(GetFileName(gameSkinList[i]), (gameSkinList[i] == object.fgSkin))){
							object.fgSkin = gameSkinList[i];
							if(object.fgSkin.Contains("+111A")) object.fgSkin = "Skins\\Any\\"+dimensions+"\\"+GetFileName(object.fgSkin);
							if(individualList){
								Skin skin;
								skin.bgSkin = object.bgSkin;
								skin.fgSkin = object.fgSkin;
								skin.updateBg = object.updateBg;
								skin.updateFg = object.updateFg;
								@skin.block = @object.block;
								if(object.updateFg) skin.Apply();
							}else{
								Sign sign;
								sign.bgSkin = object.bgSkin;
								sign.fgSkin = object.fgSkin;
								sign.updateBg = object.updateBg;
								sign.updateFg = object.updateFg;
								sign.objectName = object.name;
								@sign.obj = object;
								if(object.updateFg) startnew(CoroutineFunc(sign.ApplyOther));
							}
						}
					}
				}
			}
			for(uint i=0;i<userSkinList.Length;i++){
				if(object.type == "Item"){
					array<string> skinType = object.item.ItemModel.SkinDirectory.Split("\\");
					if((!userSkinList[i].Contains("Skins\\Any\\Advertisement") || userSkinList[i].StartsWith("Skins\\Any\\"+skinType[skinType.Length-2])) && (userSkinList[i].Contains("+111Y") || userSkinList[i].Contains("+111A"))){
						if(UI::Selectable(GetFileName(userSkinList[i]), false)){
							object.fgSkin = userSkinList[i];
						}
					}
				}else{
					array<string> skinType = object.block.BlockModel.SkinDirectory.Split("\\");
					if((!userSkinList[i].Contains("Skins\\Any\\Advertisement") || userSkinList[i].StartsWith("Skins\\Any\\"+skinType[skinType.Length-2])) && (userSkinList[i].Contains("+111Y") || userSkinList[i].Contains("+111A"))){
						if(UI::Selectable(GetFileName(userSkinList[i]), (userSkinList[i] == object.fgSkin))){
							object.fgSkin = userSkinList[i];
							if(individualList){
								Skin skin;
								skin.bgSkin = object.bgSkin;
								skin.fgSkin = object.fgSkin;
								skin.updateBg = object.updateBg;
								skin.updateFg = object.updateFg;
								@skin.block = @object.block;
								if(object.updateFg) skin.Apply();
							}else{
								Sign sign;
								sign.bgSkin = object.bgSkin;
								sign.fgSkin = object.fgSkin;
								sign.updateBg = object.updateBg;
								sign.updateFg = object.updateFg;
								sign.objectName = object.name;
								@sign.obj = object;
								if(object.updateFg) startnew(CoroutineFunc(sign.ApplyOther));
							}
						}
					}
				}
			}
			UI::EndCombo();
		}
		if(!object.updateFg) UI::EndDisabled();
		UI::SameLine();
		object.updateFg = (UI::Checkbox("Update##"+2+object.name+object.id, object.updateFg));
		// UI::Text("e");
		if(Setting_TableType) UI::TableNextColumn();
		if(Setting_TableType) UI::Text(object.type);
		if(Setting_TableSource) UI::TableNextColumn();
		if(Setting_TableSource) UI::Text(object.source);
		if(Setting_TableSize) UI::TableNextColumn();
		if(Setting_TableSize) {
			if (object.size == 0 && object.source != "In-Game" && object.source != "In TP") {
				UI::Text("\\$555" + Text::Format("%lld",object.size));
				if (UI::IsItemHovered()) infotext = "Impossible to get the size of this block/item";
			} else {
				if (object.icon) {
					UI::Text("\\$fc0" + Text::Format("%lld",object.size));
					if (UI::IsItemHovered()) infotext = "All items with size in orange contains the icon. You must re-open the map to have the real size.";
				} else {
					UI::Text(Text::Format("%lld",object.size));
				}
			}
		}

		if(Setting_TableCount) UI::TableNextColumn();
		if(Setting_TableCount) UI::Text(Text::Format("%lld",object.count));
	}

	void LoadingIndicator() {
		if(isScanning){
			if (Time::get_Now() % 400 > 300) {
				loadingText = " | " + spinner[0];
			} else if (Time::get_Now() % 400 > 200) {
				loadingText = " | " + spinner[1];
			} else if (Time::get_Now() % 400 > 100) {
				loadingText = " | " + spinner[2];
			} else {
				loadingText = " | " + spinner[3];
			}
		}else{
			loadingText = "";
		}
	}
}
