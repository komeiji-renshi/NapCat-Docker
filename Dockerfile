# 自托管：改为你的 Docker Hub 用户名/napcat-docker（与 base workflow 推送的镜像一致）
FROM koiuta/napcat-docker:base

RUN useradd --no-log-init -d /app napcat

WORKDIR /app

COPY NapCat.Shell.zip entrypoint.sh templates /app/
# 安装Linux QQ
RUN arch=$(arch | sed s/aarch64/arm64/ | sed s/x86_64/amd64/) && \
    curl -o linuxqq.deb https://dldir1v6.qq.com/qqfile/qq/QQNT/7516007c/linuxqq_3.2.25-45758_${arch}.deb && \
    dpkg -i --force-depends linuxqq.deb && rm linuxqq.deb && \
    chmod +x entrypoint.sh && \
    echo "(async () => {await import('file:///app/napcat/napcat.mjs');})();" > /opt/QQ/resources/app/loadNapCat.js && \
    sed -i 's|"main": "[^"]*"|"main": "./loadNapCat.js"|' /opt/QQ/resources/app/package.json

VOLUME /app/napcat/config
VOLUME /app/.config/QQ

ENTRYPOINT ["bash", "entrypoint.sh"]

