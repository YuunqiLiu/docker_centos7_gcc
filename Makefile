.PHONY: build test clean clean-all release opt upload help

IMAGE_NAME := centos7-gcc14:latest
IMAGE_NAME_OPT := centos7-gcc14:slim
DOCKERFILE := Dockerfile.gcc13-prebuilt
BUILD_DIR := build
TEST_DIR := $(BUILD_DIR)/test
RELEASE_DIR := $(BUILD_DIR)/release

# GHCR 推送配置（需要用户设置）
GHCR_USERNAME ?= yuunqiliu
GHCR_REGISTRY := ghcr.io
GHCR_IMAGE := $(GHCR_REGISTRY)/$(GHCR_USERNAME)/centos7-gcc14:latest

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
	@echo "=== 优化镜像 (扁平化为单层，保留ENV) ==="
	@echo ""
	@echo "原镜像大小: $$(docker images $(IMAGE_NAME) --format='{{.Size}}')"
	@echo ""
	@echo "1. 创建临时容器并导出文件系统..."
	docker create --name gcc-temp-container $(IMAGE_NAME)
	docker export gcc-temp-container > /tmp/gcc-rootfs.tar
	docker rm gcc-temp-container
	@echo "   ✓ 文件系统已导出到 /tmp/gcc-rootfs.tar"
	@echo ""
	@echo "2. 生成优化 Dockerfile..."
	@echo "FROM scratch" > /tmp/Dockerfile.opt
	@echo "ADD gcc-rootfs.tar /" >> /tmp/Dockerfile.opt
	@echo "ENV PATH=/opt/gcc-14/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin" >> /tmp/Dockerfile.opt
	@echo "ENV LD_LIBRARY_PATH=/opt/gcc-14/lib64" >> /tmp/Dockerfile.opt
	@echo "WORKDIR /workspace" >> /tmp/Dockerfile.opt
	@echo "CMD [\"/bin/bash\"]" >> /tmp/Dockerfile.opt
	@echo "   ✓ Dockerfile 已生成"
	@echo ""
	@echo "3. 构建优化镜像..."
	docker build -t $(IMAGE_NAME_OPT) -f /tmp/Dockerfile.opt /tmp/
	@echo "   ✓ 优化镜像已构建"
	@echo ""
	@echo "4. 清理临时文件..."
	rm -f /tmp/gcc-rootfs.tar /tmp/Dockerfile.opt
	@echo "   ✓ 临时文件已清理"
	@echo ""
	@echo "5. 验证 GCC 版本..."
	@docker run --rm $(IMAGE_NAME_OPT) gcc --version | head -1 | grep "14\." || (echo "❌ GCC 版本不是 14!" && exit 1)
	@docker run --rm $(IMAGE_NAME_OPT) gcc --version | head -1
	@echo "   ✓ GCC 14 验证成功"
	@echo ""
	@echo "6. 镜像大小对比:"
	@echo "   原镜像: $$(docker images $(IMAGE_NAME) --format='{{.Size}}')"
	@echo "   优化后: $$(docker images $(IMAGE_NAME_OPT) --format='{{.Size}}')"
	@echo ""
	@echo "7. 删除原镜像 (只保留优化版本)..."
	docker rmi $(IMAGE_NAME)
	@echo "   ✓ 原镜像已删除"
	@echo ""
	@echo "=== 优化完成 ==="
	@echo ""
	@echo "下一步: make upload"

upload:
	@echo "=== 推送镜像到 GitHub Container Registry ==="
	@echo ""
	@echo "检查镜像..."
	@docker images $(IMAGE_NAME_OPT) --format="✅ 镜像大小: {{.Size}}" || (echo "❌ 镜像不存在，请先运行: make opt" && exit 1)
	@echo ""
	@echo "GHCR 推送配置:"
	@echo "  GHCR_USERNAME: $(GHCR_USERNAME)"
	@echo "  目标镜像: $(GHCR_IMAGE)"
	@echo ""
	@echo "开始推送流程..."
	@echo ""
	@echo "Step 1️⃣  登录 GHCR (需要 GitHub Token)"
	docker login $(GHCR_REGISTRY) -u $(GHCR_USERNAME)
	@echo ""
	@echo "Step 2️⃣  标记镜像"
	docker tag $(IMAGE_NAME_OPT) $(GHCR_IMAGE)
	@echo "✅ 镜像已标记: $(GHCR_IMAGE)"
	@echo ""
	@echo "Step 3️⃣  推送镜像到 GHCR (这会花费几分钟)..."
	docker push $(GHCR_IMAGE)
	@echo ""
	@echo "✅ 推送完成！"
	@echo ""
	@echo "查看镜像:"
	@echo "  https://github.com/users/$(GHCR_USERNAME)/packages"
	@echo ""
	@echo "拉取镜像:"
	@echo "  docker pull $(GHCR_IMAGE)"

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
