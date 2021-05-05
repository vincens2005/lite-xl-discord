-- lite-xl 1.16
local core = require "core"
local command = require "core.command"


core.log("discord plugin: starting python script")
system.exec("python3 presence.py")
