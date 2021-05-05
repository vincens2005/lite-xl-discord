-- lite-xl 1.16
local core = require "core"
local command = require "core.command"
local quit = core.quit
local restart = core.restart

core.log("discord plugin: starting python script")
system.exec("python3 "..USERDIR.."/plugins/lite-xl-discord/presence.py --pickle="..USERDIR.."/plugins/lite-xl-discord/discord_data.pickle")

local function tell_discord_to_stop()
  local command = "python3 "..USERDIR.."/plugins/lite-xl-discord/update_presence.py --state='no' --details='no' --die-now='yes' --pickle="..USERDIR.."/plugins/lite-xl-discord/discord_data.pickle"
  --core.log("running command ".. command)
  core.log("stopping discord rpc...")
  system.exec(command)
end

core.quit = function(force)
  tell_discord_to_stop()
  return quit(force)
end

core.restart = function()
  tell_discord_to_stop()
  return restart()
end

command.add("core.docview", {["discord-presence:stop-RPC"] = tell_discord_to_stop})
--core.project_dir
