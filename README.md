# CentOS 7 GCC Docker 镜像

基于 CentOS 7 的 Docker 镜像，包含预编译的 GCC 工具链。

## 可用版本

### 1. Dockerfile - GCC 11 (devtoolset-11)
使用 Red Hat Software Collections (SCL) 官方仓库中的 devtoolset-11，包含 GCC 11。
- **优点**: 官方支持，稳定可靠
- **缺点**: 最高只到 GCC 11，没有 GCC 13

### 2. Dockerfile.gcc13-prebuilt - GCC 13
使用 conda-forge 提供的预编译 GCC 13 工具链。
- **优点**: 包含最新的 GCC 13
- **缺点**: 来自第三方源（conda-forge）

## 构建镜像

### 方法 1: 使用构建脚本
```bash
chmod +x build.sh
./build.sh
```

### 方法 2: 手动构建

#### 构建 GCC 11 版本：
```bash
docker build -t centos7-gcc11:latest -f Dockerfile .
```

#### 构建 GCC 13 版本：
```bash
docker build -t centos7-gcc13:latest -f Dockerfile.gcc13-prebuilt .
```

## 使用镜像

### 运行容器
```bash
# GCC 11 版本
docker run -it --rm centos7-gcc11:latest

# GCC 13 版本
docker run -it --rm centos7-gcc13:latest
```

### 验证 GCC 版本
在容器内运行：
```bash
gcc --version
g++ --version
```

### 编译示例程序
```bash
# 在容器内
echo '#include <stdio.h>
int main() {
    printf("Hello from GCC!\\n");
    return 0;
}' > test.c

gcc test.c -o test
./test
```

## 挂载本地目录
```bash
docker run -it --rm -v $(pwd):/workspace centos7-gcc13:latest
```

## 关于 SCL 和 GCC 版本

CentOS 7 的官方 SCL 仓库中：
- devtoolset-7: GCC 7
- devtoolset-8: GCC 8
- devtoolset-9: GCC 9
- devtoolset-10: GCC 10
- devtoolset-11: GCC 11

**注意**: 官方 SCL 仓库没有提供 GCC 13 的 devtoolset。要使用 GCC 13，需要从第三方源（如 conda-forge）获取预编译版本。

## 第三方预编译源

1. **conda-forge**: 通过 Anaconda/Miniconda 提供
2. **Bootlin Toolchains**: https://toolchains.bootlin.com/
3. **Linaro**: 提供 ARM 架构的工具链
4. **自行编译**: 从 GNU 官方下载源码编译（耗时较长）

## 许可证

本项目遵循 MIT 许可证。GCC 工具链遵循各自的许可证（通常为 GPL）。