-- mod-version:1 lite-xl 1.16
local core = require "core"
local command = require "core.command"
local common = require "core.common"
local config = require "core.config"
require "plugins.lite-xl-discord.discord"
-- function replacements:
local quit = core.quit
local restart = core.restart
local status = {filename = nil, space = nil}


-- stolen from https://stackoverflow.com/questions/1426954/split-string-in-lua
local function split_string(inputstr, sep)
	if sep == nil then sep = "%s" end
	local t = {}
	for str in string.gmatch(inputstr, "([^" .. sep .. "]+)") do
		table.insert(t, str)
	end
	return t
end


local function update_status()
	local filename = "unsaved file"
	-- return if doc isn't active
	if not core.active_view then return end
	if not core.active_view.doc then return end

	if core.active_view.doc.filename then
		filename = core.active_view.doc.filename
		filename = split_string(filename, "/")
		filename = filename[#filename]
	end


	local details = "editing " .. filename
	local dir = common.basename(core.project_dir)
	local state = "in " .. dir
	status.filename = filename
	status.space = dir
	discord_update(state, details, "lite-xl")
	system.exec(cmd)
end

local function start_rpc()
	core.log_quiet("discord plugin: starting RPC")
	discord_init()
	update_status()
end

core.quit = function(force)
	discord_shutdown()
	return quit(force)
end

core.restart = function()
	discord_shutdown()
	return restart()
end

core.add_thread(function()
	while true do
		-- skip loop if doc isn't active
		if not core.active_view then goto continue end
		if not core.active_view.doc then goto continue end
		if not (common.basename(core.project_dir) == status.space and
						core.active_view.doc.filename == status.filename) then
							update_status()
						end
		::continue::
		coroutine.yield(config.project_scan_rate)
	end
end)

command.add("core.docview",
	{["discord-presence:stop-RPC"] = function()
		discord_shutdown()
		core.log("Stopping RPC...")
	end
})
command.add("core.docview", {["discord-presence:update-RPC"] = update_status})

command.add("core.docview", {["discord-presence:start-RPC"] = start_rpc})

start_rpc()
