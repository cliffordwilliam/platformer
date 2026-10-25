@abstract
class_name Screen
## The screen's size, read once from the project settings.

static var width: int = ProjectSettings.get_setting("display/window/size/viewport_width")
static var height: int = ProjectSettings.get_setting("display/window/size/viewport_height")
static var half_width: float = width / 2.0
static var half_height: float = height / 2.0
