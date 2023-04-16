local skynet = require "skynet"
local s = require "service"
local socket = require "skynet.socket"
local runconfig = require "runconfig"
local msg_process_handeler = require "msg_process_handler"
local futil = require "futil"


local my_node = skynet.getenv("node")
local node_info = runconfig[my_node]
local login_id = 1  --轮询算法

local conns = {}    --[fd] = conn
local players = {}  --[playerid] = gateplayer 

local logins = {}


--连接类
function conn()
    local m = {
        fd = nil,
        playerid = nil,
    }

    return m
end

--玩家类
function gateplayer()
    local m = {
        playerid = nil,
        agent = nil,
        conn = nil,
    }

    return m
end

--关闭连接的请求
local disconnect = function (fd)
    local coon = conns[fd]
    if not coon then
        return
    end

    local playerid = coon.playerid


    --还没完成登录
    if not playerid then
        return 
    else    --已经完成登录了
        players[playerid] = nil
        local reason = "断线了"
        skynet.call("agentmgr", "lua", "reqkick", playerid, reason)
    end

    socket.close(fd)

end

--把协议对象 转化成字符串 并添加\r\n
local str_pack = function (cmd, msg)
    return table.concat(msg, ",") .. "\r\n"
end


--对消息字符串进行处理
local str_unpack = function (msg_str)
    local msg = {}

    while true do
        local arg, rest = string.match(msg_str, "(.-),(.*)")
        if arg then
            msg_str = rest
            arg = futil.try2num(arg)
            table.insert(msg, arg)
        else
            msg_str = futil.try2num(msg_str)
            table.insert(msg, msg_str)
            break
        end
    end

    return msg[1], msg  --返回命令 和 参数
    
end

--开始对消息进行处理
local process_msg = function (fd, msg_str)
    local cmd, cmd_info = str_unpack(msg_str)

    skynet.error("process_msg cmd = " ..  futil.toStr(cmd_info))

    local conn = conns[fd]
    local playerid = conn.playerid
    
    if playerid then   --如果客户端已经登录的话
        local player = players[playerid]
        local agent = player.agent
        skynet.send(agent, "lua", "client", cmd, cmd_info)
    else
        skynet.error("process_msg send")
        --local login = ".login" .. login_id

        skynet.send(logins[login_id], "lua", "client", fd, cmd, cmd_info)
        
        login_id = login_id + 1
        if login_id > #node_info.login then    --服务器轮询
            login_id = 1
        end
    end
    
end

--处理缓冲区
local process_buff = function (fd, read_buff)
    
    while true do
        local msg_str, rest = string.match(read_buff, "(.-)\r\n(.*)")
        if msg_str then
            read_buff = rest    --\r\n后面的内容
            process_msg(fd, msg_str)
        else
            return read_buff
        end
    end
end



--接受连接 进行数据的处理
local recv_loop = function (fd)
    socket.start(fd)

    local read_buff = ""

    while true do
        local recv_str =  socket.read(fd)
        
        if recv_str then
            skynet.error("recv  from fd =  " .. fd .. "  msg = " .. recv_str )
            read_buff = read_buff .. recv_str
            read_buff = process_buff(fd, read_buff)
        else
            skynet.error("disconnect socket close" .. fd)
            disconnect(fd)
            socket.close(fd)
            return
        end
    end

end

--连接的回调函数
local connect = function (fd, addr)
    skynet.error("gate connect from " .. addr .. " fd = ".. fd)

    local c = conn()
    c.fd = fd
    conns[fd] = c

    skynet.fork(recv_loop, fd)
end

function s.init()
    skynet.error("[gate init start]" .. s.name .. " " .. s.id)
    
    
    local port = node_info.gateway[s.id].port

    local listen_fd = socket.listen("0.0.0.0", port)

    skynet.error("gate start listen port = " .. port)

    socket.start(listen_fd, connect)


    --启动了两个login的服务
    table.insert(logins, skynet.newservice("login", "login", 1))
    table.insert(logins, skynet.newservice("login", "login", 2))
    

end

--发送消息的接口
s.resp.send_by_fd = function (source, fd, msg)
    if not conns[fd] then
        skynet.error("send_by_fd no this fd")
        return 
    end

    local info = str_pack(msg[1], msg)
    skynet.error("send_by_fd " .. futil.toStr(info))
    socket.write(fd, info)
end

s.resp.send = function (source, playerid, msg)
    local player = players[playerid]

    if not player then
        skynet.error("s.resp.send no this player")
        return 
    end

    local coon = player.conn
    if not coon then
        skynet.error("s.resp.send no this coon")
        return 
    end

    s.resp.send(nil, coon.fd, msg)
end



--确认登录的接口
s.resp.sure_agent = function (source, fd, playerid, agent)

    local coon = conns[fd]
    if not coon then
        skynet.call("agentmgr", "lua", "reqkick", playerid, "未完成登录就下线了")
        return false
    end

    coon.playerid = playerid

    local gplayer = gateplayer()
    gplayer.agent = agent
    gplayer.conn = coon
    gplayer.playerid = playerid


    players[playerid] = gplayer

    return true
end


--agentmgr 想直接踢出一名玩家的话
s.resp.kick = function (source, playerid)
    local gplayer = players[playerid]

    if not gplayer then
        return 
    end


    local coon = gplayer.conn
    players[playerid] = nil

    if not coon then
        return
    end

    conns[coon.fd] = nil

    disconnect(coon.fd)

    socket.close(coon.fd)
end



s.start(...)