FROM ghcr.io/astral-sh/uv:latest AS uv
FROM python:3.12-slim

ARG WITH_LIBREOFFICE=true
ARG USE_CHINA_MIRROR=true
ARG GH_VERSION=2.96.0

# ── apt 源 ──
RUN if [ "$USE_CHINA_MIRROR" = "true" ]; then \
      sed -i 's|http://deb.debian.org|https://mirrors.tuna.tsinghua.edu.cn|g' /etc/apt/sources.list.d/debian.sources \
      && sed -i 's|http://security.debian.org|https://mirrors.tuna.tsinghua.edu.cn/debian-security|g' /etc/apt/sources.list.d/debian.sources; \
    fi

# ── 系统基础包（含中文字体）──
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl ca-certificates git gnupg \
    fonts-wqy-zenhei fonts-wqy-microhei \
    pandoc poppler-utils qpdf ffmpeg \
    && rm -rf /var/lib/apt/lists/*

# ── Node.js 24 ──
RUN if [ "$USE_CHINA_MIRROR" = "true" ]; then \
      curl -fsSL https://npmmirror.com/mirrors/nodesource/setup_24.x | bash -; \
    else \
      curl -fsSL https://deb.nodesource.com/setup_24.x | bash -; \
    fi \
    && apt-get install -y nodejs \
    && rm -rf /var/lib/apt/lists/*

# ── npm 源 ──
RUN if [ "$USE_CHINA_MIRROR" = "true" ]; then \
      npm config set registry https://registry.npmmirror.com; \
    fi

# ── git 镜像 ──
RUN if [ "$USE_CHINA_MIRROR" = "true" ]; then \
      git config --global url."https://ghproxy.net/https://github.com".insteadOf https://github.com; \
    fi

# ── 目录 ──
RUN mkdir -p /app/data /app/secret /app/backups
WORKDIR /app

# ── uv ──
COPY --from=uv /uv /bin/uv

# ── 虚拟环境 ──
RUN uv venv /app/venv
ENV PATH="/app/venv/bin:$PATH"

# ── Python 包 ──
RUN if [ "$USE_CHINA_MIRROR" = "true" ]; then \
      mkdir -p /root/.config/uv \
      && printf '[index]\nurl = "https://pypi.tuna.tsinghua.edu.cn/simple"\ndefault = true\n' > /root/.config/uv/uv.toml \
      && pip config set global.index-url https://pypi.tuna.tsinghua.edu.cn/simple; \
    fi \
    && uv pip install --no-cache-dir \
        qwenpaw \
        openpyxl pandas \
        Markdown Jinja2 fonttools brotli Pillow \
        python-pptx "markitdown[pptx]" \
        pypdf pdfplumber reportlab \
        dashscope yescan

# ── Playwright 浏览器 ──
RUN if [ "$USE_CHINA_MIRROR" = "true" ]; then \
      PLAYWRIGHT_DOWNLOAD_HOST=https://npmmirror.com/mirrors/playwright \
      playwright install-deps chromium \
      && PLAYWRIGHT_DOWNLOAD_HOST=https://npmmirror.com/mirrors/playwright \
      playwright install chromium; \
    else \
      playwright install-deps chromium \
      && playwright install chromium; \
    fi

# ── npm 技能包 ──
RUN npm install -g docx pptxgenjs && npm cache clean --force

# ── GitHub CLI ──
RUN if [ "$USE_CHINA_MIRROR" = "true" ]; then \
      curl -fsSL "https://ghproxy.net/https://github.com/cli/cli/releases/download/v${GH_VERSION}/gh_${GH_VERSION}_linux_amd64.tar.gz" \
        | tar xz -C /usr/local --strip-components=1; \
    else \
      curl -fsSL "https://github.com/cli/cli/releases/download/v${GH_VERSION}/gh_${GH_VERSION}_linux_amd64.tar.gz" \
        | tar xz -C /usr/local --strip-components=1; \
    fi

# ── LibreOffice（可选，~400MB）──
RUN if [ "$WITH_LIBREOFFICE" = "true" ]; then \
      apt-get update && apt-get install -y --no-install-recommends libreoffice \
      && rm -rf /var/lib/apt/lists/*; \
    fi

# ── 环境变量 ──
ENV WORKSPACE_DIR=/app
ENV QWENPAW_WORKING_DIR=/app/data
ENV QWENPAW_SECRET_DIR=/app/secret
ENV QWENPAW_BACKUP_DIR=/app/backups
ENV QWENPAW_RUNNING_IN_CONTAINER=1

EXPOSE 8088
CMD ["/bin/sh", "-c", "\
    set -e; \
    if [ ! -f /app/data/config.json ]; then \
        echo '📦 First run — initializing...'; \
        qwenpaw init --defaults --accept-security; \
        echo '✅ Init done.'; \
    fi; \
    exec qwenpaw app --host 0.0.0.0 --port ${QWENPAW_PORT:-8088} \
"]
