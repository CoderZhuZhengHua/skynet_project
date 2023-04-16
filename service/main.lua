local skynet = require "skynet"
local runconfig = require "runconfig"

local CMD = {}



local function start()
    skynet.error("this is my first project")
    skynet.error("runconfig = %s", runconfig.agentmgr.node)
    
end






skynet.start(function ()

    start()

    skynet.newservice("debug_console", 8888)
    skynet.newservice("gateway", "gateway", 1)



    skynet.exit()
    --[[skynet.dispatch("lua", function(session, address, command, ...)
    
        local fun = assert(CMD[command])
        fun(...)
    
    end)]]

end)