-- mod-version:1 lite-xl 1.16
local core = require "core"
local command = require "core.command"
local common = require "core.common"
local config = require "core.config"
-- function replacements:
local quit = core.quit
local restart = core.restart
local status = {
	filename = nil,
	space = nil
}
core.log("discord plugin: starting python script")
system.exec("python3 " .. USERDIR .. "/plugins/lite-xl-discord/presence.py --pickle=" .. USERDIR .. "/plugins/lite-xl-discord/discord_data.pickle")


local function tell_discord_to_stop()
	local cmd = "python3 " .. USERDIR .. "/plugins/lite-xl-discord/update_presence.py --state='no' --details='no' --die-now='yes' --pickle=" .. USERDIR .. "/plugins/lite-xl-discord/discord_data.pickle"
	-- core.log("running command ".. command)
	core.log("stopping discord rpc...")
	system.exec(cmd)
end

local function update_status()
	local details = "editing file " .. core.active_view.doc.filename
	local dir = common.basename(core.project_dir)
	local state = "in workspace " .. dir
	status.filename = core.active_view.doc.filename
	status.space = dir
	local cmd = "python3 " .. USERDIR .. "/plugins/lite-xl-discord/update_presence.py --state='" .. state .. "' --details='" .. details .. "' --die-now='no' --pickle=" .. USERDIR .. "/plugins/lite-xl-discord/discord_data.pickle"
	system.exec(cmd)
end

core.quit = function(force)
	tell_discord_to_stop()
	return quit(force)
end

core.restart = function()
	tell_discord_to_stop()
	return restart()
end

core.add_thread(function()
	while true do
		if not (common.basename(core.project_dir) == status.space and core.active_view.doc.filename == status.filename) then
			update_status()
		end
		coroutine.yield(config.project_scan_rate)
	end
end)

command.add("core.docview",
            {["discord-presence:stop-RPC"] = tell_discord_to_stop})
command.add("core.docview", {["discord-presence:update-RPC"] = update_status})
-- core.project_dir
