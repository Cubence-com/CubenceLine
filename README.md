# CubenceLine

[English](README.md) | [中文](README.zh.md)

A high-performance Claude Code statusline tool written in Rust with Git integration, usage tracking, interactive TUI configuration, and Claude Code enhancement utilities.

![Language:Rust](https://img.shields.io/static/v1?label=Language&message=Rust&color=orange&style=flat-square)
![License:MIT](https://img.shields.io/static/v1?label=License&message=MIT&color=blue&style=flat-square)

## Screenshots

![CubenceLine](assets/img1.png)

The statusline shows: Model | Directory | Git Branch Status | Context Window Information

## Features

### Core Functionality
- **Git integration** with branch, status, and tracking info  
- **Model display** with simplified Claude model names
- **Usage tracking** based on transcript analysis
- **Directory display** showing current workspace
- **Minimal design** using Nerd Font icons

### Interactive TUI Features
- **Interactive main menu** when executed without input
- **TUI configuration interface** with real-time preview
- **Theme system** with multiple built-in presets
- **Segment customization** with granular control
- **Configuration management** (init, check, edit)

### Claude Code Enhancement
- **Context warning disabler** - Remove annoying "Context low" messages
- **Verbose mode enabler** - Enhanced output detail
- **Robust patcher** - Survives Claude Code version updates
- **Automatic backups** - Safe modification with easy recovery

## Installation

### Quick Install (Recommended)

Install via npm (works on all platforms):

```bash
# Install globally
npm install -g @cubence/cubenceline

# Or using yarn
yarn global add @cubence/cubenceline

# Or using pnpm
pnpm add -g @cubence/cubenceline
```

Use npm mirror for faster download:
```bash
npm install -g @cubence/cubenceline --registry https://registry.npmmirror.com
```

After installation:
- ✅ Global command `cubenceline` is available everywhere
- ⚙️ Follow the configuration steps below to integrate with Claude Code
- 🎨 Run `cubenceline -c` to open configuration panel for theme selection

### Claude Code Configuration

Add to your Claude Code `settings.json`:

**Linux/macOS:**
```json
{
  "statusLine": {
    "type": "command", 
    "command": "~/.claude/ccline/cubenceline",
    "padding": 0
  }
}
```

**Windows:**
```json
{
  "statusLine": {
    "type": "command", 
    "command": "%USERPROFILE%\\.claude\\ccline\\cubenceline.exe",
    "padding": 0
  }
}
```

**Fallback (npm installation):**
```json
{
  "statusLine": {
    "type": "command", 
    "command": "cubenceline",
    "padding": 0
  }
}
```
*Use this if npm global installation is available in PATH*

### Update

```bash
npm update -g @cubence/cubenceline
```

<details>
<summary>Manual Installation (Click to expand)</summary>

Alternatively, download from [Releases](https://github.com/Cubence-com/CubenceLine/releases):

#### Linux

#### Option 1: Dynamic Binary (Recommended)
```bash
mkdir -p ~/.claude/ccline
wget https://github.com/Cubence-com/CubenceLine/releases/latest/download/cubenceline-linux-x64.tar.gz
tar -xzf cubenceline-linux-x64.tar.gz
cp cubenceline ~/.claude/ccline/
chmod +x ~/.claude/ccline/cubenceline
```
*Requires: Ubuntu 22.04+, CentOS 9+, Debian 11+, RHEL 9+ (glibc 2.35+)*

#### Option 2: Static Binary (Universal Compatibility)
```bash
mkdir -p ~/.claude/ccline
wget https://github.com/Cubence-com/CubenceLine/releases/latest/download/cubenceline-linux-x64-static.tar.gz
tar -xzf cubenceline-linux-x64-static.tar.gz
cp cubenceline ~/.claude/ccline/
chmod +x ~/.claude/ccline/cubenceline
```
*Works on any Linux distribution (static, no dependencies)*

#### macOS (Intel)

```bash  
mkdir -p ~/.claude/ccline
wget https://github.com/Cubence-com/CubenceLine/releases/latest/download/cubenceline-macos-x64.tar.gz
tar -xzf cubenceline-macos-x64.tar.gz
cp cubenceline ~/.claude/ccline/
chmod +x ~/.claude/ccline/cubenceline
```

#### macOS (Apple Silicon)

```bash
mkdir -p ~/.claude/ccline  
wget https://github.com/Cubence-com/CubenceLine/releases/latest/download/cubenceline-macos-arm64.tar.gz
tar -xzf cubenceline-macos-arm64.tar.gz
cp cubenceline ~/.claude/ccline/
chmod +x ~/.claude/ccline/cubenceline
```

#### Windows

```powershell
# Create directory and download
New-Item -ItemType Directory -Force -Path "$env:USERPROFILE\.claude\ccline"
Invoke-WebRequest -Uri "https://github.com/Cubence-com/CubenceLine/releases/latest/download/cubenceline-windows-x64.zip" -OutFile "cubenceline-windows-x64.zip"
Expand-Archive -Path "cubenceline-windows-x64.zip" -DestinationPath "."
Move-Item "cubenceline.exe" "$env:USERPROFILE\.claude\ccline\"
```

</details>

### Build from Source

```bash
git clone https://github.com/Cubence-com/CubenceLine.git
cd CubenceLine
cargo build --release

# Linux/macOS
mkdir -p ~/.claude/ccline
cp target/release/cubenceline ~/.claude/ccline/cubenceline
chmod +x ~/.claude/ccline/cubenceline

# Windows (PowerShell)
New-Item -ItemType Directory -Force -Path "$env:USERPROFILE\.claude\ccline"
copy target\release\cubenceline.exe "$env:USERPROFILE\.claude\ccline\cubenceline.exe"
```

## Usage

### Configuration Management

```bash
# Initialize configuration file
cubenceline --init

# Check configuration validity  
cubenceline --check

# Print current configuration
cubenceline --print

# Enter TUI configuration mode
cubenceline --config
```

### Theme Override

```bash
# Temporarily use specific theme (overrides config file)
cubenceline --theme cometix
cubenceline --theme minimal
cubenceline --theme gruvbox
cubenceline --theme nord
cubenceline --theme powerline-dark

# Or use custom theme files from ~/.claude/ccline/themes/
cubenceline --theme my-custom-theme
```

### Claude Code Enhancement

```bash
# Disable context warnings and enable verbose mode
cubenceline --patch /path/to/claude-code/cli.js

# Example for common installation
cubenceline --patch ~/.local/share/fnm/node-versions/v24.4.1/installation/lib/node_modules/@anthropic-ai/claude-code/cli.js
```

## Default Segments

Displays: `Directory | Git Branch Status | Model | Context Window`

### Git Status Indicators

- Branch name with Nerd Font icon
- Status: `✓` Clean, `●` Dirty, `⚠` Conflicts  
- Remote tracking: `↑n` Ahead, `↓n` Behind

### Model Display

Shows simplified Claude model names:
- `claude-3-5-sonnet` → `Sonnet 3.5`
- `claude-4-sonnet` → `Sonnet 4`

### Context Window Display

Token usage percentage based on transcript analysis with context limit tracking.

## Configuration

CubenceLine supports full configuration via TOML files and interactive TUI:

- **Configuration file**: `~/.claude/ccline/config.toml`
- **Interactive TUI**: `cubenceline --config` for real-time editing with preview
- **Theme files**: `~/.claude/ccline/themes/*.toml` for custom themes
- **Automatic initialization**: `cubenceline --init` creates default configuration

### Available Segments

All segments are configurable with:
- Enable/disable toggle
- Custom separators and icons
- Color customization
- Format options

Supported segments: Directory, Git, Model, ContextWindow, Usage, Subscription, Balance, Cost, Session, OutputStyle, Update

#### Subscription & Balance segments

- `subscription` shows remaining vs. limit for the 5-hour and weekly windows returned by `{ANTHROPIC_BASE_URL}/v1/user/subscription-info` (the `ANTHROPIC_BASE_URL` value is read from `~/.claude/settings.json` → `env.ANTHROPIC_BASE_URL`, just like `ANTHROPIC_AUTH_TOKEN`).
- `balance` surfaces the normal balance (`amount_dollar` / `amount_units`) from the same response.
- Both segments reuse the Claude Code OAuth token that `cubenceline` already reads via Keychain/`~/.claude/.credentials.json`.
- Configure `api_url`, `cache_duration` (seconds), and `timeout` (seconds) in the segment options if you need to point at a different endpoint or adjust refresh behaviour.
- API values are expressed in "units" where `1_000_000 = $1`; both segments convert to dollars for the primary display.


## Requirements

- **Git**: Version 1.5+ (Git 2.22+ recommended for better branch detection)
- **Terminal**: Must support Nerd Fonts for proper icon display
  - Install a [Nerd Font](https://www.nerdfonts.com/) (e.g., FiraCode Nerd Font, JetBrains Mono Nerd Font)
  - Configure your terminal to use the Nerd Font
- **Claude Code**: For statusline integration

## Development

```bash
# Build development version
cargo build

# Run tests
cargo test

# Build optimized release
cargo build --release
```

## Roadmap

- [x] TOML configuration file support
- [x] TUI configuration interface
- [x] Custom themes
- [x] Interactive main menu
- [x] Claude Code enhancement tools

## Contributing

Contributions are welcome! Please feel free to submit issues or pull requests.

## Related Projects

- [tweakcc](https://github.com/Piebald-AI/tweakcc) - Command-line tool to customize your Claude Code themes, thinking verbs, and more.

## License

This project is licensed under the [MIT License](LICENSE).

## Star History

[![Star History Chart](https://api.star-history.com/svg?repos=Cubence-com/CubenceLine&type=Date)](https://star-history.com/#Cubence-com/CubenceLine&Date)
