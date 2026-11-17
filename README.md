# pxxl-probe-image

Pxxl 免费层 Web Service 用的镜像：一个最小 HTTP 响应器过平台健康检查，
同时前台守护官方 Nezha v2 agent（`nezhahq/agent`，构建期烘进镜像，运行时禁自更新）。

## 环境变量（由 Pxxl 项目 env 下发，不进镜像）

| 变量 | 说明 |
| --- | --- |
| `NZ_SERVER` | 面板地址，如 `nezhav2.btppone.hidns.vip`；缺端口时自动补 `:443` |
| `NZ_CLIENT_SECRET` | 面板连接密钥，**必须标记 secret** |
| `NZ_UUID` | 可选；不传则由 secret 派生稳定实例 ID |
| `PORT` | Pxxl 运行时注入；同时监听 `:80` 兜底 |

## 为什么这么包

Pxxl Web Service 在发布路由前要求进程监听 `$PORT` 并绑定 `0.0.0.0`，
而 Nezha agent 是纯出站 gRPC 客户端、不监听端口，单独跑必被健康检查判死。
因此镜像里同时跑 `busybox httpd`（占位 200）和 agent。

镜像多架构 `linux/amd64` + `linux/arm64`，由 GA buildx 构建推送到 GHCR。
