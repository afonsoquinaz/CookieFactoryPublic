class_name Icons
## Loads the generated icon textures (assets/icons/<name>.png).

static var _cache := {}


static func tex(name: String) -> Texture2D:
	if _cache.has(name):
		return _cache[name]
	var path := "res://assets/icons/%s.png" % name
	var t: Texture2D = load(path) if ResourceLoader.exists(path) else null
	_cache[name] = t
	return t
