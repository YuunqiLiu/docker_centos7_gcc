# CentOS 7 GCC Docker 镜像

基于 CentOS 7 的 Docker 镜像，包含预编译的 GCC 工具链。

> 📚 **快速上手**: 查看 [快速使用指南](QUICK_GUIDE.md) 了解构建、使用、保存和推送镜像的详细步骤。

## 快速开始

```bash
# 使用自动化脚本（推荐）
./docker-workflow.sh all        # 构建并测试

# 或手动构建
docker build -t centos7-gcc13:latest -f Dockerfile.gcc13-prebuilt .

# 编译你的程序（挂载当前目录）
docker run --rm -v $(pwd):/workspace centos7-gcc13:latest bash -c "
  gcc /workspace/your_program.c -o /workspace/your_program
"

# 编译结果保存在当前目录，可直接运行
./your_program
```

**注意**: C++ 程序需要添加 `-static-libstdc++ -static-libgcc` 选项。

## 自动化脚本

本项目提供了 `docker-workflow.sh` 脚本来自动化常见任务：

### 基本用法

```bash
# 构建镜像
./docker-workflow.sh build

# 测试镜像（编译 C++20 代码并验证 glibc 2.17 兼容性）
./docker-workflow.sh test

# 构建 + 测试
./docker-workflow.sh all

# 推送到 Docker Hub
./docker-workflow.sh push -u your_username

# 保存镜像为本地文件
./docker-workflow.sh save

# 清理测试文件
./docker-workflow.sh clean

# 查看帮助
./docker-workflow.sh --help
```

### 测试内容

`test` 命令会：
1. 检查系统信息（CentOS 7, glibc 2.17, GCC 13）
2. 编译 C++20 测试程序（包含 Concepts、constexpr、consteval 等特性）
3. 运行测试程序验证功能
4. 检查程序链接的 glibc 版本，确保兼容 CentOS 7 的 glibc 2.17

详细测试报告见 [TEST_REPORT.md](TEST_REPORT.md)。

## 可用版本

### 1. Dockerfile - GCC 11 (devtoolset-11)
使用 Red Hat Software Collections (SCL) 官方仓库中的 devtoolset-11，包含 GCC 11。
- **优点**: 官方支持，稳定可靠
- **缺点**: 最高只到 GCC 11，没有 GCC 13

### 2. Dockerfile.gcc13-prebuilt - GCC 13
使用 Bootlin 提供的预编译 GCC 13 工具链。
- **优点**: 包含最新的 GCC 13
- **缺点**: C++ 程序需要静态链接标准库（`-static-libstdc++ -static-libgcc`）

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

### 在容器内执行单个命令
不进入交互式终端，直接执行命令：
```bash
# 查看 GCC 版本
docker run --rm centos7-gcc13:latest gcc --version

# 编译单个文件
docker run --rm -v $(pwd):/workspace centos7-gcc13:latest gcc /workspace/test.c -o /workspace/test

# 执行复杂命令
docker run --rm -v $(pwd):/workspace centos7-gcc13:latest bash -c "cd /workspace && gcc main.c -o app && ./app"
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

### C++ 程序编译注意事项（GCC 13 版本）
GCC 13 镜像中，C++ 程序需要静态链接标准库以兼容 CentOS 7 的 glibc 2.17：
```bash
# C 程序（无需特殊选项）
gcc program.c -o program

# C++ 程序（必须静态链接标准库）
g++ program.cpp -o program -std=c++14 -static-libstdc++ -static-libgcc
```

详细测试报告见 [TEST_REPORT.md](TEST_REPORT.md)。

## 挂载本地目录
```bash
docker run -it --rm -v $(pwd):/workspace centos7-gcc13:latest
```

## 编译文件存储位置

### 容器内编译
在容器内编译的文件默认存储在容器的文件系统中，容器删除后文件也会丢失。

### 保存编译结果到本地
使用 `-v` 参数挂载本地目录，编译结果会直接保存在本地：
```bash
# 挂载当前目录到容器的 /workspace
docker run --rm -v $(pwd):/workspace centos7-gcc13:latest bash -c "
  gcc /workspace/test.c -o /workspace/test
"

# 编译完成后，test 可执行文件会保存在当前目录
ls -l test
```

### 推荐工作流程
```bash
# 1. 在本地目录准备源代码
cd /path/to/your/project

# 2. 启动容器并挂载当前目录
docker run -it --rm -v $(pwd):/workspace centos7-gcc13:latest

# 3. 在容器内编译（文件会保存到本地）
cd /workspace
gcc main.c -o app
exit

# 4. 在本地查看编译结果
ls -l app
```

## 镜像管理

### 查看本地镜像
```bash
docker images | grep centos7-gcc
```

### 保存镜像到本地文件
将 Docker 镜像导出为 tar 文件，方便分发或备份：
```bash
# 保存单个镜像
docker save centos7-gcc13:latest -o centos7-gcc13.tar

# 保存时压缩（推荐）
docker save centos7-gcc13:latest | gzip > centos7-gcc13.tar.gz
```

### 从本地文件加载镜像
```bash
# 加载未压缩的镜像
docker load -i centos7-gcc13.tar

# 加载压缩的镜像
docker load -i centos7-gcc13.tar.gz
```

### 推送到 Docker Hub
```bash
# 1. 登录 Docker Hub
docker login

# 2. 给镜像打标签（使用你的 Docker Hub 用户名）
docker tag centos7-gcc13:latest yourusername/centos7-gcc13:latest
docker tag centos7-gcc13:latest yourusername/centos7-gcc13:1.0

# 3. 推送镜像
docker push yourusername/centos7-gcc13:latest
docker push yourusername/centos7-gcc13:1.0
```

### 推送到其他镜像仓库

#### GitHub Container Registry (ghcr.io)
```bash
# 1. 创建 GitHub Personal Access Token (需要 write:packages 权限)

# 2. 登录 GitHub Container Registry
echo $GITHUB_TOKEN | docker login ghcr.io -u USERNAME --password-stdin

# 3. 打标签并推送
docker tag centos7-gcc13:latest ghcr.io/yourusername/centos7-gcc13:latest
docker push ghcr.io/yourusername/centos7-gcc13:latest
```

#### 阿里云容器镜像服务
```bash
# 1. 登录阿里云镜像仓库
docker login --username=your_username registry.cn-hangzhou.aliyuncs.com

# 2. 打标签并推送
docker tag centos7-gcc13:latest registry.cn-hangzhou.aliyuncs.com/namespace/centos7-gcc13:latest
docker push registry.cn-hangzhou.aliyuncs.com/namespace/centos7-gcc13:latest
```

### 从镜像仓库拉取
```bash
# Docker Hub
docker pull yourusername/centos7-gcc13:latest

# GitHub Container Registry
docker pull ghcr.io/yourusername/centos7-gcc13:latest

# 阿里云
docker pull registry.cn-hangzhou.aliyuncs.com/namespace/centos7-gcc13:latest
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