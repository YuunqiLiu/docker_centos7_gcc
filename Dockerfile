FROM centos:7

# 更新系统并安装基础工具
RUN yum install -y centos-release-scl epel-release && \
    yum install -y \
    wget \
    curl \
    make \
    gcc \
    gcc-c++ \
    && yum clean all

# 安装 devtoolset-11 (CentOS 7 SCL 中可用的最新版本包含 GCC 11)
# 注意：SCL 官方仓库中没有 GCC 13，最高为 GCC 11
RUN yum install -y devtoolset-11-gcc devtoolset-11-gcc-c++ devtoolset-11-binutils && \
    yum clean all

# 或者，从第三方源下载预编译的 GCC 13
# 创建安装目录
RUN mkdir -p /opt/gcc-13

# 下载预编译的 GCC 13（使用 Red Hat Developer Toolset 或第三方源）
# 方案1: 从官方 GNU 镜像站下载预编译版本
WORKDIR /tmp
RUN wget -q https://ftp.gnu.org/gnu/gcc/gcc-13.2.0/gcc-13.2.0.tar.gz || \
    wget -q https://mirrors.tuna.tsinghua.edu.cn/gnu/gcc/gcc-13.2.0/gcc-13.2.0.tar.gz

# 注意：上面是源码包，如果需要预编译的二进制文件，可以使用以下方案
# 方案2: 从第三方预编译源下载（例如 Conan Center 或其他镜像）
RUN yum install -y centos-release-scl-rh && \
    yum clean all

# 设置环境变量以使用 devtoolset-11
ENV PATH="/opt/rh/devtoolset-11/root/usr/bin:${PATH}" \
    LD_LIBRARY_PATH="/opt/rh/devtoolset-11/root/usr/lib64:/opt/rh/devtoolset-11/root/usr/lib:${LD_LIBRARY_PATH}" \
    MANPATH="/opt/rh/devtoolset-11/root/usr/share/man:${MANPATH}" \
    INFOPATH="/opt/rh/devtoolset-11/root/usr/share/info:${INFOPATH}" \
    PCP_DIR="/opt/rh/devtoolset-11/root" \
    PERL5LIB="/opt/rh/devtoolset-11/root/usr/lib64/perl5/vendor_perl:/opt/rh/devtoolset-11/root/usr/lib/perl5:/opt/rh/devtoolset-11/root/usr/share/perl5/vendor_perl:${PERL5LIB}" \
    PYTHONPATH="/opt/rh/devtoolset-11/root/usr/lib64/python2.7/site-packages:/opt/rh/devtoolset-11/root/usr/lib/python2.7/site-packages:${PYTHONPATH}"

WORKDIR /workspace

# 验证安装
RUN gcc --version && g++ --version

CMD ["/bin/bash"]
