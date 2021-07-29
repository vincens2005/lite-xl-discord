require "discord"
local function sleep(n)
  os.execute("sleep " .. tonumber(n))
end

discord_init()

sleep(1)

discord_update("test1", "test2", "lite-xl")

sleep(30)

discord_update("AAHAHAHA", "jdsbsudysds", "lite-xl")

sleep(20)

discord_shutdown()
