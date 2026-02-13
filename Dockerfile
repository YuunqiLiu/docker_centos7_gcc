FROM quay.io/centos/centos:centos7 AS base


# 替换为阿里云镜像源（国内访问快）
RUN sed -i 's|^mirrorlist=|#mirrorlist=|g' /etc/yum.repos.d/CentOS-*.repo && \
    sed -i 's|^#baseurl=http://mirror.centos.org|baseurl=https://mirrors.aliyun.com|g' /etc/yum.repos.d/CentOS-*.repo && \
    sed -i 's|^baseurl=http://vault.centos.org|baseurl=https://mirrors.aliyun.com|g' /etc/yum.repos.d/CentOS-*.repo && \
    yum makecache fast

# 安装基础依赖
RUN yum install -y which wget curl bzip2 gcc gcc-c++ make gmp-devel mpfr-devel libmpc-devel glibc-static libstdc++-static openssl-devel git && \
    yum clean all

# 下载并安装 Python 3.8 预编译包（使用 Anaconda 的独立 Python）
RUN cd /tmp && \
    wget --progress=bar:force:noscroll https://repo.anaconda.com/miniconda/Miniconda3-py38_23.5.2-0-Linux-x86_64.sh -O miniconda.sh && \
    bash miniconda.sh -b -p /opt/python38 && \
    rm miniconda.sh && \
    ln -sf /opt/python38/bin/python /usr/bin/python3.8 && \
    ln -sf /opt/python38/bin/python /usr/bin/python3 && \
    ln -sf /opt/python38/bin/python /usr/bin/python38 && \
    ln -sf /opt/python38/bin/pip /usr/bin/pip3 && \
    echo "Python 3.8 installed: $(python3.8 --version)" && \
    echo "System Python 2.7 preserved: $(python --version 2>&1 || echo 'not in path')"

# 下载并安装 CMake 3.27.7（预编译二进制版本）
RUN cd /tmp && \
    wget --progress=bar:force:noscroll https://github.com/Kitware/CMake/releases/download/v3.27.7/cmake-3.27.7-linux-x86_64.tar.gz && \
    tar -xzf cmake-3.27.7-linux-x86_64.tar.gz -C /opt && \
    rm cmake-3.27.7-linux-x86_64.tar.gz && \
    ln -sf /opt/cmake-3.27.7-linux-x86_64/bin/cmake /usr/bin/cmake && \
    ln -sf /opt/cmake-3.27.7-linux-x86_64/bin/cmake /usr/bin/cmake3 && \
    ln -sf /opt/cmake-3.27.7-linux-x86_64/bin/ctest /usr/bin/ctest && \
    ln -sf /opt/cmake-3.27.7-linux-x86_64/bin/cpack /usr/bin/cpack && \
    echo "CMake installed: $(cmake --version | head -1)"

# 中间测试阶段（只构建到这里用于验证工具安装）
FROM base AS test-stage
RUN echo "=== 工具验证 ===" && \
    which cmake && which cmake3 && \
    cmake --version && \
    which python3 && which python38 && \
    python3 --version && \
    python38 --version && \
    which git && git --version && \
    gcc --version && \
    echo "=== 工具安装成功 ==="

# 完整构建阶段
FROM base AS builder

# 设置工作目录
WORKDIR /tmp

# 下载 GCC 14.2.0 源码（使用 GNU 官方 FTP 镜像，显示进度条）
RUN echo "开始下载 GCC 14.2.0 源码 (约 150MB)..." && \
    wget --progress=bar:force:noscroll --tries=3 --waitretry=10 \
    https://ftp.gnu.org/gnu/gcc/gcc-14.2.0/gcc-14.2.0.tar.gz \
    -O gcc-14.2.0.tar.gz && \
    echo "下载完成，文件大小: $(du -h gcc-14.2.0.tar.gz | cut -f1)"

# 解压源码
RUN echo "开始解压 GCC 14.2.0 源码..." && \
    tar -xzf gcc-14.2.0.tar.gz && \
    rm gcc-14.2.0.tar.gz && \
    echo "GCC 源码已解压"

# 创建构建目录
RUN mkdir -p /tmp/gcc-build

WORKDIR /tmp/gcc-build

# 配置 GCC（禁用一些不必要的功能以加快编译）
RUN ../gcc-14.2.0/configure \
    --prefix=/opt/gcc-14 \
    --enable-languages=c,c++ \
    --disable-multilib \
    --disable-bootstrap \
    --enable-checking=release

# 编译 GCC（使用 nproc-2 个核心，避免系统卡死）
RUN make -j$(expr $(nproc) - 2 \| 1)

# 安装 GCC
RUN make install

# 清理构建文件
RUN rm -rf /tmp/gcc-14.2.0 /tmp/gcc-build

# 最终镜像
FROM base AS final

# 从builder阶段复制编译好的GCC
COPY --from=builder /opt/gcc-14 /opt/gcc-14

# 设置环境变量
ENV PATH="/opt/gcc-14/bin:${PATH}" \
    LD_LIBRARY_PATH="/opt/gcc-14/lib64:/opt/gcc-14/lib:${LD_LIBRARY_PATH}"

WORKDIR /workspace

# 验证安装
RUN gcc --version && g++ --version && \
    echo "GCC 工具链已成功安装到: /opt/gcc-toolchain"

CMD ["/bin/bash"]

# 优化镜像：移除调试符号和LTO工具
FROM final AS optimized

# 移除LTO相关工具（约660MB）
RUN echo "移除LTO工具以减少镜像大小..." && \
    rm -f /opt/gcc-14/bin/lto-dump && \
    rm -f /opt/gcc-14/libexec/gcc/x86_64-pc-linux-gnu/14.2.0/lto1 && \
    echo "LTO工具已移除"

# Strip编译器二进制文件以移除调试符号（预计减少40-50%）
RUN echo "开始strip编译器二进制文件..." && \
    strip --strip-unneeded /opt/gcc-14/bin/* 2>/dev/null || true && \
    strip --strip-unneeded /opt/gcc-14/libexec/gcc/x86_64-pc-linux-gnu/14.2.0/cc1 2>/dev/null || true && \
    strip --strip-unneeded /opt/gcc-14/libexec/gcc/x86_64-pc-linux-gnu/14.2.0/cc1plus 2>/dev/null || true && \
    strip --strip-unneeded /opt/gcc-14/libexec/gcc/x86_64-pc-linux-gnu/14.2.0/collect2 2>/dev/null || true && \
    strip --strip-unneeded /opt/gcc-14/libexec/gcc/x86_64-pc-linux-gnu/14.2.0/lto-wrapper 2>/dev/null || true && \
    strip --strip-unneeded /opt/gcc-14/libexec/gcc/x86_64-pc-linux-gnu/14.2.0/g++-mapper-server 2>/dev/null || true && \
    echo "调试符号已移除"

# 可选：移除文档和locale文件（约20MB）
RUN echo "移除文档和locale文件..." && \
    rm -rf /opt/gcc-14/share/locale && \
    rm -rf /opt/gcc-14/share/man && \
    rm -rf /opt/gcc-14/share/info && \
    echo "文档和locale文件已移除"

# 显示优化后的大小
RUN echo "优化后的GCC目录大小:" && \
    du -sh /opt/gcc-14

CMD ["/bin/bash"]
