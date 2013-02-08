#!/usr/bin/env lua

local function checkenv(varname)
    local value = os.getenv(varname)
    if not value then
        print(varname .. ' not set')
        os.exit(1)
    end
    return value
end

local WORLD_DATA_REPOSITORY = checkenv('WORLD_DATA_REPOSITORY')
local CLIENT_UPDATES_DIR = checkenv('CLIENT_UPDATES_DIR')


local function trim(s)
    s = string.gsub(s, '^%s+', '') -- strip preceding whitespace
    s = string.gsub(s, '%s+$', '') -- strip trailing whitespace
    return s
end

local function capture(command)
    local f = assert(io.popen(command, 'r'))
    local s = assert(f:read('*a'))
    f:close()
    return trim(s)
end

local function execute(command)
    local result = assert(os.execute(command))
    if result ~= 0 then
        print("Error executing:")
        print(" " .. command)
        os.exit(1)
    end
end

local function git(subcommand)
    return 'git --git-dir=' .. WORLD_DATA_REPOSITORY .. ' ' .. subcommand
end

local function adler32(file)
    return string.sub(capture('adler32 ' .. file), -8)
end

local function last_revision(paths)
    local output = capture(git('log -1 --oneline -- ' .. table.concat(paths, ' ')))
    return assert(string.match(output, '(%w+) '))
end


local packages = {
    {
        name = "definitions",
        paths = {
            "ea-skills.xml",
            "effects.xml",
            "emotes.xml",
            "hair.xml",
            "items.xml",
            "monsters.xml",
            "npcs.xml",
            "paths.xml",
            "skills.xml",
            "status-effects.xml",
        },
    },
    --{ name = "music", type = "music", required = "no", paths = { "music" }, },
    { name = "sound", paths = { "sfx" }, },
    { name = "maps", paths = { "maps" }, },
    { name = "graphics", paths = { "graphics" }, },
}

local resources_lines = {
    '<?xml version="1.0"?>',
    '<updates>',
}

for i=1,#packages do
    local package = packages[i]
    local revision = last_revision(package.paths)
    local filename = package.name .. "-" .. revision .. ".zip"
    local fullname = CLIENT_UPDATES_DIR .. '/' .. filename

    print("Creating " .. filename)
    execute(git('archive HEAD --output=' .. fullname .. ' ' .. table.concat(package.paths, ' ')))

    local type = package.type or "data"
    local hash = adler32(fullname)
    local line = ' <update type="' .. type .. '" '
    if package.required == "no" then
        line = line .. ' required="no"'
    end
    line = line .. ' file="' .. filename .. '"'
    line = line .. ' hash="' .. hash .. '" '
    if package.description then
        line = line .. ' description="' .. package.description .. '"'
    end
    line = line .. '/>'
    table.insert(resources_lines, line)
end

table.insert(resources_lines, '</updates>')

print("Writing resources.xml")
local file = io.open(CLIENT_UPDATES_DIR .. "/resources.xml", "w")
file:write(table.concat(resources_lines, '\n') .. '\n')
file:close()