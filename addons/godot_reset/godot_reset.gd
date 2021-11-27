tool
class_name GodotReset extends EditorPlugin

signal enable_ridiculous_coding()

var __regex: Dictionary = {
	"set_color": "^#?([0-9a-f]{3}|[0-9a-f]{6})$",
	"black": "^#?(0{3}|0{6})$"
}
var __server: UDPServer = null
var __settings: EditorSettings = null
var __timer_poll: Timer = null
var __timer_coding: Timer = null



func _enter_tree() -> void:
	print("Godot Reset enabled")

	self.__settings = self.get_editor_interface().get_editor_settings()

	self.__server = UDPServer.new()
	self.__server.listen(4242)

	self.__timer_poll = Timer.new()
	self.__timer_poll.autostart = true
	self.__timer_poll.wait_time = 0.3
	self.__timer_poll.connect("timeout", self, "__poll")
	self.add_child(self.__timer_poll)

	self.__timer_coding = Timer.new()
	self.__timer_coding.wait_time = 60.0
	self.__timer_coding.one_shot = true
	self.__timer_coding.connect("timeout", self, "__disable_coding")
	self.add_child(self.__timer_coding)

	for key in self.__regex.keys():
		var ex = RegEx.new()
		ex.compile(self.__regex[key])
		self.__regex[key] = ex


func _exit_tree() -> void:
	print("Godot Reset disabled")


var __focused_text_edit: TextEdit = null

func _process(delta: float) -> void:
	var editor: EditorInterface  = self.get_editor_interface()
	var script_editor: ScriptEditor = editor.get_script_editor()

	for text_edit in self.__find_text_edits(script_editor):
		if text_edit.has_focus():
			self.__focused_text_edit = text_edit
			return

func __find_text_edits(parent: Node) -> Array:
	var text_edits: Array = []

	for child in parent.get_children():
		if child.get_child_count():
			text_edits.append_array(self.__find_text_edits(child))

		if child is TextEdit:
			text_edits.append(child)

	return text_edits


func __disable_coding() -> void:
	var editor = get_editor_interface()
	editor.set_plugin_enabled("ridiculous_coding", false)


func __poll() -> void:
	self.__server.poll()
	if self.__server.is_connection_available():
		var peer : PacketPeerUDP = self.__server.take_connection()
		var pkt = peer.get_packet()

		var result = JSON.parse(pkt.get_string_from_utf8())
		if result.error:
			return

		var data = result.result

		match data:
			{"type": "set_color", "color": var color, "username": var username}:
				if !self.__regex["set_color"].search(color.to_lower()):
					print("Sorry %s, %s is an invalid color" % [username, color])
					return

				if username.to_lower() == "liioni":
					if self.__regex["black"].search(color.to_lower()):
						print("Surprise, surprise! Liioni with the %s" % color)
					else:
						print("WHAT!? Liioni didn't use #000000!?!?")
				else:
					print("Setting editor to %s for %s!" % [color, username])

				self.__settings.set_setting(
					"interface/theme/base_color",
					color
				)
			{"type": "enable_ridiculous_coding", "username": var username}:
				print("Time to get ridiculous thanks to %s!" % username)

				var editor = get_editor_interface()
				editor.set_plugin_enabled("ridiculous_coding", true)

				self.__timer_coding.start()
			{"type": "add_comment", "username": var username, "comment": var comment}:
				if username == 'Liioni':
					username = 'Lil\'Oni'

				if !self.__focused_text_edit:
					print("Sorry %s, it looks like there are no open scripts")
					return

				print("%s has left a comment in the code" % username)
			 # this part of the code was sponsored by RAID SHADOW LEGENDS - Lumikkode

				var cursor_line: int = self.__focused_text_edit.cursor_get_line()
				var cursor_column: int = self.__focused_text_edit.cursor_get_column()
				var scroll_horizontal: int = self.__focused_text_edit.scroll_horizontal
				var scroll_vertical: float = self.__focused_text_edit.scroll_vertical

				var line_length = self.__focused_text_edit.get_line(cursor_line).length()
				self.__focused_text_edit.cursor_set_column(line_length)

				self.__focused_text_edit.insert_text_at_cursor(" # %s - %s" % [comment, username]) # expletive - TheYagich # pee break - totally_not_a_spambot

				self.__focused_text_edit.cursor_set_line(cursor_line)
				self.__focused_text_edit.cursor_set_column(cursor_column)
				self.__focused_text_edit.scroll_horizontal = scroll_horizontal
				self.__focused_text_edit.scroll_vertical = scroll_vertical

			_:
				print("invalid payload: ", typeof(data), data)
