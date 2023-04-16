return {
    --集群的配置
    cluster = {
        node1 = "127.0.0.1:7771",
        node2 = "127.0.0.1:7772",
    },

    --agentmgr  全局唯一的agentmgr服务位于node1
    agentmgr = {node = "node1"},

    --scene
    scene = {
        node1 = {1001, 1002},   --在节点1开启编号为1001 1002的两个战斗场景服务
        --node2 = {1003},
    },

    --节点1 开启两个gateway和两个login
    node1 = {
        gateway = {
            [1] = {port = 8001},
            [2] = {port = 8002},
        },

        login = {
            [1] = {},
            [2] = {},
        }
    },

    --节点2
    node2 = {
        gateway = {
            [1] = {port = 8011},
            [2] = {port = 8012},
        },

        login = {
            [1] = {},
            [2] = {},
        }
    }












}