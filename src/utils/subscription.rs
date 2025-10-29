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
    const DEFAULT_URL: &'static str = "https://cubence.com/api/v1/user/subscription-info";
    const CACHE_FILE: &'static str = ".subscription_info_cache.json";

    pub fn default_url() -> &'static str {
        Self::DEFAULT_URL
    }

    pub fn fetch(api_url: &str, timeout_secs: u64) -> Option<SubscriptionInfo> {
        let token = credentials::get_oauth_token()?;

        let agent = ureq::AgentBuilder::new()
            .timeout(Duration::from_secs(timeout_secs))
            .timeout_read(Duration::from_secs(timeout_secs))
            .timeout_write(Duration::from_secs(timeout_secs))
            .build();

        let response = agent
            .get(api_url)
            .set("Authorization", &format!("Bearer {}", token))
            .set("Content-Type", "application/json")
            .call()
            .ok()?;

        if response.status() != 200 {
            return None;
        }

        response.into_json().ok()
    }

    pub fn get_with_cache(
        api_url: &str,
        timeout_secs: u64,
        cache_duration_secs: u64,
    ) -> Option<SubscriptionInfo> {
        // Try memory/disk cache first
        if let Some(cache) = Self::load_cache() {
            if Self::is_cache_valid(&cache, cache_duration_secs) {
                return Some(cache.info);
            }
        }

        let info = Self::fetch(api_url, timeout_secs)?;

        let cache = SubscriptionInfoCache {
            info: info.clone(),
            cached_at: Utc::now().to_rfc3339(),
        };
        Self::save_cache(&cache);

        Some(info)
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
}
