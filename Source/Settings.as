[Setting category="General" name="Lightmap found color" description="Color for when the lightmap priority is found." color]
vec4 Setting_LMFoundColor = vec4(0.3,0.7,0.3,1);

[Setting category="General" name="Lightmap found indicator" description="Change the button color when lightmap priority is found."]
bool Setting_LMFoundIndicate = true;

[Setting category="General" name="Lightmap priority scanning" description="Enable or disable the lightmap priority scanning. Won't show previously applied priorities when disabled."]
bool Setting_LMScanning = true;

[Setting category="General" name="Only apply buttons color when scan is finished" description="Will only change the lightmap buttons color when the lightmap priority scanning is finished."]
bool Setting_LMChangeButtonWhenFinishScanning = false;

[Setting category="General" name="Displays Filter global lightmap priority buttons" description="Displays lightmap priority buttons next to the Filter text bar."]
bool Setting_LMFilterButtons = true;

[Setting category="General" name="Enable camera focus button" description="Display the camera focus button."]
bool Setting_EnableCameraFocus = true;

[Setting category="Notification" name="Lightmap priority applied notification" description="Enable or disable the notification when a lightmap priority is applied. Can spam your screen with notification."]
bool Setting_NotifLMApplied = true;

[Setting category="Notification" name="Processing from Filter bar notification" description="Enable or disable the notification when starting a lightmap change from the Filter text bar."]
bool Setting_NotifSearchProcess = true;

[Setting category="Table" name="Type" description="Enable or disable the Type column."]
bool Setting_TableType = true;

[Setting category="Table" name="Source" description="Enable or disable the Source column."]
bool Setting_TableSource = true;

[Setting category="Table" name="Size" description="Enable or disable the Size column."]
bool Setting_TableSize = true;

[Setting category="Table" name="Count" description="Enable or disable the Count column."]
bool Setting_TableCount = true;