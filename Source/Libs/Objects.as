class Objects { //Items or Blocks
	string name;
	int trigger; // CGameItemModel::EnumWaypointType or CGameCtnBlockInfo::EWayPointType
	string type;
	string source;
	int size;
	int count;
	bool icon;
	array<vec3> positions;
	string id = "";
	CGameCtnAnchoredObject @item;
	CGameCtnBlock @block;
	string bgSkin = "None";
	string fgSkin = "None";
	bool updateBg = true;
	bool updateFg = true;

	Objects(const string &in name, int trigger, bool icon, const string &in type, const string &in source, int size, vec3 pos, const string &in id, CGameCtnAnchoredObject @obj) {
		this.name = name;
		this.trigger = trigger;
		this.count = 1;
		this.type = type;
		this.icon = icon;
		this.source = source;
		this.size = size;
		this.positions = {pos};
		this.id = id;
		@this.item = obj;
	}
	Objects(const string &in name, int trigger, bool icon, const string &in type, const string &in source, int size, vec3 pos, const string &in id, CGameCtnBlock @obj) {
		this.name = name;
		this.trigger = trigger;
		this.count = 1;
		this.type = type;
		this.icon = icon;
		this.source = source;
		this.size = size;
		this.positions = {pos};
		this.id = id;
		@this.block = obj;
	}
}

array<string> gameSkinList = {};
array<string> userSkinList = {};

// Force to split the refresh functions to bypass the script execution delay on heavy maps
void RefreshBlocks() {
	auto map = GetApp().RootMap;

	if (map !is null) {
		// Blocks
		auto blocks = map.Blocks;

		// Editor plugin API for GetVec3FromCoord function
		auto pluginmaptype = cast<CGameEditorPluginMapMapType>(cast<CGameCtnEditorFree>(GetApp().Editor).PluginMapType);

		for(uint i = 0; i < blocks.Length; i++) {
			int idifexist = -1;
			string blockname;
			bool isofficial = true;
			blockname = blocks[i].BlockModel.IdName;
			if (blockname.ToLower().SubStr(blockname.Length - 22, 22) == ".block.gbx_customblock") {
				isofficial = false;
				blockname = blockname.SubStr(0, blockname.Length - 12);
			}

			vec3 pos;
			if (blocks[i].CoordX != 4294967295 && blocks[i].CoordZ != 4294967295) { // Not placed in free mapping
				if (pluginmaptype !is null) { // Editor plugin is available
					pos = pluginmaptype.GetVec3FromCoord(blocks[i].Coord);
				} else {
					pos.x = blocks[i].CoordX * 32 + 16;
					pos.y = (blocks[i].CoordY - 8) * 8 + 4;
					pos.z = blocks[i].CoordZ * 32 + 16;
				}
			} else {
				pos = Dev::GetOffsetVec3(blocks[i], 0x6c);
				// center the coordinates in the middle of the block
				pos.x += 16;
				pos.y += 4;
				pos.z += 16;
			}

			int index = objectsindex.Find(blockname);

			if(blocks[i].BlockModel.SkinDirectory.Contains("Any\\Advertisement")){
				if(individualList){
					int trigger = blocks[i].BlockModel.EdWaypointType;
					AddNewObject(blockname, trigger, "Block", pos, 0, isofficial, @blocks[i], blocks[i].IdName+i);
					objectsindex.InsertLast(blockname);
				}else{
					if (index >= 0) {
						objects[index].count++;
						objects[index].positions.InsertLast(pos);
					} else {
						int trigger = blocks[i].BlockModel.EdWaypointType;
						AddNewObject(blockname, trigger, "Block", pos, 0, isofficial, @blocks[i], "");
						objectsindex.InsertLast(blockname);
					}
				}
			}
			if (i % 100 == 0) yield(); // to avoid timeout
		}
	}
}

// Force to split the refresh functions to bypass the script execution delay on heavy maps
void RefreshItems() {
	// return;
	auto map = GetApp().RootMap;

	if (map !is null) {
		// Items
		auto items = map.AnchoredObjects;
		for(uint i = 0; i < items.Length; i++) {
			int idifexist = -1;
			string itemname = items[i].ItemModel.IdName;
			int fallbacksize = 0;
			bool isofficial = true;

			if (itemname.ToLower().SubStr(itemname.Length - 9, 9) == ".item.gbx") {
				isofficial = false;
				auto article = cast<CGameCtnArticle>(items[i].ItemModel.ArticlePtr);
				if (article !is null) {
					itemname = string(article.PageName) + string(article.Name) + ".Item.Gbx";
				} else {
					auto fid = cast<CSystemFidFile@>(GetFidFromNod(items[i].ItemModel));
					fallbacksize = fid.ByteSize;
				}
			}

			int index = objectsindex.Find(itemname);

			if(items[i].ItemModel.SkinDirectory.Contains("Any\\Advertisement")){
				if(individualList){
					int trigger = items[i].ItemModel.WaypointType;
					auto item = items[i];
					AddNewObject(itemname, trigger, "Item", items[i].AbsolutePositionInMap, fallbacksize, isofficial, @items[i], items[i].IdName+i);
					objectsindex.InsertLast(itemname);
				}else{
					if (index >= 0) {
						objects[index].count++;
						objects[index].positions.InsertLast(items[i].AbsolutePositionInMap);
					} else {
						int trigger = items[i].ItemModel.WaypointType;
						auto item = items[i];
						AddNewObject(itemname, trigger, "Item", items[i].AbsolutePositionInMap, fallbacksize, isofficial, @items[i], "");
						objectsindex.InsertLast(itemname);
					}
				}
			}
			if (i % 100 == 0) yield(); // to avoid timeout
		}
	}
}

void AddNewObject(const string &in objectname, int trigger, const string &in type, vec3 pos, int fallbacksize, bool isofficial, CGameCtnBlock @block, const string &in id = "") {
	bool icon = false;
	int size;
	string source;
	CSystemFidFile@ file;
	CGameCtnCollector@ collector;
	CSystemFidFile@ tempfile;

	if (type == "Item" && Regex::IsMatch(objectname, "^[0-9]*/.*.zip/.*", Regex::Flags::None)) {//  ItemCollections
		source = "Club";
		@file = Fids::GetFake('MemoryTemp\\FavoriteClubItems\\' + objectname);
		@collector = cast<CGameCtnCollector>(cast<CGameItemModel>(file.Nod));
		if (collector is null || (collector.Icon !is null || file.ByteSize == 0)) {
			@tempfile = Fids::GetFake('MemoryTemp\\CurrentMap_EmbeddedFiles\\ContentLoaded\\ClubItems\\' + objectname);
		}
	} else { // Blocks and Items
		source = "Local";
		@file = Fids::GetUser(type + 's\\' + objectname);
		@collector = cast<CGameCtnCollector>(cast<CGameItemModel>(file.Nod));
		if (collector is null || (collector.Icon !is null || file.ByteSize == 0)) {
			@tempfile = Fids::GetFake('MemoryTemp\\CurrentMap_EmbeddedFiles\\ContentLoaded\\' + type + 's\\' + objectname);

			if (type == "Block" && tempfile.ByteSize == 0) { // Block is in Items dir
				@tempfile = Fids::GetFake('MemoryTemp\\CurrentMap_EmbeddedFiles\\ContentLoaded\\Items\\' + objectname);
			}
		}
	}
	if (tempfile !is null) {
		if (collector !is null && collector.Icon !is null && tempfile.ByteSize == 0) {
			icon = true;
			size = file.ByteSize;
		} else  {
			size = tempfile.ByteSize;
		}
		if (isofficial) {
			source = "In-Game";
		} else if (file.ByteSize == 0 && tempfile.ByteSize == 0 && fallbacksize == 0) {
#if TMNEXT
			source = "Local";
#else
			source = "In TP";
#endif
		} else if (file.ByteSize == 0 && tempfile.ByteSize == 0 && fallbacksize > 0 ) {
			source = "Embedded";
			size = fallbacksize;
		} else if (file.ByteSize == 0 && tempfile.ByteSize > 0) {
			source = "Embedded";
		}
	} else {
		size = file.ByteSize;
	}

	objects.InsertLast(Objects(objectname, trigger, icon, type, source, size, pos, id, block));
}

void AddNewObject(const string &in objectname, int trigger, const string &in type, vec3 pos, int fallbacksize, bool isofficial, CGameCtnAnchoredObject @item, const string &in id = "") {
	bool icon = false;
	int size;
	string source;
	CSystemFidFile@ file;
	CGameCtnCollector@ collector;
	CSystemFidFile@ tempfile;

	if (type == "Item" && Regex::IsMatch(objectname, "^[0-9]*/.*.zip/.*", Regex::Flags::None)) {//  ItemCollections
		source = "Club";
		@file = Fids::GetFake('MemoryTemp\\FavoriteClubItems\\' + objectname);
		@collector = cast<CGameCtnCollector>(cast<CGameItemModel>(file.Nod));
		if (collector is null || (collector.Icon !is null || file.ByteSize == 0)) {
			@tempfile = Fids::GetFake('MemoryTemp\\CurrentMap_EmbeddedFiles\\ContentLoaded\\ClubItems\\' + objectname);
		}
	} else { // Blocks and Items
		source = "Local";
		@file = Fids::GetUser(type + 's\\' + objectname);
		@collector = cast<CGameCtnCollector>(cast<CGameItemModel>(file.Nod));
		if (collector is null || (collector.Icon !is null || file.ByteSize == 0)) {
			@tempfile = Fids::GetFake('MemoryTemp\\CurrentMap_EmbeddedFiles\\ContentLoaded\\' + type + 's\\' + objectname);

			if (type == "Block" && tempfile.ByteSize == 0) { // Block is in Items dir
				@tempfile = Fids::GetFake('MemoryTemp\\CurrentMap_EmbeddedFiles\\ContentLoaded\\Items\\' + objectname);
			}
		}
	}
	if (tempfile !is null) {
		if (collector !is null && collector.Icon !is null && tempfile.ByteSize == 0) {
			icon = true;
			size = file.ByteSize;
		} else  {
			size = tempfile.ByteSize;
		}
		if (isofficial) {
			source = "In-Game";
		} else if (file.ByteSize == 0 && tempfile.ByteSize == 0 && fallbacksize == 0) {
#if TMNEXT
			source = "Local";
#else
			source = "In TP";
#endif
		} else if (file.ByteSize == 0 && tempfile.ByteSize == 0 && fallbacksize > 0 ) {
			source = "Embedded";
			size = fallbacksize;
		} else if (file.ByteSize == 0 && tempfile.ByteSize > 0) {
			source = "Embedded";
		}
	} else {
		size = file.ByteSize;
	}

	objects.InsertLast(Objects(objectname, trigger, icon, type, source, size, pos, id, item));
}

void ScanGameSigns(CSystemFidsFolder@ fidsFolder) {
    if (fidsFolder !is null)
    {
        for (uint i = 0; i < fidsFolder.Trees.Length; i++)
        {
            ScanGameSigns(cast<CSystemFidsFolder>(fidsFolder.Trees[i]));
        }
        for (uint i = 0; i < fidsFolder.Leaves.Length; i++)
        {
				auto parentFolder = fidsFolder.Leaves[i].ParentFolder;
				string path = "";
				if(parentFolder.DirName == "Reversible"){
					path = "Reversible\\" + path;
				}
				path = ParentUntilSkin(@parentFolder, path+fidsFolder.Leaves[i].FileName);
				if(path.Contains("Skins\\Any")){
					gameSkinList = AddUniqueGameSkin(gameSkinList, path);
					// gameSkinList.InsertLast(path);
				}
        }
    }
}

array<string> AddUniqueGameSkin(array<string> gameSkinList, const string &in path){
	bool inArray = false;
	for(int i = 0; i < gameSkinList.Length; i++){
		if(path.ToLower() == gameSkinList[i].ToLower()) inArray = true;
	}

	if(!inArray) gameSkinList.InsertLast(path);
	return gameSkinList;
}

void ScanUserSigns(CSystemFidsFolder@ fidsFolder) {
    if (fidsFolder !is null)
    {
        for (uint i = 0; i < fidsFolder.Trees.Length; i++)
        {
            ScanUserSigns(cast<CSystemFidsFolder>(fidsFolder.Trees[i]));
        }
        for (uint i = 0; i < fidsFolder.Leaves.Length; i++)
        {
				// auto parentFolder = fidsFolder.Leaves[i].ParentFolder;
				// string path = "";
				// if(parentFolder.DirName == "Reversible"){
				// 	path = "Reversible\\" + path;
				// }
				// path = ParentUntilSkin(@parentFolder, path+fidsFolder.Leaves[i].FileName);
				if(fidsFolder.Leaves[i].FullFileName.Contains("Skins\\Any\\Advertisement")){
					array<string> path = string(fidsFolder.Leaves[i].FullFileName).Split("Skins\\");
					for(uint j=0;j<path.Length;j++){
						if(path[j].StartsWith("Any\\Advertisement") && AcceptedFileExt(path[j])){
							userSkinList.InsertLast("Skins\\"+path[j]);
						}
					}
					// userSkinList.InsertLast(path);
				}
        }
    }
}

bool AcceptedFileExt(const string &in fileName){
	if(
		fileName.ToLower().EndsWith(".jpg")
		|| fileName.ToLower().EndsWith(".jpeg")
		|| fileName.ToLower().EndsWith(".png")
		|| fileName.ToLower().EndsWith(".webm")
	){
		return true;
	}else{
		return false;
	}
}

string ParentUntilSkin(CSystemFidsFolder @folder, const string &in path){
	if(folder.DirName == "Skins"){
		return path;
	}else{
		auto parent = folder.ParentFolder;
		string tmpPath = parent.DirName + "\\" + path;
		return ParentUntilSkin(parent, tmpPath);
	}
}

bool FocusCam(const string &in objectname, const vec3 &in pos = vec3(0,0,0)) {
	auto editor = cast<CGameCtnEditorFree>(GetApp().Editor);
	auto camera = editor.OrbitalCameraControl;
	auto map = GetApp().RootMap;


	if (camera !is null) {
		if(individualList){
			camera.m_TargetedPosition = pos;
		}else{
			int index = objectsindex.Find(objectname);

			camerafocusindex++;

			if (camerafocusindex > objects[index].positions.Length - 1 ) {
				camerafocusindex = 0;
			}

			camera.m_TargetedPosition = objects[index].positions[camerafocusindex];
		}
		// Workaround to update camera TargetedPosition
		editor.ButtonZoomInOnClick();
		editor.ButtonZoomOutOnClick();
		return true;
	}
	return false;
}

class Skin {
	dictionary translator = {
		{"Left.webm", "Left+111A.webm"},
		{"Right.webm", "Right+111A.webm"},
		{"Up.webm", "Up+111A.webm"},
		{"Down.webm", "Down+111A.webm"}
	};
	dictionary translator1x1 = {
		{"Left+FreezeRGB.webm", "Left+111A.webm"},
		{"Right+FreezeRGB.webm", "Right+111A.webm"},
		{"Up+FreezeRGB.webm", "Up+111A.webm"},
		{"Down+FreezeRGB.webm", "Down+111A.webm"}
	};
	CGameCtnBlock @block;
	CGameCtnAnchoredObject @item;
	string bgSkin;
	string fgSkin;
	bool updateBg = true;
	bool updateFg = true;

	void Apply(){
		auto editor = cast<CGameCtnEditorFree>(GetApp().Editor);

		if(bgSkin.ToLower().EndsWith(".zip")){
			int len = GetFileName(bgSkin).Length;
			bgSkin = bgSkin.SubStr(0, bgSkin.Length-len) + bgSkin.SubStr(bgSkin.Length-len, 1).ToUpper() + bgSkin.SubStr(bgSkin.Length-(len-1), len+1);
		}
		if(fgSkin.ToLower().EndsWith(".zip")){
			int len = GetFileName(fgSkin).Length;
			fgSkin = fgSkin.SubStr(fgSkin.Length-len, 1).ToUpper() + fgSkin.SubStr(fgSkin.Length-(len-1), len+1);
		}
		if(@block !is null){
			string currFg = editor.PluginMapType.GetBlockSkinFg(block);
			string currBg = editor.PluginMapType.GetBlockSkinBg(block);

			if(currFg.Trim() != ""){
				if(currFg.Contains("+FreezeRGB")) currFg = currFg.Replace("+FreezeRGB", "+111A");
				if(!currFg.Contains("+FreezeRGB") && !currFg.Contains("+111A")) currFg = currFg.Replace(".webm", "+111A.webm");
				if(block.BlockInfo.Name.StartsWith("Stage") || block.BlockInfo.Name.StartsWith("Stand")){
					currFg = currFg.Replace("+111A", "");
				}
			}

			if(currBg != bgSkin && currFg != fgSkin)
			{
				editor.PluginMapType.SetBlockSkins(block, (updateBg ? bgSkin : currBg), (updateFg ? fgSkin : currFg));
				print("Applied bg: " + (updateBg ? bgSkin : currBg) + " / fg: "+ (updateFg ? fgSkin : currFg));
			}
			else if(currBg == bgSkin && currFg != fgSkin)
			{
				editor.PluginMapType.SetBlockSkins(block, currBg, (updateFg ? fgSkin : currFg));
				print("Applied bg: " + currBg + " / fg: "+ (updateFg ? fgSkin : currFg));
			}
			else if(currBg != bgSkin && currFg == fgSkin)
			{
				editor.PluginMapType.SetBlockSkins(block, (updateBg ? bgSkin : currBg), currFg);
				print("Applied bg: " + (updateBg ? bgSkin : currBg) + " / fg: "+ currFg);
			}
		}
	}
}

string GetFileName(const string &in path){
	array<string> fileName = path.Split("\\");
	return fileName[fileName.Length-1];
}

class Sign {
	Objects@ obj;
	string objectName;
	string bgSkin;
	string fgSkin;
	bool updateBg = true;
	bool updateFg = true;

	void ApplyOther() {
		auto editor = cast<CGameCtnEditorFree>(GetApp().Editor);
		auto blocks = editor.Challenge.Blocks;
		for(int i = 0; i < blocks.Length; i++){
			auto block = blocks[i];
			auto article = cast<CGameCtnArticle>(block.BlockInfo.ArticlePtr);
			if (article !is null) {
					string reqBlock = objectName;
					string mapBlock = article.Name;



					if(reqBlock == mapBlock){
						Skin skin;
						skin.bgSkin = bgSkin;
						skin.fgSkin = fgSkin;
						skin.updateBg = updateBg;
						skin.updateFg = updateFg;
						@skin.block = @blocks[i];
						skin.Apply();
					}
			}
			if (i % 100 == 0) yield();
		}

		// obj.selectedLM = LMToIntBlock(lmLvlB);
		string[] name = objectName.Split("/");
	}
}

// class Batch {
// 	Objects@[] sortableobjects;
// 	string bgSkin;
// 	string fgSkin;
	
// 	void ApplySearch() {

// 	}
// }