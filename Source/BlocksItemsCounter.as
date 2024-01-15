enum ESortColumn {
	ItemName,
	Type,
	Source,
	Size,
	Count
}

bool menu_visibility = false;
uint camerafocusindex = 0;
bool refreshobject;
int totalObjectCount = 0;
bool individualList = false;

string searchStr = "";

bool sort_reverse;
bool forcesort;
string infotext;

array<Objects@> objects = {};
array<Objects@> sortableobjects = {};
array<string> objectsindex = {};

string scanningStatus = "";
bool isScanning = false;
array<string> spinner = {Icons::Kenney::MoveTr, Icons::Kenney::MoveRb, Icons::Kenney::MoveLb, Icons::Kenney::MoveTl};
string loadingText = "";
bool finishedScanning = false;

ESortColumn sortCol = ESortColumn(-1);

void Main() {
	while (true) {
		if (refreshobject) {
			gameSkinList = {};
			userSkinList = {};
			ScanGameSigns(cast<CSystemFidsFolder>(Fids::GetGameFolder("GameData/Skins")));
			ScanUserSigns(cast<CSystemFidsFolder>(Fids::GetUserFolder("Skins")));
			gameSkinList.Sort(function(a,b){
				string tmpA = Regex::Replace(a.ToLower(), "\\.[^.]*$", "");
				string tmpB = Regex::Replace(b.ToLower(), "\\.[^.]*$", "");
				array<string> arrA = tmpA.Split("\\");
				array<string> arrB = tmpB.Split("\\");
				if(arrA.Length > 0) tmpA = arrA[arrA.Length-1];
				if(arrB.Length > 0) tmpB = arrB[arrB.Length-1];
				return tmpA<tmpB;
			});
			userSkinList.Sort(function(a,b){
				string tmpA = Regex::Replace(a.ToLower(), "\\.[^.]*$", "");
				string tmpB = Regex::Replace(b.ToLower(), "\\.[^.]*$", "");
				array<string> arrA = tmpA.Split("\\");
				array<string> arrB = tmpB.Split("\\");
				if(arrA.Length > 0) tmpA = arrA[arrA.Length-1];
				if(arrB.Length > 0) tmpB = arrB[arrB.Length-1];
				return tmpA<tmpB;
			});
			objects.Resize(0);
			objectsindex.Resize(0);
			sortableobjects.Resize(0);
			RefreshBlocks();
			RefreshItems();
			sortableobjects = objects;
			if (sortableobjects.Length > 0) sortableobjects.Sort(function(a,b) { return a.size > b.size; }); // Sort by size by default, it will be used as second sort criteria
			refreshobject = false;
		}
		yield();
	}
}

void RenderInterface() {
	if (!menu_visibility) return;
	if (!RenderLib::InMapEditor()) return;

	CGameCtnEditorFree@ editor = cast<CGameCtnEditorFree>(GetApp().Editor);
	CGameCtnChallenge@ map = cast<CGameCtnChallenge>(GetApp().RootMap);

	infotext = "";

	UI::SetNextWindowPos(200, 200, UI::Cond::Once);
	UI::PushStyleVar(UI::StyleVar::WindowMinSize, vec2(600, 400));
	if (UI::Begin("\\$FF0" + Icons::FileImageO + "\\$z Signs Manager###Signs Manager", menu_visibility, UI::WindowFlags::NoCollapse)) {
		if (refreshobject) {
			totalObjectCount = 0;
			RenderLib::LoadingButton();
		} else {
			if (UI::Button(Icons::Refresh + " Refresh")) {
				refreshobject = true;
				forcesort = true;
			}
		}
		RenderLib::LoadingIndicator();
		UI::SameLine();
		UI::PushStyleColor(UI::Col::FrameBg, vec4(0.169,0.388,0.651,0.1));
		individualList = UI::Checkbox("No grouping", individualList);
		UI::SameLine();
		infotext = "Total count: " + totalObjectCount;

		UI::SameLine();
		if(Setting_LMFilterButtons){
			UI::Dummy(vec2(UI::GetWindowSize().x - 850, 10));
		}else{
			UI::Dummy(vec2(UI::GetWindowSize().x - 600, 10));
		}
		UI::SameLine();
		UI::SetNextItemWidth(200);
		if (refreshobject) {
			searchStr = "";
			string newSearchStr = UI::InputText("Filter", searchStr, UI::InputTextFlags(UI::InputTextFlags::AutoSelectAll | UI::InputTextFlags::NoUndoRedo | UI::InputTextFlags::ReadOnly));
		} else {
			string newSearchStr = "";
			newSearchStr = UI::InputText("Filter", searchStr, UI::InputTextFlags(UI::InputTextFlags::AutoSelectAll | UI::InputTextFlags::NoUndoRedo));
			if (newSearchStr != searchStr) {
				searchStr = newSearchStr;
				string searchStrLower = searchStr.ToLower();
				sortableobjects = {};
				for(uint i = 0; i < objects.Length; i++) {
					if(searchStrLower == "" || objects[i].name.ToLower().Contains(searchStrLower)) {
						sortableobjects.InsertLast(objects[i]);
					}
				}
			}
		}
		UI::PopStyleColor();

		UI::Separator();
		vec2 winsize = UI::GetWindowSize();
		winsize.x = winsize.x-25;
		winsize.y = winsize.y-115;
		array<bool> enabledColumns = {Setting_TableType, Setting_TableSource, Setting_TableSize, Setting_TableCount};
		int nbrEnabledColumns = 3;
		for(uint i = 0; i < enabledColumns.Length; i++) if(enabledColumns[i]) nbrEnabledColumns++;
		if (UI::BeginTable("ItemsTable", nbrEnabledColumns, UI::TableFlags(UI::TableFlags::Resizable | UI::TableFlags::Sortable | UI::TableFlags::NoSavedSettings | UI::TableFlags::BordersInnerV | UI::TableFlags::SizingStretchProp | UI::TableFlags::ScrollY), winsize)) {				UI::TableSetupScrollFreeze(0, 1);
			UI::TableSetupColumn("Item Name", UI::TableColumnFlags::None, 55.f, ESortColumn::ItemName);	
			UI::TableSetupColumn("Background", UI::TableColumnFlags::None, 7.f, ESortColumn::Type);
			UI::TableSetupColumn("Foreground", UI::TableColumnFlags::None, 7.f, ESortColumn::Type);
			if(Setting_TableType) UI::TableSetupColumn("Type", UI::TableColumnFlags::None, 7.f, ESortColumn::Type);
			if(Setting_TableSource) UI::TableSetupColumn("Source", UI::TableColumnFlags::None, 13.f, ESortColumn::Source);
			if(Setting_TableSize) UI::TableSetupColumn("Size", UI::TableColumnFlags::None, 15.f, ESortColumn::Size);
			if(Setting_TableCount) UI::TableSetupColumn("Count", UI::TableColumnFlags::DefaultSort, 10.f, ESortColumn::Count);
			UI::TableHeadersRow();

			UI::TableSortSpecs@ sortSpecs = UI::TableGetSortSpecs();
			if(sortSpecs !is null && sortSpecs.Specs.Length == 1 && sortableobjects.Length > 1) {
				if(sortSpecs.Dirty || (forcesort && !refreshobject)) {
					if(sortCol != ESortColumn(sortSpecs.Specs[0].ColumnUserID) || (forcesort && !refreshobject)) {
						sortCol = ESortColumn(sortSpecs.Specs[0].ColumnUserID);
						switch(sortCol) {
							case ESortColumn::ItemName:
								sortableobjects.Sort(function(a,b) { return a.name < b.name; });
								break;
							case ESortColumn::Type:
								sortableobjects.Sort(function(a,b) { return a.type < b.type; });
								break;
							case ESortColumn::Source:
								sortableobjects.Sort(function(a,b) { return a.source < b.source; });
								break;
							case ESortColumn::Size:
								sortableobjects.Sort(function(a,b) { return a.size < b.size; });
								break;
							case ESortColumn::Count:
								sortableobjects.Sort(function(a,b) { return a.count < b.count; });
								break;
						}
						if (forcesort && sort_reverse) {
							sortableobjects.Reverse();
						} else {
							sort_reverse = false;
						}
					} else if (sortCol == ESortColumn(sortSpecs.Specs[0].ColumnUserID)) {
						sortableobjects.Reverse();
						sort_reverse = !sort_reverse;
					}

					sortSpecs.Dirty = false;
					forcesort = false;
				}
			}
			if (sortableobjects.Length > 0 ) {
				for(uint i = 0; i < sortableobjects.Length; i++) {
					RenderLib::GenerateRow(sortableobjects[i]);
					if(refreshobject) totalObjectCount += sortableobjects[i].count;
					
				}
			} else if (refreshobject) { // Display the items during the refresh
				for(uint i = 0; i < objects.Length; i++) {
					RenderLib::GenerateRow(objects[i]);
					totalObjectCount += objects[i].count;
				}
			}
			UI::EndTable();
			UI::Separator();
			UI::Text(Icons::Info + " " + infotext + loadingText + scanningStatus);
		}
	}
	
	UI::End();
	UI::PopStyleVar();
}
	
void RenderMenu() {
	if (!RenderLib::InMapEditor()) return;

	if(UI::MenuItem("\\$FF0" + Icons::FileImageO + "\\$z Signs Manager", "", menu_visibility)) {
		menu_visibility = !menu_visibility;
		refreshobject = true;
		forcesort = true;
	}
}
