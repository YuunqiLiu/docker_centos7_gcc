# 快速使用指南

## 1️⃣ 如何构建镜像

```bash
# 构建 GCC 13 版本
docker build -t centos7-gcc13:latest -f Dockerfile.gcc13-prebuilt .

# 或构建 GCC 11 版本
docker build -t centos7-gcc11:latest -f Dockerfile .
```

**构建时间**: 约 5-10 分钟（取决于网络速度）

---

## 2️⃣ 编译结果保存在哪里？

### 情况 1: 容器内编译（不推荐）
```bash
docker run -it centos7-gcc13:latest
# 在容器内编译的文件保存在容器文件系统中
# ⚠️ 容器删除后文件会丢失
```

### 情况 2: 挂载本地目录（✅ 推荐）
```bash
# 挂载当前目录到容器的 /workspace
docker run --rm -v $(pwd):/workspace centos7-gcc13:latest bash -c "
  gcc /workspace/test.c -o /workspace/test
"

# ✅ 编译结果保存在当前目录（本地）
ls -l test
```

**推荐**: 始终使用 `-v $(pwd):/workspace` 挂载本地目录，这样编译结果会直接保存到本地。

---

## 3️⃣ 如何保存镜像到本地文件

### 导出镜像为 tar 文件
```bash
# 保存为 tar 文件（约 1-2 GB）
docker save centos7-gcc13:latest -o centos7-gcc13.tar

# 保存并压缩（推荐，约 500-800 MB）
docker save centos7-gcc13:latest | gzip > centos7-gcc13.tar.gz
```

### 在其他机器上加载镜像
```bash
# 加载 tar 文件
docker load -i centos7-gcc13.tar

# 或加载压缩文件
docker load -i centos7-gcc13.tar.gz

# 验证加载成功
docker images | grep centos7-gcc13
```

---

## 4️⃣ 如何推送到镜像托管平台

### 推送到 Docker Hub
```bash
# 1. 登录 Docker Hub
docker login

# 2. 给镜像打标签（替换 yourusername 为你的用户名）
docker tag centos7-gcc13:latest yourusername/centos7-gcc13:latest

# 3. 推送镜像
docker push yourusername/centos7-gcc13:latest

# 4. 其他人可以拉取使用
docker pull yourusername/centos7-gcc13:latest
```

### 推送到 GitHub Container Registry
```bash
# 1. 创建 Personal Access Token (需要 write:packages 权限)
#    GitHub → Settings → Developer settings → Personal access tokens

# 2. 登录 ghcr.io
echo $GITHUB_TOKEN | docker login ghcr.io -u USERNAME --password-stdin

# 3. 打标签并推送
docker tag centos7-gcc13:latest ghcr.io/yourusername/centos7-gcc13:latest
docker push ghcr.io/yourusername/centos7-gcc13:latest
```

### 推送到阿里云容器镜像服务
```bash
# 1. 登录阿里云（需要先在阿里云创建命名空间）
docker login --username=your_aliyun_username registry.cn-hangzhou.aliyuncs.com

# 2. 打标签并推送
docker tag centos7-gcc13:latest registry.cn-hangzhou.aliyuncs.com/namespace/centos7-gcc13:latest
docker push registry.cn-hangzhou.aliyuncs.com/namespace/centos7-gcc13:latest
```

---

## 5️⃣ 如何在容器内执行单个命令

### 执行简单命令
```bash
# 查看 GCC 版本
docker run --rm centos7-gcc13:latest gcc --version

# 查看系统信息
docker run --rm centos7-gcc13:latest cat /etc/redhat-release

# 查看 glibc 版本
docker run --rm centos7-gcc13:latest ldd --version
```

### 编译单个文件
```bash
# 编译 C 程序
docker run --rm -v $(pwd):/workspace centos7-gcc13:latest \
  gcc /workspace/test.c -o /workspace/test

# 编译 C++ 程序（注意静态链接选项）
docker run --rm -v $(pwd):/workspace centos7-gcc13:latest \
  g++ /workspace/test.cpp -o /workspace/test -std=c++14 -static-libstdc++ -static-libgcc
```

### 执行复杂命令（使用 bash -c）
```bash
docker run --rm -v $(pwd):/workspace centos7-gcc13:latest bash -c "
  cd /workspace &&
  gcc main.c utils.c -o app &&
  ./app &&
  echo 'Compilation and execution completed!'
"
```

### 批量编译项目
```bash
docker run --rm -v $(pwd):/workspace centos7-gcc13:latest bash -c "
  cd /workspace &&
  make clean &&
  make -j$(nproc) &&
  make install
"
```

---

## 💡 常用命令速查

```bash
# 构建镜像
docker build -t centos7-gcc13:latest -f Dockerfile.gcc13-prebuilt .

# 交互式运行容器
docker run -it --rm -v $(pwd):/workspace centos7-gcc13:latest

# 执行单个命令
docker run --rm -v $(pwd):/workspace centos7-gcc13:latest gcc test.c -o test

# 查看本地镜像
docker images | grep centos7-gcc

# 删除镜像
docker rmi centos7-gcc13:latest

# 保存镜像到文件
docker save centos7-gcc13:latest | gzip > centos7-gcc13.tar.gz

# 从文件加载镜像
docker load -i centos7-gcc13.tar.gz

# 推送到 Docker Hub
docker tag centos7-gcc13:latest username/centos7-gcc13:latest
docker push username/centos7-gcc13:latest
```

---

## ⚠️ 重要提示

### C++ 编译注意事项
GCC 13 镜像中，C++ 程序必须静态链接标准库：
```bash
g++ program.cpp -o program -static-libstdc++ -static-libgcc
```
原因：Bootlin 工具链的 libstdc++ 依赖较新的 glibc，而 CentOS 7 只有 glibc 2.17。

### C 程序无限制
C 程序可以直接编译，无需特殊选项：
```bash
gcc program.c -o program
```

详细测试报告见 [TEST_REPORT.md](TEST_REPORT.md)。
