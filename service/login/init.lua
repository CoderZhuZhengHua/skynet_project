local skynet = require "skynet"
local s = require "service"


s.client = {}   --这里存放着 所有的命令

s.resp.client = function (source, fd, cmd, msg)
    skynet.error("s.resp.client  cmd" .. cmd)
    if s.client[cmd] then
        local ret = s.client[cmd](fd, msg, source)
        skynet.send(source, "lua", "send_by_fd", fd, ret)
    else
        skynet.error("s.resp.client unknown cmd ".. cmd)
    end
end

s.client.login = function (fd, msg, source)
    skynet.error("login" .."  fd = " .. fd .." msg = "  .. " source = " .. source)

    return {"login", 1, "测试"}
end


s.start(...)