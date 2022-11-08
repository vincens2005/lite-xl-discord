local discord = require "discord"
local function sleep(n)
  os.execute("sleep " .. tonumber(n))
end

discord.init("839231973289492541")

sleep(1)

discord.update({
	state = "things",
	details = "stuffs",
	large_image = "lite-xl"
})

sleep(30)

discord.update({
	state = "more thinfs",
	details = "mr ",
	large_image = "lite-xl"
})


sleep(20)

discord.shutdown()
