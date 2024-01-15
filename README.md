# Lightmap Priority Manager

Lightmap Priority Manager, like its name says, aims to help you manage blocks and items lightmap priority, giving you more control over the lightmap calculations !
It is a fork of the [Items & Blocks Counter](https://openplanet.dev/plugin/blocksitemscounter) plugin by Beu.

## Features (that the original plugin doesn't have)
- Change lightmap priority for items (vanilla and non vanilla)
- Change lightmap priority for blocks (vanilla or custom blocks)
- Batch change lightmap priority
- Scans and displays what lightmap priority items and blocks have
- A lot of options

## Settings
Default settings work perfectly but you can customize a few things, including:
- Changing buttons color when lightmap is found (after a scan)
- Enable or disable the lightmap found indicator (after a scan)
- Enable or disable the lightmap scan
- Enable or disable the lightmap priority next to the Filter bar
- Enable or disable the camera focus button (from the original plugin)
- Enable or disable the 3 kind of notifications
	- Lightmap applied notification
	- Processing from Filter bar notification
	- Scanning notification
- Enable or disable the 4 kind of columns from the main table listing everything
	- Type (Items / Blocks)
	- Source (In-Game, Embedded, Local)
	- Size
	- Count
	
## Note
1. The lightmap scan is not the fastest, if anyone has a better scanning algorithm, please let me know on Discord `bmx22c#0001`.
2. As Grass blocks (that covers the Stadium floor) are recreated each time you open up the editor, their lightmap priority will not be kept upon reloading. The lightmap priority is still applied and you should only do this once your map is ready to be shipped, making the Grass lightmap priority change the last thing you'll do before computing shadows.

## Contributing
Source code is on [GitHub](https://github.com/bmx22c/LightmapPriorityManager). Feel free contribute.

## Changelog
### 1.1
- Added loading indicator at the bottom on the window
- Lightmap buttons update in real time when clicking on them
- Added setting to only update the lightmap buttons color when scanning is finished
- Removed Scanning notification as it's been replaced with text at the bottom of the window
- Lightmap buttons hover color is correctly set

### 1.0
Initial release