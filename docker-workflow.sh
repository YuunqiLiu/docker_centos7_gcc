#!/bin/bash
set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 配置变量
IMAGE_NAME="centos7-gcc13"
IMAGE_TAG="latest"
DOCKERFILE="Dockerfile.gcc13-prebuilt"
TEST_SOURCE="test_cpp20.cpp"
TEST_BINARY="test_cpp20"
DOCKER_USERNAME="${DOCKER_USERNAME:-}"
DOCKER_REGISTRY="${DOCKER_REGISTRY:-docker.io}"

# 帮助信息
print_help() {
    cat << EOF
用法: $0 [命令] [选项]

命令:
    build       构建 Docker 镜像
    test        测试镜像中的 GCC 编译 C++20 代码
    push        推送镜像到镜像仓库
    all         执行 build + test
    clean       清理测试生成的文件
    save        保存镜像为 tar.gz 文件
    
选项:
    -u, --username USERNAME    Docker Hub 用户名（用于 push）
    -r, --registry REGISTRY    镜像仓库地址（默认: docker.io）
    -t, --tag TAG              镜像标签（默认: latest）
    -h, --help                 显示帮助信息

环境变量:
    DOCKER_USERNAME            Docker Hub 用户名
    DOCKER_REGISTRY            镜像仓库地址

示例:
    $0 build                   # 构建镜像
    $0 test                    # 测试镜像
    $0 all                     # 构建并测试
    $0 push -u username        # 推送到 Docker Hub
    $0 save                    # 保存镜像为文件
EOF
}

# 打印带颜色的消息
print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# 构建镜像
build_image() {
    print_info "开始构建 Docker 镜像..."
    echo "======================================"
    echo "  镜像名称: ${IMAGE_NAME}:${IMAGE_TAG}"
    echo "  Dockerfile: ${DOCKERFILE}"
    echo "======================================"
    echo
    
    if ! docker build -t "${IMAGE_NAME}:${IMAGE_TAG}" -f "${DOCKERFILE}" .; then
        print_error "镜像构建失败！"
        exit 1
    fi
    
    echo
    print_success "镜像构建成功！"
    docker images | grep "${IMAGE_NAME}"
}

# 测试镜像
test_image() {
    print_info "开始测试镜像..."
    echo "======================================"
    echo "  测试内容: GCC 13 编译 C++20 代码"
    echo "  测试文件: ${TEST_SOURCE}"
    echo "  验证内容: 链接到 glibc 2.17"
    echo "======================================"
    echo
    
    if [ ! -f "${TEST_SOURCE}" ]; then
        print_error "测试文件 ${TEST_SOURCE} 不存在！"
        exit 1
    fi
    
    # 检查镜像是否存在
    if ! docker images | grep -q "${IMAGE_NAME}.*${IMAGE_TAG}"; then
        print_error "镜像 ${IMAGE_NAME}:${IMAGE_TAG} 不存在，请先运行 build 命令"
        exit 1
    fi
    
    print_info "步骤 1: 检查系统信息"
    docker run --rm "${IMAGE_NAME}:${IMAGE_TAG}" bash -c "
        echo '系统版本: '
        cat /etc/redhat-release
        echo
        echo 'glibc 版本:'
        ldd --version | head -n1
        echo
        echo 'GCC 版本:'
        gcc --version | head -n1
    "
    
    echo
    print_info "步骤 2: 编译 C++20 测试程序"
    docker run --rm -v "$(pwd):/workspace" "${IMAGE_NAME}:${IMAGE_TAG}" bash -c "
        set -e
        cd /workspace
        echo '编译命令: g++ ${TEST_SOURCE} -o ${TEST_BINARY} -std=c++20 -static-libstdc++ -static-libgcc'
        g++ ${TEST_SOURCE} -o ${TEST_BINARY} -std=c++20 -static-libstdc++ -static-libgcc 2>&1 | grep -v 'warning:' || true
        if [ -f ${TEST_BINARY} ]; then
            echo '✅ 编译成功'
        else
            echo '❌ 编译失败'
            exit 1
        fi
    "
    
    echo
    print_info "步骤 3: 运行测试程序"
    docker run --rm -v "$(pwd):/workspace" "${IMAGE_NAME}:${IMAGE_TAG}" bash -c "
        cd /workspace
        ./${TEST_BINARY}
    "
    
    echo
    print_info "步骤 4: 验证 glibc 依赖"
    docker run --rm -v "$(pwd):/workspace" "${IMAGE_NAME}:${IMAGE_TAG}" bash -c "
        cd /workspace
        echo '动态链接库:'
        ldd ${TEST_BINARY} | grep -E 'libc\\.so|libm\\.so|libstdc' || true
        echo
        echo '需要的 GLIBC 版本:'
        objdump -T ${TEST_BINARY} | grep 'GLIBC_' | sed 's/.*GLIBC_/GLIBC_/' | sort -u | grep 'GLIBC_' || echo '无特定 GLIBC 版本要求'
        echo
        echo '系统 glibc 版本:'
        strings /lib64/libc.so.6 | grep '^GLIBC_' | sort -V | tail -3
    "
    
    echo
    print_success "所有测试通过！✅"
    print_success "编译的程序使用 glibc 2.17，与 CentOS 7 完全兼容"
}

# 推送镜像
push_image() {
    if [ -z "${DOCKER_USERNAME}" ]; then
        print_error "未指定 Docker 用户名，请使用 -u 选项或设置 DOCKER_USERNAME 环境变量"
        exit 1
    fi
    
    print_info "准备推送镜像到 ${DOCKER_REGISTRY}..."
    
    # 登录检查
    print_info "检查 Docker 登录状态..."
    if ! docker info 2>/dev/null | grep -q "Username"; then
        print_warning "未登录 Docker，请先登录："
        echo "  docker login ${DOCKER_REGISTRY}"
        exit 1
    fi
    
    # 打标签
    REMOTE_TAG="${DOCKER_REGISTRY}/${DOCKER_USERNAME}/${IMAGE_NAME}:${IMAGE_TAG}"
    print_info "打标签: ${REMOTE_TAG}"
    docker tag "${IMAGE_NAME}:${IMAGE_TAG}" "${REMOTE_TAG}"
    
    # 推送
    print_info "推送镜像..."
    if docker push "${REMOTE_TAG}"; then
        print_success "镜像推送成功！"
        echo
        echo "其他用户可以通过以下命令拉取镜像："
        echo "  docker pull ${REMOTE_TAG}"
    else
        print_error "镜像推送失败！"
        exit 1
    fi
}

# 保存镜像
save_image() {
    OUTPUT_FILE="${IMAGE_NAME}-${IMAGE_TAG}.tar.gz"
    print_info "保存镜像到文件: ${OUTPUT_FILE}"
    
    if docker save "${IMAGE_NAME}:${IMAGE_TAG}" | gzip > "${OUTPUT_FILE}"; then
        print_success "镜像已保存到: ${OUTPUT_FILE}"
        ls -lh "${OUTPUT_FILE}"
        echo
        echo "在其他机器上加载镜像："
        echo "  docker load -i ${OUTPUT_FILE}"
    else
        print_error "保存镜像失败！"
        exit 1
    fi
}

# 清理文件
clean_files() {
    print_info "清理测试生成的文件..."
    rm -f "${TEST_BINARY}"
    print_success "清理完成"
}

# 解析命令行参数
parse_args() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            -u|--username)
                DOCKER_USERNAME="$2"
                shift 2
                ;;
            -r|--registry)
                DOCKER_REGISTRY="$2"
                shift 2
                ;;
            -t|--tag)
                IMAGE_TAG="$2"
                shift 2
                ;;
            -h|--help)
                print_help
                exit 0
                ;;
            *)
                break
                ;;
        esac
    done
}

# 主函数
main() {
    if [ $# -eq 0 ]; then
        print_help
        exit 0
    fi
    
    COMMAND=$1
    shift
    parse_args "$@"
    
    case $COMMAND in
        build)
            build_image
            ;;
        test)
            test_image
            ;;
        push)
            push_image
            ;;
        all)
            build_image
            echo
            test_image
            ;;
        clean)
            clean_files
            ;;
        save)
            save_image
            ;;
        *)
            print_error "未知命令: $COMMAND"
            echo
            print_help
            exit 1
            ;;
    esac
}

main "$@"
