extends Gift

func _ready():
	print("I am alive!")
	self.connect_to_twitch()
	yield(self, "twitch_connected")

	print("Hello?")

	var oauth_token: String = OS.get_environment("OAUTH_TOKEN")
	var channel_name: String = OS.get_environment("CHANNEL_NAME")

	var output: Array = []
	OS.execute("echo", ["%CHANNEL_NAME%"], true, output)
	print("Does this work?", output)

	self.authenticate_oauth("TheYagich", oauth_token)
	if(yield(self, "login_attempt") == false):
		print("Invalid token.")
		return
	self.join_channel(channel_name)

	self.send("I am alive! \u1F41DÌ†ΩÌ∞ùÌ†ΩÌ∞ùÌ†ΩÌ∞ùÌ†ΩÌ∞ùÌ†ΩÌ∞ùÌ†ΩÌ∞ù")

