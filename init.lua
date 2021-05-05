-- lite-xl 1.16
local core = require "core"
local command = require "core.command"


local function start_stuff()
  core.log("discord plugin: starting python script")
  system.exec("python3 presence.py")
end
start_stuff()
command.add("core", {["discord-presence:start-presence"] = start_stuff})
