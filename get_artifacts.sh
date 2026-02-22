#!/bin/bash

token="$1"
version="$2"

# 设置输出目录
output_dir="."
# NapCatQQ 仓库：改为你的 fork 则使用自构建的 NapCat
NAPCATQQ_REPO="${NAPCATQQ_REPO:-komeiji-renshi/NapCatQQ}"
# 下载release
curl -s -X GET \
    -H "Authorization: token $token" \
    -L "https://github.com/${NAPCATQQ_REPO}/releases/download/$version/NapCat.Shell.zip" \
    -o "$output_dir/NapCat.Shell.zip"

echo "编译产物已保存到$output_dir (from ${NAPCATQQ_REPO})"
ls -lh
