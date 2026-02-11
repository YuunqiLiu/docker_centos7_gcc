.PHONY: build test clean clean-all release opt upload help

IMAGE_NAME := centos7-gcc14:latest
IMAGE_NAME_OPT := centos7-gcc14:slim
DOCKERFILE := Dockerfile.gcc13-prebuilt
BUILD_DIR := build
TEST_DIR := $(BUILD_DIR)/test
RELEASE_DIR := $(BUILD_DIR)/release

build:
	@echo "=== 开始构建 Docker 镜像 ==="
	@mkdir -p $(BUILD_DIR)
	docker build --network=host --build-arg http_proxy=http://127.0.0.1:7897 --build-arg https_proxy=http://127.0.0.1:7897 -t $(IMAGE_NAME) -f $(DOCKERFILE) . 2>&1 | tee $(BUILD_DIR)/build.log
	@echo "=== 构建完成 ==="

test:
	@echo "=== 测试 GCC 14 和 C++20 混合链接 ==="
	@mkdir -p $(TEST_DIR)
	@echo "1. 检查 GCC 版本..."
	@docker run --rm $(IMAGE_NAME) gcc --version | head -1
	@docker run --rm $(IMAGE_NAME) g++ --version | head -1
	@echo "2. 编译 C++20 测试..."
	@docker run --rm -v $(PWD):/workspace $(IMAGE_NAME) g++ -std=c++20 -static-libgcc -static-libstdc++ -pthread -o /workspace/$(TEST_DIR)/test_cpp20 /workspace/test_cpp20.cpp -lm
	@echo "3. 检查依赖..."
	@docker run --rm -v $(PWD):/workspace $(IMAGE_NAME) ldd /workspace/$(TEST_DIR)/test_cpp20
	@echo "4. 验证 GLIBC..."
	@docker run --rm $(IMAGE_NAME) ldd --version | head -1
	@echo "5. 文件大小..."
	@docker run --rm -v $(PWD):/workspace $(IMAGE_NAME) ls -lh /workspace/$(TEST_DIR)/test_cpp20 | awk '{print $$5}'
	@echo "6. 运行测试..."
	@docker run --rm -v $(PWD):/workspace $(IMAGE_NAME) /workspace/$(TEST_DIR)/test_cpp20 | head -10
	@echo "7. NSS 测试..."
	@docker run --rm -v $(PWD):/workspace $(IMAGE_NAME) g++ -std=c++20 -static-libgcc -static-libstdc++ -o /workspace/$(TEST_DIR)/test_nss /workspace/test_nss.cpp -ldl
	@docker run --rm --network=host -v $(PWD):/workspace $(IMAGE_NAME) /workspace/$(TEST_DIR)/test_nss | head -10
	@echo "=== 测试完成 ==="

release:
	@echo "=== 准备镜像上传 ==="
	@mkdir -p $(RELEASE_DIR)
	@echo ""
	@echo "镜像信息："
	@docker images $(IMAGE_NAME) --format="  REPOSITORY:TAG    {{.Repository}}:{{.Tag}}\n  IMAGE ID         {{.ID}}\n  大小              {{.Size}}\n  创建时间         {{.CreatedAt}}"
	@echo ""
	@echo "推送到镜像仓库方法："
	@echo ""
	@echo "1. Docker Hub (官方仓库):"
	@echo "   docker tag $(IMAGE_NAME) <your-dockerhub-username>/centos7-gcc14:latest"
	@echo "   docker login -u <username> -p <password>"
	@echo "   docker push <your-dockerhub-username>/centos7-gcc14:latest"
	@echo ""
	@echo "2. 阿里云容器镜像服务:"
	@echo "   docker tag $(IMAGE_NAME) registry.cn-hangzhou.aliyuncs.com/<your-namespace>/centos7-gcc14:latest"
	@echo "   docker login -u <username> registry.cn-hangzhou.aliyuncs.com"
	@echo "   docker push registry.cn-hangzhou.aliyuncs.com/<your-namespace>/centos7-gcc14:latest"
	@echo ""
	@echo "3. 生成镜像签名文件 (保存到 $(RELEASE_DIR)):"
	@docker inspect $(IMAGE_NAME) --format='{{json .}}' > $(RELEASE_DIR)/image-info.json
	@echo "   已生成: $(RELEASE_DIR)/image-info.json"
	@echo ""
	@echo "=== 准备完成 ==="

opt:
	@echo "=== 优化镜像 (去除所有构建layers) ==="
	@echo ""
	@echo "1. 导出容器文件系统..."
	docker run --name gcc-container $(IMAGE_NAME) true
	docker export gcc-container > /tmp/gcc-export.tar
	@echo "   ✓ 导出完成"
	@echo ""
	@echo "2. 导入为新镜像..."
	docker import /tmp/gcc-export.tar $(IMAGE_NAME_OPT)
	docker rm gcc-container
	rm /tmp/gcc-export.tar
	@echo "   ✓ 导入完成"
	@echo ""
	@echo "3. 镜像对比:"
	@echo "   原镜像: $$(docker images $(IMAGE_NAME) --format='{{.Size}}')"
	@echo "   优化后: $$(docker images $(IMAGE_NAME_OPT) --format='{{.Size}}')"
	@echo ""
	@echo "=== 优化完成 ==="
	@echo ""
	@echo "下一步: make upload"

upload:
	@echo "=== 推送优化镜像到 GitHub Container Registry ==="
	@echo ""
	@docker images $(IMAGE_NAME_OPT) --format="镜像大小: {{.Size}}" || (echo "❌ 优化镜像不存在，请先运行: make opt" && exit 1)
	@echo ""
	@echo "前置要求:"
	@echo "  - GitHub 用户名和 Personal Access Token (PAT)"
	@echo "  - 访问: https://github.com/settings/tokens"
	@echo "  - 勾选: write:packages, read:packages"
	@echo ""
	@echo "推送步骤:"
	@echo ""
	@echo "Step 1️⃣  登录到 GHCR"
	@echo "   docker login ghcr.io"
	@echo "   输入用户名: <your-github-username>"
	@echo "   输入密码: <your-personal-access-token>"
	@echo ""
	@echo "Step 2️⃣  标记镜像"
	@echo "   docker tag $(IMAGE_NAME_OPT) ghcr.io/<your-github-username>/centos7-gcc14:latest"
	@echo ""
	@echo "Step 3️⃣  推送镜像"
	@echo "   docker push ghcr.io/<your-github-username>/centos7-gcc14:latest"
	@echo ""
	@echo "完整命令 (一键执行):"
	@echo "   docker login ghcr.io && \\"
	@echo "   docker tag $(IMAGE_NAME_OPT) ghcr.io/<your-github-username>/centos7-gcc14:latest && \\"
	@echo "   docker push ghcr.io/<your-github-username>/centos7-gcc14:latest"
	@echo ""
	@echo "验证:"
	@echo "   访问 https://github.com/users/<your-github-username>/packages"
	@echo ""
	@echo "使用镜像:"
	@echo "   docker pull ghcr.io/<your-github-username>/centos7-gcc14:latest"
	@echo ""
	@echo "注意事项:"
	@echo "   - 镜像将以私有方式上传，可在设置中改为公开"
	@echo "   - 实际上传大小约 1.9GB (优化后)"
	@echo "   - 下载时会自动重建Docker layers"
	@echo ""
	@echo "=== 推送指南完成 ==="

clean:
	@echo "=== 清理中 ==="
	rm -rf $(BUILD_DIR)
	rm -f test_cpp20 test_cpp20_dynamic test_nss_static test_nss_dynamic test_full_static test_hybrid test_dynamic
	@echo "=== 清理完成 ==="

clean-all: clean
	@echo "=== 完全清理 ==="
	docker rmi $(IMAGE_NAME) 2>/dev/null || true
	docker rmi $(IMAGE_NAME_OPT) 2>/dev/null || true
	@echo "=== 完成 ==="

help:
	@echo "可用命令:"
	@echo "  make build     - 构建 Docker 镜像"
	@echo "  make test      - 测试混合链接"
	@echo "  make release   - 显示镜像信息"
	@echo "  make opt       - 优化镜像 (去除构建layers，只保留最终结果)"
	@echo "  make upload    - 推送优化镜像到 GitHub Container Registry"
	@echo "  make clean     - 清理测试文件"
	@echo "  make clean-all - 完全清理（包括镜像）"
