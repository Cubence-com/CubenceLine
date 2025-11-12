use chrono::{DateTime, Local, TimeZone, Utc};
use serde::{Deserialize, Serialize};
use std::time::Duration;

use super::credentials;

#[derive(Debug, Clone, Serialize, Deserialize, Default)]
pub struct BalanceInfo {
    #[serde(default)]
    pub amount_dollar: f64,
    #[serde(default)]
    pub amount_units: u64,
}

#[derive(Debug, Clone, Serialize, Deserialize, Default)]
pub struct WindowInfo {
    #[serde(default)]
    pub limit: u64,
    #[serde(default)]
    pub remaining: u64,
    #[serde(default)]
    pub reset_at: Option<i64>,
    #[serde(default)]
    pub used: u64,
}

#[derive(Debug, Clone, Serialize, Deserialize, Default)]
pub struct SubscriptionWindow {
    #[serde(default)]
    pub five_hour: WindowInfo,
    #[serde(default)]
    pub weekly: WindowInfo,
}

#[derive(Debug, Clone, Serialize, Deserialize, Default)]
pub struct SubscriptionInfo {
    #[serde(default)]
    pub normal_balance: BalanceInfo,
    #[serde(default)]
    pub subscription_window: SubscriptionWindow,
    #[serde(default)]
    pub timestamp: i64,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
struct SubscriptionInfoCache {
    info: SubscriptionInfo,
    cached_at: String,
}

pub struct SubscriptionApiClient;

impl SubscriptionApiClient {
    const DEFAULT_BASE_URL: &'static str = "https://cubence.com/api";
    const SUBSCRIPTION_PATH: &'static str = "/v1/user/subscription-info";
    const HEALTH_PATH: &'static str = "/health";
    const CACHE_FILE: &'static str = ".subscription_info_cache.json";

    fn get_proxy_from_settings() -> Option<String> {
        // First try to read from Claude settings file
        if let Ok(home) = std::env::var("HOME").or_else(|_| std::env::var("USERPROFILE")) {
            let settings_path = format!("{}/.claude/settings.json", home);
            if let Ok(content) = std::fs::read_to_string(&settings_path) {
                if let Ok(settings) = serde_json::from_str::<serde_json::Value>(&content) {
                    // Try HTTPS_PROXY first, then HTTP_PROXY from settings file
                    if let Some(proxy) = settings
                        .get("env")
                        .and_then(|env| env.get("HTTPS_PROXY"))
                        .or_else(|| settings.get("env").and_then(|env| env.get("HTTP_PROXY")))
                        .and_then(|v| v.as_str())
                        .map(|s| s.to_string())
                    {
                        return Some(proxy);
                    }
                }
            }
        }

        // Fallback to environment variables if not found in settings file
        std::env::var("HTTPS_PROXY")
            .or_else(|_| std::env::var("HTTP_PROXY"))
            .ok()
    }

    pub fn default_url() -> String {
        let base_url = credentials::get_anthropic_base_url()
            .unwrap_or_else(|| Self::DEFAULT_BASE_URL.to_string());
        Self::build_subscription_url(&base_url)
    }

    fn build_subscription_url(base_url: &str) -> String {
        format!(
            "{}{}",
            base_url.trim_end_matches('/'),
            Self::SUBSCRIPTION_PATH
        )
    }

    pub fn fetch(api_url: &str, timeout_secs: u64) -> Result<SubscriptionInfo, String> {
        let token = credentials::get_oauth_token()
            .ok_or_else(|| "Failed to get OAuth token".to_string())?;

        let mut agent_builder = ureq::AgentBuilder::new()
            .timeout(Duration::from_secs(timeout_secs))
            .timeout_read(Duration::from_secs(timeout_secs))
            .timeout_write(Duration::from_secs(timeout_secs));

        // Configure proxy from Claude settings if available
        if let Some(proxy_url) = Self::get_proxy_from_settings() {
            if let Ok(proxy) = ureq::Proxy::new(&proxy_url) {
                agent_builder = agent_builder.proxy(proxy);
            }
        }

        let agent = agent_builder.build();

        let response = agent
            .get(api_url)
            .set("Authorization", &format!("Bearer {}", token))
            .set("Content-Type", "application/json")
            .call()
            .map_err(|e| format!("API request failed: {}", e))?;

        if response.status() != 200 {
            return Err(format!("API returned status code: {}", response.status()));
        }

        response
            .into_json()
            .map_err(|e| format!("Failed to parse response: {}", e))
    }

    pub fn get_with_cache(
        api_url: &str,
        timeout_secs: u64,
        cache_duration_secs: u64,
    ) -> Result<SubscriptionInfo, String> {
        // Try memory/disk cache first
        if let Some(cache) = Self::load_cache() {
            if Self::is_cache_valid(&cache, cache_duration_secs) {
                return Ok(cache.info);
            }
        }

        let info = Self::fetch(api_url, timeout_secs)?;

        let cache = SubscriptionInfoCache {
            info: info.clone(),
            cached_at: Utc::now().to_rfc3339(),
        };
        Self::save_cache(&cache);

        Ok(info)
    }

    pub fn format_reset_time(reset_at: Option<i64>) -> Option<String> {
        let ts = reset_at?;
        let datetime = Local.timestamp_opt(ts, 0).single()?;
        Some(datetime.format("%m-%d %H:%M").to_string())
    }

    pub fn format_units_to_dollars(units: u64) -> f64 {
        (units as f64) / 1_000_000.0
    }

    fn get_cache_path() -> Option<std::path::PathBuf> {
        let home = dirs::home_dir()?;
        Some(home.join(".claude").join("ccline").join(Self::CACHE_FILE))
    }

    fn load_cache() -> Option<SubscriptionInfoCache> {
        let cache_path = Self::get_cache_path()?;
        if !cache_path.exists() {
            return None;
        }

        let content = std::fs::read_to_string(&cache_path).ok()?;
        serde_json::from_str(&content).ok()
    }

    fn save_cache(cache: &SubscriptionInfoCache) {
        if let Some(path) = Self::get_cache_path() {
            if let Some(parent) = path.parent() {
                let _ = std::fs::create_dir_all(parent);
            }

            if let Ok(content) = serde_json::to_string_pretty(cache) {
                let _ = std::fs::write(path, content);
            }
        }
    }

    fn is_cache_valid(cache: &SubscriptionInfoCache, cache_duration_secs: u64) -> bool {
        if cache_duration_secs == 0 {
            return false;
        }

        if let Ok(cached_at) = DateTime::parse_from_rfc3339(&cache.cached_at) {
            let now = Utc::now();
            let elapsed = now.signed_duration_since(cached_at.with_timezone(&Utc));
            elapsed.num_seconds() < cache_duration_secs as i64
        } else {
            false
        }
    }

    /// Check health endpoint and return latency in milliseconds
    pub fn check_health_latency(base_url: &str, timeout_secs: u64) -> Result<u64, String> {
        let health_url = format!("{}{}", base_url.trim_end_matches('/'), Self::HEALTH_PATH);

        let mut agent_builder = ureq::AgentBuilder::new()
            .timeout(Duration::from_secs(timeout_secs))
            .timeout_read(Duration::from_secs(timeout_secs))
            .timeout_write(Duration::from_secs(timeout_secs));

        // Configure proxy from Claude settings if available
        if let Some(proxy_url) = Self::get_proxy_from_settings() {
            if let Ok(proxy) = ureq::Proxy::new(&proxy_url) {
                agent_builder = agent_builder.proxy(proxy);
            }
        }

        let agent = agent_builder.build();

        // Measure request latency
        let start = std::time::Instant::now();
        let response = agent
            .get(&health_url)
            .call()
            .map_err(|e| format!("Health check failed: {}", e))?;
        let latency = start.elapsed();

        if response.status() != 200 {
            return Err(format!(
                "Health check returned status: {}",
                response.status()
            ));
        }

        Ok(latency.as_millis() as u64)
    }
}
