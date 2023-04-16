local skynet = require "skynet"
local cluster = require "skynet.cluster"
require "skynet.manager"

local M = {
    --类型和id
    name = "",
    id = 0,
    --回调函数
    exit = nil,
    init = nil,
    --分发方法
    resp = {},
}


function traceback(err)
    skynet.error(tostring(err))
    skynet.error(debug.traceback())
end

--address 是消息的发送方
local dispatch = function ( session, address, cmd, ...)
    skynet.error("service dispatch ",session, address, cmd)
    local fun = M.resp[cmd]
    if not fun then
        skynet.error("service dispatch no  this fun")
        skynet.ret()
        return 
    end

    local ret = table.pack(xpcall(fun, traceback, address, ...))
    local is_ok = ret[1]

    if not is_ok then
        skynet.ret()
        return
    end

    --skynet.error("service dispatch return " .. table.unpack(ret, 2))
    skynet.retpack(table.unpack(ret, 2))
end


function init()
    skynet.error("service init ")
    skynet.dispatch("lua", dispatch)
    if M.init then
        M.init()
    end

    --skynet.register ("." .. M.name .. M.id)
end

function M.start(name, id, ...)
    skynet.error("service start ", name, id)


    M.name = name
    M.id = tonumber(id) 

    
    skynet.start(init)
end

function M.call(node, srv, ...)
    local my_node = skynet.getenv("node")

    if my_node == node then
        return skynet.call(srv, "lua",...)
    else
        return cluster.call(node, srv, ...)
    end
end

function M.send(node, srv, ...)
    local my_node = skynet.getenv("node")

    if my_node == node then
        return skynet.send(srv, "lua",...)
    else
        return cluster.send(node, srv, ...)
    end
end


return M