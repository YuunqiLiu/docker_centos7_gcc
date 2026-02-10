#!/bin/bash

# 简化的构建脚本 - 使用最新的 GCC 13 版本
# 如需更多选项，请使用 docker-workflow.sh

echo "=========================================="
echo " CentOS 7 + GCC 13 Docker 镜像构建"
echo "=========================================="
echo

# 检查 docker-workflow.sh 是否存在
if [ -f "./docker-workflow.sh" ]; then
    echo "使用 docker-workflow.sh 构建镜像..."
    ./docker-workflow.sh build
else
    echo "构建 GCC 13 镜像..."
    docker build -t centos7-gcc13:latest -f Dockerfile.gcc13-prebuilt .
fi

echo
echo "=========================================="
echo " 构建完成！"
echo "=========================================="
echo
echo "下一步："
echo "  运行测试: ./docker-workflow.sh test"
echo "  查看帮助: ./docker-workflow.sh --help"
echo "  或手动运行: docker run -it --rm centos7-gcc13:latest"
