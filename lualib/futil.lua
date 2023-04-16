
local skynet = require "skynet"
require "tostring"

local M = {}


function M.try2num(arg) --尝试把参数转化成数字
    local ret = tonumber(arg)
    if ret then
        return ret
    else
        return arg
    end
end

function  M.toStr(info)
    if info then
        return table.tostring(info)
    end
    return ""
end

return M