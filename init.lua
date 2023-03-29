-- mod-version:3 lite-xl 2.1
local core = require "core"
local config = require "core.config"
local common = require "core.common"
local command = require "core.command"
local RootView = require "core.rootview"
local Object = require "core.object"
local discord = require "plugins.lite-xl-discord.discord"

-- stolen from https://github.com/TorchedSammy/litepresence/ Copyright (c) 2021 TorchedSammy
local function makeTbl(tbl)
	local t = {}
	for exts, ftype in pairs(tbl) do
		for ext in exts:gmatch('[^,]+') do
			t[ext] = ftype
		end
	end
	return t
end

-- extensions mapped to language names
local extTbl = makeTbl {
    ['asm'] = 'assembly',
    ['c,h'] = 'c',
    ['cpp,hpp'] = 'cpp',
    ['cr'] = 'crystal',
    ['cs'] = 'cs',
    ['css'] = 'css',
    ['dart'] = 'dart',
    ['ejs,tmpl'] = 'ejs',
    ['ex,exs'] = 'elixir',
    ['gitignore,gitattributes,gitmodules'] = 'git',
    ['go'] = 'go',
    ['hs'] = 'haskell',
    ['htm,html,mhtml'] = 'html',
    ['png,jpg,jpeg,jfif,gif,webp'] = 'image',
    ['java,class,properties'] = 'java',
    ['js'] = 'javascript',
    ['json'] = 'json',
    ['kt'] = 'kotlin',
    ['lua'] = 'lua',
    ['md,markdown'] = 'markdown',
    ['t'] = 'perl',
    ['php'] = 'php',
    ['py,pyx'] = 'python',
    ['jsx,tsx'] = 'react',
    ['rb'] = 'ruby',
    ['rs'] = 'rust',
    ['sh,bat'] = 'shell',
    ['swift'] = 'swift',
    ['txt,rst,rest'] = 'text',
    ['toml'] = 'toml',
    ['ts'] = 'typescript',
    ['vue'] = 'vue',
    ['xml,svg,yml,yaml,cfg,ini'] = 'xml',
}

-- thanks sammyette

-- some rules for placeholders:
-- %f - filename
-- %F - file path (absolute)
-- %d - file dir
-- %D - file dir (absolute)
-- %w - workspace name
-- %W - workspace path
-- %.n where n is a number - nth function after the string
-- %% DOES NOT NEED TO BE ESCAPED.
local default_config = {
    application_id = "749282810971291659",
    editing_details = "Editing %f",
    idle_details = "Idling",
    lower_editing_details = "in %w",
    lower_idle_details = "Idle",
    elapsed_time = true,
    idle_timeout = 30,
    autoconnect = true,
    reconnect = 5
}

local rpc_config = common.merge(default_config, config.discord_rpc)


local function replace_placeholders(data, placeholders)
    local text = type(data) == "string" and data or data[1]
    return string.gsub(text, "%%()(.)(%d*)", function(i, t, n)
        if placeholders[t] then
            return placeholders[t]
        elseif t == "." then
            if type(data) ~= "table" then error("no function provided", 0) end
            if not n or not data[tonumber(n) + 1] then
                error(string.format("invalid function index at %d", i), 0)
            end
            return data[tonumber(n) + 1]()
        else
            return "%" .. t
        end
    end)
end

local Discord = Object:extend()
function Discord:new()
    self.running = false
    self.idle = false
    self.error = false
    self.placeholders = {}

    core.add_thread(function()
        while true do
            coroutine.yield(config.project_scan_rate)
            discord.poll()

            local time = system.get_time()
            if self.running then
                if time - self.last_activity >= rpc_config.idle_timeout then
                    self.idle = true
                    self:update()
                end
            else
                if not self.error
                    and type(rpc_config.reconnect) == "number"
                    and self.disconnect ~= nil
                    and time - self.disconnect >= rpc_config.reconnect then
                    self:start()
                end
            end
        end
    end)
end

function Discord:update_placeholders()
    self.placeholders["w"] = common.basename(core.project_dir)
    self.placeholders["W"] = core.project_dir

    if core.active_view.doc and core.active_view.doc.filename then
        local filename = common.basename(core.active_view.doc.filename)
        self.placeholders["f"] = filename
        self.placeholders["F"] = core.active_view.doc.abs_filename

        local file_dir = string.sub(core.active_view.doc.abs_filename, 1, -#filename - 2)
        self.placeholders["d"] = string.sub(file_dir, #core.project_dir + 1, -1) or "."
        self.placeholders["D"] = file_dir
    else
        for _, t in ipairs { "f", "F", "d", "D" } do
            self.placeholders[t] = core.active_view:get_name()
        end
    end
end

function Discord:update()
    if not self.running then return end
    self:update_placeholders()

    local details = replace_placeholders(
        self.idle and rpc_config.idle_details or rpc_config.editing_details,
        self.placeholders
    )
    local state = replace_placeholders(
        self.idle and rpc_config.lower_idle_details or rpc_config.lower_editing_details,
        self.placeholders
    )

    local new_status = {
        state = state,
        details = details,
        large_image = "litexl",
        start_time = self.start_time
    }

    local filetype = self.placeholders["f"] and self.placeholders["f"]:match('^.+(%..+)$')

    if filetype then
        local img = extTbl[filetype:sub(2)]
        if img and not self.idle then
            new_status.large_image = img
            new_status.small_image = "litexl"
        end
    end

    discord.update(new_status)
end

function Discord:verify_config()
    for _, name in ipairs { "idle_details", "editing_details", "lower_idle_details", "lower_editing_details" } do
        local status, err = pcall(replace_placeholders, rpc_config[name], {})
        if not status then
            self.error = true
            core.error("lite-xl-discord: Invalid value for config.discord_rpc.%s: %s", name, err)
        end
    end
    return self.error
end

function Discord:start()
    if self.running then return end
    if self:verify_config() then return end

    self.running = true
    self.disconnect = nil
    self.last_activity = system.get_time()
    self.start_time = rpc_config.elapsed_time and os.time() or nil

    discord.on_event("ready", function()
        core.log("lite-xl-discord: connected to RPC!")
        self:update()
    end)
    discord.on_event("disconnect", function(n, err)
        self.running = false
        self.disconnect = system.get_time()
        discord.shutdown()
        core.error("lite-xl-discord: lost RPC connection: %d %s", n, err)
    end)

    core.log("lite-xl-discord: Starting RPC")
    discord.init(rpc_config.application_id)
end

function Discord:stop()
    discord.shutdown()
    core.log("lite-xl-discord: RPC stopped.")
end

function Discord:bump()
    self.last_activity = system.get_time()
    if self.idle then
        self.idle = false
        self:update()
    end
end


local rpc = Discord()


-- function replacements

-- unless one day they finally decided that autoreloading user module is not a good idea
-- this will be required since user expects their config to automagically update
local load_user_directory = core.load_user_directory
function core.load_user_directory()
    load_user_directory()
    rpc_config = common.merge(default_config, config.discord_rpc)
end

local on_quit_project = core.on_quit_project
function core.on_quit_project(...)
    rpc:stop()
    on_quit_project(...)
end

local set_active_view = core.set_active_view
function core.set_active_view(view)
    set_active_view(view)
    core.try(rpc.update, rpc)
end

for _, fn in ipairs { "mouse_pressed", "mouse_released", "text_input" } do
    local oldfn = RootView["on_" .. fn]
    RootView["on_" .. fn] = function(...)
        rpc:bump()
        return oldfn(...)
    end
end


-- commands
command.add(nil, {
    ["discord-rpc:stop-RPC"] = function()
        rpc:stop()
    end,
    ["discord-rpc:start-RPC"] = function()
        rpc:start()
    end
})


if rpc_config.autoconnect then
    rpc:start()
end
