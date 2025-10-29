# 发布指南

本文档介绍如何发布 CubenceLine 到 npm。

## 前置要求

1. **npm 账号和组织**
   ```bash
   # 登录 npm
   npm login

   # 创建 @cubence 组织（首次发布时）
   npm org create cubence

   # 验证登录状态
   npm whoami
   ```

2. **GitHub 配置**
   - 在 GitHub 仓库设置中添加 `NPM_TOKEN` secret
   - 获取 npm token: https://www.npmjs.com/settings/your-username/tokens
   - 创建 Automation token 并添加到 GitHub Secrets

## 发布方式

### 方式一：使用 GitHub Actions（推荐）

这是最简单和推荐的方式，会自动构建所有平台并发布。

1. **更新版本号**
   ```bash
   # 升级补丁版本 (1.0.0 -> 1.0.1)
   make npm-bump-patch

   # 或升级次要版本 (1.0.0 -> 1.1.0)
   make npm-bump-minor

   # 或升级主要版本 (1.0.0 -> 2.0.0)
   make npm-bump-major
   ```

2. **提交更改并打标签**
   ```bash
   # 提交版本更新
   git add .
   git commit -m "chore: bump version to 1.0.1"

   # 创建 git tag
   git tag v1.0.1

   # 推送到 GitHub（会自动触发 GitHub Actions）
   git push origin master --tags
   ```

3. **等待自动发布**
   - GitHub Actions 会自动构建所有平台
   - 自动发布到 npm
   - 自动创建 GitHub Release

### 方式二：手动发布（当前平台）

如果你只想在本地构建当前平台并发布：

1. **检查 npm 登录状态**
   ```bash
   make npm-check
   ```

2. **构建当前平台**
   ```bash
   # macOS ARM64
   make build-darwin-arm64

   # 或其他平台...
   ```

3. **复制二进制文件**
   ```bash
   make copy-binaries
   ```

4. **发布到 npm**
   ```bash
   # 先发布平台包
   make npm-publish-platforms

   # 然后发布主包
   make npm-publish-main
   ```

### 方式三：完整手动发布（所有平台）

⚠️ **注意**：这需要配置跨平台编译工具链，不推荐。建议使用 GitHub Actions。

1. **安装交叉编译工具**
   ```bash
   make build-targets
   ```

2. **完整发布流程**
   ```bash
   make npm-release
   ```

## Makefile 命令参考

### 版本管理
- `make npm-version` - 显示当前版本号
- `make npm-bump-patch` - 升级补丁版本 (1.0.0 -> 1.0.1)
- `make npm-bump-minor` - 升级次要版本 (1.0.0 -> 1.1.0)
- `make npm-bump-major` - 升级主要版本 (1.0.0 -> 2.0.0)

### 构建
- `make build-darwin-arm64` - 构建 macOS ARM64
- `make build-darwin-x64` - 构建 macOS x64
- `make build-linux-x64` - 构建 Linux x64
- `make build-linux-x64-musl` - 构建 Linux x64 (静态)
- `make build-win32-x64` - 构建 Windows x64
- `make build-all-platforms` - 构建所有平台
- `make copy-binaries` - 复制二进制文件到 npm 包目录

### npm 发布
- `make npm-check` - 检查 npm 登录状态
- `make npm-publish-platforms` - 发布所有平台包
- `make npm-publish-main` - 发布主包
- `make npm-publish-all` - 发布所有包
- `make npm-prepare` - 准备发布（构建+复制）
- `make npm-release` - 完整发布流程
- `make npm-dry-run` - 模拟发布（不实际发布）

### 开发
- `make build` - 构建开发版本
- `make release` - 构建发布版本
- `make test` - 运行测试
- `make lint` - 代码检查
- `make fmt` - 格式化代码

## 发布检查清单

发布前确保：

- [ ] 代码已提交到 git
- [ ] 所有测试通过 (`make test`)
- [ ] 代码格式正确 (`make fmt-check`)
- [ ] Clippy 检查通过 (`make lint`)
- [ ] 版本号已更新（Cargo.toml 和所有 package.json）
- [ ] README 文档已更新
- [ ] CHANGELOG 已更新（如果有）
- [ ] npm 已登录 (`npm whoami`)
- [ ] GitHub NPM_TOKEN secret 已配置（使用 GitHub Actions 时）

## 发布后验证

1. **检查 npm 包**
   ```bash
   # 查看包信息
   npm view @cubence/cubenceline

   # 查看平台包
   npm view @cubence/cubenceline-darwin-arm64
   ```

2. **测试安装**
   ```bash
   # 在新环境中测试
   npm install -g @cubence/cubenceline
   cubenceline --version
   ```

3. **检查 GitHub Release**
   - 访问 https://github.com/Cubence-com/CubenceLine/releases
   - 确认新版本已发布

## 故障排除

### npm 发布失败

1. **权限错误**
   ```bash
   # 确保已登录
   npm whoami

   # 确保在 @cubence 组织中
   npm org ls cubence
   ```

2. **版本冲突**
   ```bash
   # 检查已发布的版本
   npm view @cubence/cubenceline versions

   # 确保新版本号更高
   make npm-version
   ```

3. **平台包缺失**
   ```bash
   # 确保所有平台包都已构建
   ls -la npm/platforms/*/cubenceline*

   # 重新复制二进制文件
   make copy-binaries
   ```

### GitHub Actions 失败

1. **检查 NPM_TOKEN**
   - 确保 token 有效且未过期
   - 在 GitHub 仓库设置中更新 secret

2. **交叉编译失败**
   - 查看 GitHub Actions 日志
   - 某些平台可能需要额外的编译工具

## 回滚版本

如果发布有问题，可以弃用有问题的版本：

```bash
# 弃用特定版本（不推荐安装，但仍可下载）
npm deprecate @cubence/cubenceline@1.0.1 "版本有问题，请使用 1.0.2"

# 发布新的修复版本
make npm-bump-patch
# ... 然后重新发布
```

⚠️ **注意**：npm 不允许删除已发布的包（24小时后），只能弃用。

## 相关链接

- npm 包: https://www.npmjs.com/package/@cubence/cubenceline
- GitHub 仓库: https://github.com/Cubence-com/CubenceLine
- 发布版本: https://github.com/Cubence-com/CubenceLine/releases
