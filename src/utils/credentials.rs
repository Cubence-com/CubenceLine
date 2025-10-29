use serde::{Deserialize, Serialize};
use std::path::PathBuf;

#[derive(Debug, Deserialize, Serialize)]
struct ClaudeSettings {
    env: Option<ClaudeEnv>,
}

#[derive(Debug, Deserialize, Serialize)]
struct ClaudeEnv {
    #[serde(rename = "ANTHROPIC_AUTH_TOKEN")]
    anthropic_auth_token: Option<String>,
    #[serde(rename = "ANTHROPIC_BASE_URL")]
    anthropic_base_url: Option<String>,
}

/// Get OAuth token from ~/.claude/settings.json
pub fn get_oauth_token() -> Option<String> {
    let settings_path = get_settings_path()?;

    if !settings_path.exists() {
        return None;
    }

    let content = std::fs::read_to_string(&settings_path).ok()?;
    let settings: ClaudeSettings = serde_json::from_str(&content).ok()?;

    settings.env.and_then(|env| env.anthropic_auth_token)
}

/// Get Anthropic base URL from ~/.claude/settings.json
pub fn get_anthropic_base_url() -> Option<String> {
    let settings_path = get_settings_path()?;

    if !settings_path.exists() {
        return None;
    }

    let content = std::fs::read_to_string(&settings_path).ok()?;
    let settings: ClaudeSettings = serde_json::from_str(&content).ok()?;

    settings.env.and_then(|env| env.anthropic_base_url)
}

fn get_settings_path() -> Option<PathBuf> {
    let home = dirs::home_dir()?;
    Some(home.join(".claude").join("settings.json"))
}
