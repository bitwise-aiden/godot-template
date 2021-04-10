tool
extends EditorPlugin


var active: bool = true
var twitch: Gift = null

var moderators: Array = [
	"b33bytes",
	"deschainxiv",
	"incompetent_ian",
	"velopman"
]

var command_responses: Dictionary = {
  '!current': 'https://velopman.itch.io/uhhh-helm password: chickenrun',
  '!discord': 'https://discord.gg/snQ4FMAkBp',
  '!github': 'https://github.com/velopman',
  '!itch': 'https://velopman.itch.io',
  '!ian': 'https://www.youtube.com/channel/UCmRJyLjnQ035ng6XP295zXg',
  '!jam': 'https://itch.io/jam/7drl-challenge-2021',
  '!onlyfans': 'https://www.youtube.com/channel/UCmRJyLjnQ035ng6XP295zXg',
  '!timezone': 'Eastern (UTC - 05:00)',
  '!today': 'Working on a game for Godot Wild Jam 30, theme: Heartbeat!',
}

var user_responses: Dictionary = {
	"b33bytes": "Buzzzzsh \u1F41D",
	"wan_hack": "NoU hydrate",
	"liioni": "_Ominous music starts playing_",
	"cavedens": "Looking pixel perfect!",
	"velopman": "GET BACK TO THE STREAM!",
	"divi02": "Okay, I'll sit up straight",
	"theyagich": "Why aren't you asleep?",
	"lumikkode": "Oh my! It is Lumi <3 <3"
}


# Lifecycle methods
func _process(delta: float) -> void:
	if self.twitch == null:
		self.__start_client()

	self.twitch.process(delta)

	if self._server == null:
		self.__start_server()

#	self._server.poll()
	var connection: StreamPeerTCP = self._server.take_connection()
	if connection:
		print(connection.get_string(256))
		var data = {
			"key": "value",
			"blah!": "Hello world",
			"asdf": 1234
		}

		connection.put_data(self.__response_json(data))

# Private methods
func __chat_message(sender : SenderData, message: String, channel: String) -> void:
	message = message.strip_edges()

	if message[0] == '!':
		self.__command(sender, message)
	elif false && sender.user in self.user_responses:
		self.twitch.chat(self.user_responses[sender.user])
		self.user_responses.erase(sender.user)


func __command(sender: SenderData, message: String) -> void:
	var command = message.split(" ", 1)[0]

	if command in self.command_responses:
		self.twitch.chat(self.command_responses[command])


func __command_buzz(command_info: CommandInfo) -> void:
	if command_info.sender_data.user == "b33bytes":
		self.twitch.chat("Buzz (pretend there are bee emojis)")


func __command_shoutout(command_info: CommandInfo, recipient: PoolStringArray) -> void:
	if self.moderators.has(command_info.sender_data.user):
		var name: String = recipient[0].replace('@', '')
		self.twitch.chat(
			"Checkout @%s over at https://twitch.tv/%s" % [name, name]
		)

func __command_time(command_info: CommandInfo) -> void:
	var time = OS.get_time()
	self.twitch.chat("%02d:%02d eastern" % [time.hour, time.minute])


func __load_settings() -> Dictionary:
	var file: File = File.new()

	if file.file_exists("user://plugin.json"):
		file.open("user://plugin.json", File.READ)
		var content: String = file.get_as_text()
		file.close()

		return JSON.parse(content).result

	return {}


func __response_json(data: Dictionary) -> PoolByteArray:
	var data_string = JSON.print(data)

	var content = PoolStringArray([
		"HTTP/1.1 200 OK",
		"Content-Type: application/json",
		"Content-Length: %d" % len(data_string),
		"",
		data_string
	])

	print(content.join("\r\n"))
	return content.join("\r\n").to_utf8()


func __start_client() -> void:
	self.twitch = Gift.new()

	var settings = self.__load_settings()
	if !settings:
		print("No settings found")
		self.set_process(false)
		return

	self.twitch.connect("chat_message", self, "__chat_message")

	self.twitch.connect_to_twitch()
	yield(self.twitch, "twitch_connected")

	self.twitch.authenticate_oauth("TheYagich", settings["oauth_token"])
	if(yield(twitch, "login_attempt") == false):
		print("Invalid token.")
		return
	self.twitch.join_channel(settings["channel_name"])

	self.twitch.add_command("buzz", self, "__command_buzz")
	self.twitch.add_command("so", self, "__command_shoutout", 1, 1)
	self.twitch.add_command("time", self, "__command_time")


const PORT = 9080
var _server: TCP_Server = null

func __start_server():
	self._server = TCP_Server.new()
#	# Create and set key and self-signed certificate.
#	var crypto = Crypto.new()
#	var key = crypto.generate_rsa(4096)
#	var cert = crypto.generate_self_signed_certificate(key, "CN=localhost,O=myorganisation,C=IT")
#	_server.private_key = key
#	_server.ssl_certificate = cert

	# Start server.
#	_server.connect("client_connected", self, "_connected")
	_server.listen(PORT)

func _connected(id, protocol):
	print(id, protocol)

	print("Client connected!")
