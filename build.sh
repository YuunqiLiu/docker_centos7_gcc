#!/bin/bash

# 构建 Docker 镜像的脚本

echo "选择要构建的镜像版本："
echo "1) 使用 devtoolset-11 (GCC 11) - 官方 SCL 仓库"
echo "2) 使用预编译的 GCC 13 - conda-forge"

read -p "请选择 [1-2]: " choice

case $choice in
    1)
        echo "构建使用 devtoolset-11 的镜像..."
        docker build -t centos7-gcc11:latest -f Dockerfile .
        ;;
    2)
        echo "构建使用预编译 GCC 13 的镜像..."
        docker build -t centos7-gcc13:latest -f Dockerfile.gcc13-prebuilt .
        ;;
    *)
        echo "无效选择"
        exit 1
        ;;
esac

echo "构建完成！"
