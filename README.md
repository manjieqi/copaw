# copaw

精简增强版 [QwenPaw](https://github.com/agentscope-ai/QwenPaw) Docker 镜像。

## vs 官方镜像

| | official | copaw |
|---|---|---|
| 桌面环境 | Xvfb + XFCE4 | ❌ 无头 Chromium |
| Chromium | 系统 apt 装 | Playwright 自管 |
| 文档技能 | ❌ | ✅ pandoc / poppler / qpdf / ffmpeg / LibreOffice（可选） |
| Python 技能包 | 仅 qwenpaw 核心 | ✅ 全套（openpyxl / pandas / pypdf / dashscope …） |
| npm 技能包 | ❌ | ✅ docx + pptxgenjs |
| gh CLI | ❌ | ✅ |
| 中文字体 | ✅ | ✅ wqy-zenhei + wqy-microhei |
| 镜像体积 | ~1.8GB | ~2.5GB（跳过 LibreOffice ~2.1GB） |

## 快速开始

### docker

```bash
docker pull manjieqi/copaw

docker run -d --name copaw --restart unless-stopped -p 8088:8088 \
  -v ./data:/app/data \
  -v ./secret:/app/secret \
  -v ./backups:/app/backups \
  -v playwright-cache:/root/.cache/ms-playwright \
  -e QWENPAW_PORT=8088 \
  manjieqi/copaw
```

### wslc

```powershell
wslc pull manjieqi/copaw

wslc run -d --name copaw -p 8088:8088 -v "${PWD}\data:/app/data" -v "${PWD}\secret:/app/secret" -v "${PWD}\backups:/app/backups" -v playwright-cache:/root/.cache/ms-playwright -e QWENPAW_PORT=8088 manjieqi/copaw
```

或用 compose：

```bash
mkdir -p data secret backups
docker compose up -d
```

首次启动会自动执行 `qwenpaw init --defaults --accept-security`，无需手动初始化。

## 本地构建

```bash
# 国内网络（默认启用国内镜像）
docker build -t manjieqi/copaw .

# 海外网络
docker build --build-arg USE_CHINA_MIRROR=false -t manjieqi/copaw .

# 跳过 LibreOffice（省 ~400MB）
docker build --build-arg WITH_LIBREOFFICE=false -t manjieqi/copaw .
```

### wslc（WSL 原生容器运行时）

```powershell
wslc run -d --name copaw -p 8088:8088 -v "${PWD}\data:/app/data" -v "${PWD}\secret:/app/secret" -v "${PWD}\backups:/app/backups" -v playwright-cache:/root/.cache/ms-playwright -e QWENPAW_PORT=8088 manjieqi/copaw
```
