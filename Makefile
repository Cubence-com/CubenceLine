# CubenceLine Makefile
# 便于开发测试的构建工具

# 变量定义
BINARY_NAME := cubenceline
INSTALL_DIR := ~/.claude/ccline
INSTALL_NAME := cubenceline
TARGET_DIR := target
RELEASE_DIR := $(TARGET_DIR)/release
DEBUG_DIR := $(TARGET_DIR)/debug

# npm 相关变量
NPM_DIR := npm
NPM_MAIN := $(NPM_DIR)/main
NPM_PLATFORMS := $(NPM_DIR)/platforms

# 跨平台编译目标
TARGETS := \
	aarch64-apple-darwin \
	x86_64-apple-darwin \
	x86_64-unknown-linux-gnu \
	x86_64-unknown-linux-musl \
	x86_64-pc-windows-gnu

# 平台映射
PLATFORM_darwin-arm64 := aarch64-apple-darwin
PLATFORM_darwin-x64 := x86_64-apple-darwin
PLATFORM_linux-x64 := x86_64-unknown-linux-gnu
PLATFORM_linux-x64-musl := x86_64-unknown-linux-musl
PLATFORM_win32-x64 := x86_64-pc-windows-gnu

# 颜色输出
BLUE := \033[0;34m
GREEN := \033[0;32m
YELLOW := \033[0;33m
RED := \033[0;31m
NC := \033[0m # No Color

.PHONY: help
help: ## 显示帮助信息
	@echo "$(BLUE)CubenceLine 开发工具$(NC)"
	@echo ""
	@echo "$(GREEN)可用命令:$(NC)"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "  $(YELLOW)%-20s$(NC) %s\n", $$1, $$2}'

.PHONY: build
build: ## 构建开发版本
	@echo "$(BLUE)构建开发版本...$(NC)"
	cargo build
	@echo "$(GREEN)✓ 构建完成: $(DEBUG_DIR)/$(BINARY_NAME)$(NC)"

.PHONY: release
release: ## 构建发布版本
	@echo "$(BLUE)构建发布版本...$(NC)"
	cargo build --release
	@echo "$(GREEN)✓ 构建完成: $(RELEASE_DIR)/$(BINARY_NAME)$(NC)"

.PHONY: run
run: build ## 构建并运行开发版本
	@echo "$(BLUE)运行开发版本...$(NC)"
	./$(DEBUG_DIR)/$(BINARY_NAME)

.PHONY: run-release
run-release: release ## 构建并运行发布版本
	@echo "$(BLUE)运行发布版本...$(NC)"
	./$(RELEASE_DIR)/$(BINARY_NAME)

.PHONY: test
test: ## 运行测试
	@echo "$(BLUE)运行测试...$(NC)"
	cargo test

.PHONY: test-verbose
test-verbose: ## 运行测试(详细输出)
	@echo "$(BLUE)运行测试(详细输出)...$(NC)"
	cargo test -- --nocapture

.PHONY: check
check: ## 检查代码(不构建)
	@echo "$(BLUE)检查代码...$(NC)"
	cargo check

.PHONY: lint
lint: ## 运行 clippy 代码检查
	@echo "$(BLUE)运行 Clippy...$(NC)"
	cargo clippy -- -D warnings

.PHONY: fmt
fmt: ## 格式化代码
	@echo "$(BLUE)格式化代码...$(NC)"
	cargo fmt

.PHONY: fmt-check
fmt-check: ## 检查代码格式
	@echo "$(BLUE)检查代码格式...$(NC)"
	cargo fmt -- --check

.PHONY: clean
clean: ## 清理构建产物
	@echo "$(BLUE)清理构建产物...$(NC)"
	cargo clean
	@echo "$(GREEN)✓ 清理完成$(NC)"

.PHONY: install
install: release ## 安装到 ~/.claude/ccline/
	@echo "$(BLUE)安装到 $(INSTALL_DIR)...$(NC)"
	mkdir -p $(INSTALL_DIR)
	cp $(RELEASE_DIR)/$(BINARY_NAME) $(INSTALL_DIR)/$(INSTALL_NAME)
	chmod +x $(INSTALL_DIR)/$(INSTALL_NAME)
	@echo "$(GREEN)✓ 安装完成: $(INSTALL_DIR)/$(INSTALL_NAME)$(NC)"

.PHONY: install-dev
install-dev: build ## 安装开发版本到 ~/.claude/ccline/
	@echo "$(BLUE)安装开发版本到 $(INSTALL_DIR)...$(NC)"
	mkdir -p $(INSTALL_DIR)
	cp $(DEBUG_DIR)/$(BINARY_NAME) $(INSTALL_DIR)/$(INSTALL_NAME)
	chmod +x $(INSTALL_DIR)/$(INSTALL_NAME)
	@echo "$(GREEN)✓ 安装完成: $(INSTALL_DIR)/$(INSTALL_NAME)$(NC)"

.PHONY: uninstall
uninstall: ## 卸载已安装的版本
	@echo "$(BLUE)卸载 $(INSTALL_DIR)/$(INSTALL_NAME)...$(NC)"
	rm -f $(INSTALL_DIR)/$(INSTALL_NAME)
	@echo "$(GREEN)✓ 卸载完成$(NC)"

.PHONY: dev
dev: fmt lint test build ## 开发流程: 格式化+检查+测试+构建
	@echo "$(GREEN)✓ 开发检查全部通过$(NC)"

.PHONY: ci
ci: fmt-check lint test build ## CI 流程: 格式检查+代码检查+测试+构建
	@echo "$(GREEN)✓ CI 检查全部通过$(NC)"

.PHONY: watch
watch: ## 监听文件变化并自动构建
	@echo "$(BLUE)监听文件变化...$(NC)"
	@command -v cargo-watch >/dev/null 2>&1 || { echo "$(RED)需要安装 cargo-watch: cargo install cargo-watch$(NC)"; exit 1; }
	cargo watch -x build

.PHONY: watch-test
watch-test: ## 监听文件变化并自动测试
	@echo "$(BLUE)监听文件变化并测试...$(NC)"
	@command -v cargo-watch >/dev/null 2>&1 || { echo "$(RED)需要安装 cargo-watch: cargo install cargo-watch$(NC)"; exit 1; }
	cargo watch -x test

.PHONY: bench
bench: ## 运行性能测试
	@echo "$(BLUE)运行性能测试...$(NC)"
	cargo bench

.PHONY: doc
doc: ## 生成并打开文档
	@echo "$(BLUE)生成文档...$(NC)"
	cargo doc --open

.PHONY: tree
tree: ## 显示依赖树
	@echo "$(BLUE)显示依赖树...$(NC)"
	cargo tree

.PHONY: outdated
outdated: ## 检查过期的依赖
	@echo "$(BLUE)检查过期的依赖...$(NC)"
	@command -v cargo-outdated >/dev/null 2>&1 || { echo "$(RED)需要安装 cargo-outdated: cargo install cargo-outdated$(NC)"; exit 1; }
	cargo outdated

.PHONY: update
update: ## 更新依赖
	@echo "$(BLUE)更新依赖...$(NC)"
	cargo update

.PHONY: demo-init
demo-init: install ## 演示: 初始化配置
	@echo "$(BLUE)初始化配置...$(NC)"
	$(INSTALL_DIR)/$(INSTALL_NAME) --init

.PHONY: demo-config
demo-config: install ## 演示: 打开配置界面
	@echo "$(BLUE)打开配置界面...$(NC)"
	$(INSTALL_DIR)/$(INSTALL_NAME) --config

.PHONY: demo-check
demo-check: install ## 演示: 检查配置
	@echo "$(BLUE)检查配置...$(NC)"
	$(INSTALL_DIR)/$(INSTALL_NAME) --check

.PHONY: demo-print
demo-print: install ## 演示: 打印配置
	@echo "$(BLUE)打印当前配置...$(NC)"
	$(INSTALL_DIR)/$(INSTALL_NAME) --print

.PHONY: demo-themes
demo-themes: install ## 演示: 测试所有主题
	@echo "$(BLUE)测试主题...$(NC)"
	@echo "\n$(YELLOW)主题: cometix$(NC)"
	$(INSTALL_DIR)/$(INSTALL_NAME) --theme cometix
	@echo "\n$(YELLOW)主题: minimal$(NC)"
	$(INSTALL_DIR)/$(INSTALL_NAME) --theme minimal
	@echo "\n$(YELLOW)主题: gruvbox$(NC)"
	$(INSTALL_DIR)/$(INSTALL_NAME) --theme gruvbox
	@echo "\n$(YELLOW)主题: nord$(NC)"
	$(INSTALL_DIR)/$(INSTALL_NAME) --theme nord
	@echo "\n$(YELLOW)主题: powerline-dark$(NC)"
	$(INSTALL_DIR)/$(INSTALL_NAME) --theme powerline-dark

.PHONY: size
size: release ## 显示二进制文件大小
	@echo "$(BLUE)二进制文件大小:$(NC)"
	@ls -lh $(RELEASE_DIR)/$(BINARY_NAME) | awk '{printf "  %s\n", $$5}'
	@echo "$(BLUE)带调试信息:$(NC)"
	@du -h $(RELEASE_DIR)/$(BINARY_NAME) | awk '{printf "  %s\n", $$1}'
	@echo "$(BLUE)压缩后估计大小:$(NC)"
	@strip $(RELEASE_DIR)/$(BINARY_NAME) -o /tmp/$(BINARY_NAME)_stripped 2>/dev/null || cp $(RELEASE_DIR)/$(BINARY_NAME) /tmp/$(BINARY_NAME)_stripped
	@ls -lh /tmp/$(BINARY_NAME)_stripped | awk '{printf "  %s\n", $$5}'
	@rm -f /tmp/$(BINARY_NAME)_stripped

.PHONY: all
all: clean dev release install ## 完整流程: 清理+开发检查+构建发布版+安装
	@echo "$(GREEN)✓ 全部完成$(NC)"

# ============================================================================
# NPM 发布相关命令
# ============================================================================

.PHONY: npm-check
npm-check: ## 检查 npm 登录状态
	@echo "$(BLUE)检查 npm 登录状态...$(NC)"
	@npm whoami || { echo "$(RED)✗ 未登录 npm，请运行: npm login$(NC)"; exit 1; }
	@echo "$(GREEN)✓ npm 已登录$(NC)"

.PHONY: build-targets
build-targets: ## 安装所有交叉编译目标
	@echo "$(BLUE)安装交叉编译目标...$(NC)"
	@for target in $(TARGETS); do \
		rustup target add $$target; \
	done
	@echo "$(GREEN)✓ 交叉编译目标安装完成$(NC)"

.PHONY: build-darwin-arm64
build-darwin-arm64: ## 构建 macOS ARM64
	@echo "$(BLUE)构建 macOS ARM64...$(NC)"
	cargo build --release --target aarch64-apple-darwin
	@echo "$(GREEN)✓ macOS ARM64 构建完成$(NC)"

.PHONY: build-darwin-x64
build-darwin-x64: ## 构建 macOS x64
	@echo "$(BLUE)构建 macOS x64...$(NC)"
	cargo build --release --target x86_64-apple-darwin
	@echo "$(GREEN)✓ macOS x64 构建完成$(NC)"

.PHONY: build-linux-x64
build-linux-x64: ## 构建 Linux x64
	@echo "$(BLUE)构建 Linux x64...$(NC)"
	cargo build --release --target x86_64-unknown-linux-gnu
	@echo "$(GREEN)✓ Linux x64 构建完成$(NC)"

.PHONY: build-linux-x64-musl
build-linux-x64-musl: ## 构建 Linux x64 (musl)
	@echo "$(BLUE)构建 Linux x64 (musl)...$(NC)"
	cargo build --release --target x86_64-unknown-linux-musl
	@echo "$(GREEN)✓ Linux x64 (musl) 构建完成$(NC)"

.PHONY: build-win32-x64
build-win32-x64: ## 构建 Windows x64
	@echo "$(BLUE)构建 Windows x64...$(NC)"
	cargo build --release --target x86_64-pc-windows-gnu
	@echo "$(GREEN)✓ Windows x64 构建完成$(NC)"

.PHONY: build-all-platforms
build-all-platforms: ## 构建所有平台（需要交叉编译工具链）
	@echo "$(BLUE)构建所有平台...$(NC)"
	@echo "$(YELLOW)注意: 这需要安装交叉编译工具链$(NC)"
	@$(MAKE) build-darwin-arm64 || echo "$(YELLOW)⚠ macOS ARM64 构建失败，跳过$(NC)"
	@$(MAKE) build-darwin-x64 || echo "$(YELLOW)⚠ macOS x64 构建失败，跳过$(NC)"
	@$(MAKE) build-linux-x64 || echo "$(YELLOW)⚠ Linux x64 构建失败，跳过$(NC)"
	@$(MAKE) build-linux-x64-musl || echo "$(YELLOW)⚠ Linux x64 musl 构建失败，跳过$(NC)"
	@$(MAKE) build-win32-x64 || echo "$(YELLOW)⚠ Windows x64 构建失败，跳过$(NC)"
	@echo "$(GREEN)✓ 所有平台构建完成$(NC)"

.PHONY: copy-binaries
copy-binaries: ## 复制二进制文件到 npm 平台包目录
	@echo "$(BLUE)复制二进制文件到 npm 平台包...$(NC)"
	@# macOS ARM64
	@if [ -f "$(TARGET_DIR)/aarch64-apple-darwin/release/$(BINARY_NAME)" ]; then \
		cp "$(TARGET_DIR)/aarch64-apple-darwin/release/$(BINARY_NAME)" "$(NPM_PLATFORMS)/darwin-arm64/"; \
		echo "$(GREEN)✓ 已复制: darwin-arm64$(NC)"; \
	else \
		echo "$(YELLOW)⚠ 未找到: darwin-arm64$(NC)"; \
	fi
	@# macOS x64
	@if [ -f "$(TARGET_DIR)/x86_64-apple-darwin/release/$(BINARY_NAME)" ]; then \
		cp "$(TARGET_DIR)/x86_64-apple-darwin/release/$(BINARY_NAME)" "$(NPM_PLATFORMS)/darwin-x64/"; \
		echo "$(GREEN)✓ 已复制: darwin-x64$(NC)"; \
	else \
		echo "$(YELLOW)⚠ 未找到: darwin-x64$(NC)"; \
	fi
	@# Linux x64
	@if [ -f "$(TARGET_DIR)/x86_64-unknown-linux-gnu/release/$(BINARY_NAME)" ]; then \
		cp "$(TARGET_DIR)/x86_64-unknown-linux-gnu/release/$(BINARY_NAME)" "$(NPM_PLATFORMS)/linux-x64/"; \
		echo "$(GREEN)✓ 已复制: linux-x64$(NC)"; \
	else \
		echo "$(YELLOW)⚠ 未找到: linux-x64$(NC)"; \
	fi
	@# Linux x64 musl
	@if [ -f "$(TARGET_DIR)/x86_64-unknown-linux-musl/release/$(BINARY_NAME)" ]; then \
		cp "$(TARGET_DIR)/x86_64-unknown-linux-musl/release/$(BINARY_NAME)" "$(NPM_PLATFORMS)/linux-x64-musl/"; \
		echo "$(GREEN)✓ 已复制: linux-x64-musl$(NC)"; \
	else \
		echo "$(YELLOW)⚠ 未找到: linux-x64-musl$(NC)"; \
	fi
	@# Windows x64
	@if [ -f "$(TARGET_DIR)/x86_64-pc-windows-gnu/release/$(BINARY_NAME).exe" ]; then \
		cp "$(TARGET_DIR)/x86_64-pc-windows-gnu/release/$(BINARY_NAME).exe" "$(NPM_PLATFORMS)/win32-x64/"; \
		echo "$(GREEN)✓ 已复制: win32-x64$(NC)"; \
	else \
		echo "$(YELLOW)⚠ 未找到: win32-x64$(NC)"; \
	fi
	@echo "$(GREEN)✓ 二进制文件复制完成$(NC)"

.PHONY: npm-version
npm-version: ## 显示当前版本号
	@echo "$(BLUE)当前版本号:$(NC)"
	@cat Cargo.toml | grep "^version" | head -1 | cut -d'"' -f2

.PHONY: npm-bump-patch
npm-bump-patch: ## 升级补丁版本号 (1.0.0 -> 1.0.1)
	@echo "$(BLUE)升级补丁版本号...$(NC)"
	@./scripts/bump-version.sh patch

.PHONY: npm-bump-minor
npm-bump-minor: ## 升级次要版本号 (1.0.0 -> 1.1.0)
	@echo "$(BLUE)升级次要版本号...$(NC)"
	@./scripts/bump-version.sh minor

.PHONY: npm-bump-major
npm-bump-major: ## 升级主要版本号 (1.0.0 -> 2.0.0)
	@echo "$(BLUE)升级主要版本号...$(NC)"
	@./scripts/bump-version.sh major

.PHONY: npm-publish-platforms
npm-publish-platforms: npm-check ## 发布所有平台包到 npm
	@echo "$(BLUE)发布平台包到 npm...$(NC)"
	@cd "$(NPM_PLATFORMS)/darwin-arm64" && npm publish --access public && echo "$(GREEN)✓ darwin-arm64 已发布$(NC)"
	@cd "$(NPM_PLATFORMS)/darwin-x64" && npm publish --access public && echo "$(GREEN)✓ darwin-x64 已发布$(NC)"
	@cd "$(NPM_PLATFORMS)/linux-x64" && npm publish --access public && echo "$(GREEN)✓ linux-x64 已发布$(NC)"
	@cd "$(NPM_PLATFORMS)/linux-x64-musl" && npm publish --access public && echo "$(GREEN)✓ linux-x64-musl 已发布$(NC)"
	@cd "$(NPM_PLATFORMS)/win32-x64" && npm publish --access public && echo "$(GREEN)✓ win32-x64 已发布$(NC)"
	@echo "$(GREEN)✓ 所有平台包已发布$(NC)"

.PHONY: npm-publish-main
npm-publish-main: npm-check ## 发布主包到 npm
	@echo "$(BLUE)发布主包到 npm...$(NC)"
	@cd "$(NPM_MAIN)" && npm publish --access public
	@echo "$(GREEN)✓ 主包已发布$(NC)"

.PHONY: npm-publish-all
npm-publish-all: npm-publish-platforms npm-publish-main ## 发布所有包到 npm
	@echo "$(GREEN)✓ 所有包已发布到 npm$(NC)"

.PHONY: npm-prepare
npm-prepare: fmt lint test build-all-platforms copy-binaries ## 准备 npm 发布（格式化+检查+测试+构建+复制）
	@echo "$(GREEN)✓ npm 发布准备完成$(NC)"
	@echo "$(YELLOW)提示: 运行 'make npm-publish-all' 发布到 npm$(NC)"

.PHONY: npm-release
npm-release: npm-prepare npm-publish-all ## 完整的 npm 发布流程（准备+发布）
	@echo "$(GREEN)✓ npm 发布完成！$(NC)"
	@$(MAKE) npm-version

.PHONY: npm-dry-run
npm-dry-run: ## 模拟 npm 发布（不实际发布）
	@echo "$(BLUE)模拟 npm 发布...$(NC)"
	@cd "$(NPM_PLATFORMS)/darwin-arm64" && npm publish --dry-run --access public
	@cd "$(NPM_PLATFORMS)/darwin-x64" && npm publish --dry-run --access public
	@cd "$(NPM_PLATFORMS)/linux-x64" && npm publish --dry-run --access public
	@cd "$(NPM_PLATFORMS)/linux-x64-musl" && npm publish --dry-run --access public
	@cd "$(NPM_PLATFORMS)/win32-x64" && npm publish --dry-run --access public
	@cd "$(NPM_MAIN)" && npm publish --dry-run --access public
	@echo "$(GREEN)✓ 模拟发布完成$(NC)"

.DEFAULT_GOAL := help
