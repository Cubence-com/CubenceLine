# CubenceLine Makefile
# 便于开发测试的构建工具

# 变量定义
BINARY_NAME := cubenceline
INSTALL_DIR := ~/.claude/ccline
INSTALL_NAME := ccline
TARGET_DIR := target
RELEASE_DIR := $(TARGET_DIR)/release
DEBUG_DIR := $(TARGET_DIR)/debug

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

.DEFAULT_GOAL := help
