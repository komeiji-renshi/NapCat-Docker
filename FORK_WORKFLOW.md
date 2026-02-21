# 自托管镜像工作流指南

将 NapCat-Docker、NapCatQQ、AstrBot 完全脱离原仓库，使用自己构建的镜像进行部署。

---

## 一、整体架构

```
你的 GitHub 仓库                    你的 Docker Hub
├── YOUR_GITHUB/NapCat-Docker  ──→  YOUR_DOCKERHUB/napcat-docker:latest
├── YOUR_GITHUB/NapCatQQ       ──→  (Release: NapCat.Shell.zip)
└── YOUR_GITHUB/AstrBot        ──→  YOUR_DOCKERHUB/astrbot:latest

部署时：
wget https://raw.githubusercontent.com/YOUR_GITHUB/NapCat-Docker/main/compose/astrbot.yml
sudo docker compose -f astrbot.yml up -d
→ 拉取的是 YOUR_DOCKERHUB 的镜像
```

---

## 二、前置准备

1. **Docker Hub 账号**：https://hub.docker.com
2. **GitHub 仓库**：Fork 以下三个仓库到你的账号
   - `NapNeko/NapCat-Docker` → `YOUR_GITHUB/NapCat-Docker`
   - `NapNeko/NapCatQQ` → `YOUR_GITHUB/NapCatQQ`
   - `Soulter/AstrBot` → `YOUR_GITHUB/AstrBot`
3. **GitHub Secrets**（在 NapCat-Docker 和 AstrBot 仓库的 Settings → Secrets 中配置）：
   - `DOCKERHUB_USERNAME`：Docker Hub 用户名
   - `DOCKERHUB_TOKEN`：Docker Hub Access Token（Settings → Security → Access Tokens）

---

## 三、各仓库修改清单

### 3.1 NapCat-Docker（必须修改）

| 文件 | 修改内容 |
|------|----------|
| `compose/astrbot.yml` | 将 `YOUR_DOCKERHUB_USERNAME` 替换为你的 Docker Hub 用户名（已预置占位符） |
| `compose/*.yml`（其他 compose） | 同上，napcat 镜像改为你的 |
| `Dockerfile` | `FROM mlikiowa/napcat-docker:base` → `FROM YOUR_DOCKERHUB/napcat-docker:base` |
| `get_artifacts.sh` | NapCatQQ 仓库改为 `YOUR_GITHUB/NapCatQQ` |
| `.github/workflows/docker-publish.yml` | `DOCKER_REPO`、NapCatQQ 仓库改为你的 |
| `.github/workflows/base-docker-publish.yml` | `REGISTRY_IMAGE` 改为 `YOUR_DOCKERHUB/napcat-docker` |

### 3.2 NapCatQQ（仅当你修改 NapCat 插件时需要）

- 修改代码后，在 GitHub 创建 Release，上传 `NapCat.Shell.zip`
- 或启用 Actions 中的 "Build NapCat Artifacts" 工作流自动构建
- NapCat-Docker 的 `get_artifacts.sh` 会从**你的** NapCatQQ Release 拉取

### 3.3 AstrBot（必须修改 + 添加 CI）

- Soulter/AstrBot 仓库有 Docker 支持，需添加 GitHub Actions 将镜像推送到你的 Docker Hub
- 在 AstrBot 仓库创建 `.github/workflows/docker-publish.yml`，参考下方「AstrBot 构建 Workflow 示例」

---

## 四、构建顺序（首次或 base 变更时）

1. **先构建 base 镜像**  
   在 NapCat-Docker 仓库：Actions → base → Run workflow

2. **再构建主镜像**  
   Actions → docker-publish → Run workflow  
   （会从你的 NapCatQQ fork 拉取 NapCat.Shell.zip）

3. **构建 AstrBot 镜像**  
   在 AstrBot 仓库运行你的 Docker 构建 workflow

---

## 五、部署命令（修改后）

```bash
# 从你的 fork 拉取 compose 配置
wget https://raw.githubusercontent.com/YOUR_GITHUB/NapCat-Docker/main/compose/astrbot.yml

# 启动（会拉取 YOUR_DOCKERHUB 的镜像）
sudo docker compose -f astrbot.yml up -d
```

---

## 六、日常修改流程

1. 修改代码 → push 到你的 fork
2. 在 GitHub Actions 手动触发对应 workflow（或配置自动触发）
3. 镜像构建并推送到你的 Docker Hub
4. 服务器执行 `docker compose pull && docker compose -f astrbot.yml up -d` 更新

---

## 七、AstrBot 构建 Workflow 示例

在 `YOUR_GITHUB/AstrBot` 仓库创建 `.github/workflows/docker-publish.yml`：

```yaml
name: docker-publish

on:
  workflow_dispatch:
  push:
    branches: [main]
    tags: ['v*']

env:
  DOCKER_REPO: YOUR_DOCKERHUB_USERNAME/astrbot

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: docker/setup-buildx-action@v3
      - uses: docker/login-action@v3
        with:
          username: ${{ secrets.DOCKERHUB_USERNAME }}
          password: ${{ secrets.DOCKERHUB_TOKEN }}
      - uses: docker/build-push-action@v5
        with:
          context: .
          push: true
          tags: |
            ${{ env.DOCKER_REPO }}:latest
            ${{ env.DOCKER_REPO }}:${{ github.sha }}
```

在仓库 Settings → Secrets 中配置 `DOCKERHUB_USERNAME` 和 `DOCKERHUB_TOKEN`。

---

## 八、占位符替换表

将以下占位符替换为你的实际值（建议全局搜索替换）：

| 占位符 | 所在文件 | 替换为 |
|--------|----------|--------|
| `YOUR_DOCKERHUB_USERNAME` | compose/astrbot.yml | 你的 Docker Hub 用户名 |
| `mlikiowa/napcat-docker` | .github/workflows/*.yml, Dockerfile | 你的用户名/napcat-docker |
| `NapNeko/NapCatQQ` | .github/workflows/docker-publish.yml | 你的用户名/NapCatQQ（若 fork 了 NapCatQQ） |
