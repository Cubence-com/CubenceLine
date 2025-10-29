#!/bin/bash
# 版本号升级脚本
# 用法: ./bump-version.sh [patch|minor|major]

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

# 获取当前版本号
get_current_version() {
    grep '^version' Cargo.toml | head -1 | cut -d'"' -f2
}

# 升级版本号
bump_version() {
    local version=$1
    local bump_type=$2

    IFS='.' read -r major minor patch <<< "$version"

    case $bump_type in
        major)
            major=$((major + 1))
            minor=0
            patch=0
            ;;
        minor)
            minor=$((minor + 1))
            patch=0
            ;;
        patch)
            patch=$((patch + 1))
            ;;
        *)
            echo -e "${RED}错误: 无效的升级类型 '$bump_type'${NC}"
            echo "用法: $0 [patch|minor|major]"
            exit 1
            ;;
    esac

    echo "$major.$minor.$patch"
}

# 更新文件中的版本号
update_file_version() {
    local file=$1
    local old_version=$2
    local new_version=$3

    if [ -f "$file" ]; then
        if [[ "$OSTYPE" == "darwin"* ]]; then
            # macOS
            sed -i '' "s/\"version\": \"$old_version\"/\"version\": \"$new_version\"/g" "$file"
            sed -i '' "s/\"$old_version\"/\"$new_version\"/g" "$file"
        else
            # Linux
            sed -i "s/\"version\": \"$old_version\"/\"version\": \"$new_version\"/g" "$file"
            sed -i "s/\"$old_version\"/\"$new_version\"/g" "$file"
        fi
        echo -e "${GREEN}✓ 已更新: $file${NC}"
    else
        echo -e "${YELLOW}⚠ 文件不存在: $file${NC}"
    fi
}

# 更新 Cargo.toml
update_cargo_toml() {
    local old_version=$1
    local new_version=$2

    if [[ "$OSTYPE" == "darwin"* ]]; then
        sed -i '' "s/^version = \"$old_version\"/version = \"$new_version\"/" Cargo.toml
    else
        sed -i "s/^version = \"$old_version\"/version = \"$new_version\"/" Cargo.toml
    fi
    echo -e "${GREEN}✓ 已更新: Cargo.toml${NC}"
}

# 主函数
main() {
    local bump_type=$1

    if [ -z "$bump_type" ]; then
        echo -e "${RED}错误: 请指定升级类型${NC}"
        echo "用法: $0 [patch|minor|major]"
        exit 1
    fi

    # 获取当前版本
    local current_version=$(get_current_version)
    echo -e "${BLUE}当前版本: $current_version${NC}"

    # 计算新版本
    local new_version=$(bump_version "$current_version" "$bump_type")
    echo -e "${BLUE}新版本: $new_version${NC}"

    # 确认
    read -p "确认升级版本号? (y/N) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo -e "${YELLOW}已取消${NC}"
        exit 0
    fi

    # 更新所有文件
    echo -e "${BLUE}更新版本号...${NC}"

    # 更新 Cargo.toml
    update_cargo_toml "$current_version" "$new_version"

    # 更新主包
    update_file_version "npm/main/package.json" "$current_version" "$new_version"

    # 更新平台包
    for platform in darwin-arm64 darwin-x64 linux-x64 linux-x64-musl win32-x64; do
        update_file_version "npm/platforms/$platform/package.json" "$current_version" "$new_version"
    done

    echo -e "${GREEN}✓ 版本号已升级: $current_version → $new_version${NC}"
    echo -e "${YELLOW}提示: 记得提交更改并打 tag: git tag v$new_version${NC}"
}

# 执行主函数
main "$@"
