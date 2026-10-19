class_name Share
## Sharing the lab: an invite with your friend code, and a snapshot of the
## lab with a stats banner (web: the browser's share sheet or a download;
## elsewhere: a PNG in the user folder).

## Shares the invite text (web share sheet if there is one, else clipboard).
static func invite(hud) -> bool:
	var text := Live.invite_text()
	if OS.has_feature("web"):
		var js := "if (navigator.share) { navigator.share({title: 'Token Empire', text: %s}).catch(function(){}); 'shared' } else { 'none' }" % JSON.stringify(text)
		var r = JavaScriptBridge.eval(js, true)
		if str(r) == "shared":
			return true
	DisplayServer.clipboard_set(text)
	if hud:
		hud.toast("Invite copied. Paste it anywhere!", "share")
	return true


## Takes a snapshot of the lab with a banner (see Hud.snapshot).
static func snapshot(hud) -> bool:
	if hud == null:
		return false
	hud.snapshot()
	return true


## Saves PNG bytes: a download on the web, a file in user://snapshots/ elsewhere.
## Returns where it went (for the toast).
static func save_png(img: Image) -> String:
	var name := "token-empire-%s.png" % Time.get_datetime_string_from_system().replace(":", "-").replace("T", "_")
	if OS.has_feature("web"):
		JavaScriptBridge.download_buffer(img.save_png_to_buffer(), name, "image/png")
		return "Downloads"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("user://snapshots"))
	var path := "user://snapshots/" + name
	img.save_png(path)
	return ProjectSettings.globalize_path(path)
