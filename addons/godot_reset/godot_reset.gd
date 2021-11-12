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
			_:
				print("invalid payload: ", typeof(data), data)
