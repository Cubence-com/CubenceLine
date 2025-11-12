use super::{Segment, SegmentData};
use crate::config::{InputData, SegmentId};
use crate::utils::{
    credentials,
    subscription::{SubscriptionApiClient, WindowInfo},
};
use std::collections::HashMap;

#[derive(Default)]
pub struct CubenceSegment;

impl CubenceSegment {
    pub fn new() -> Self {
        Self
    }

    fn get_options() -> (String, u64, u64) {
        let config = crate::config::Config::load().ok();
        let segment_config = config
            .as_ref()
            .and_then(|cfg| cfg.segments.iter().find(|s| s.id == SegmentId::Cubence));

        // Always use the URL from settings.json (ANTHROPIC_BASE_URL)
        let api_url = SubscriptionApiClient::default_url();

        let cache_duration = segment_config
            .and_then(|sc| sc.options.get("cache_duration"))
            .and_then(|v| v.as_u64())
            .unwrap_or(180);

        let timeout = segment_config
            .and_then(|sc| sc.options.get("timeout"))
            .and_then(|v| v.as_u64())
            .unwrap_or(2);

        (api_url, cache_duration, timeout)
    }

    fn format_window_for_metadata(window: &WindowInfo) -> HashMap<String, String> {
        let remaining_dollars = SubscriptionApiClient::format_units_to_dollars(window.remaining);
        let limit_dollars = SubscriptionApiClient::format_units_to_dollars(window.limit);
        let used_dollars = SubscriptionApiClient::format_units_to_dollars(window.used);

        let percent_used = if window.limit > 0 {
            (window.used as f64 / window.limit as f64) * 100.0
        } else {
            0.0
        };

        let reset_str = window
            .reset_at
            .and_then(|ts| SubscriptionApiClient::format_reset_time(Some(ts)))
            .unwrap_or_else(|| "?".to_string());

        let mut metadata = HashMap::new();
        metadata.insert("limit_dollars".to_string(), format!("{:.6}", limit_dollars));
        metadata.insert(
            "remaining_dollars".to_string(),
            format!("{:.6}", remaining_dollars),
        );
        metadata.insert("limit_units".to_string(), window.limit.to_string());
        metadata.insert("remaining_units".to_string(), window.remaining.to_string());
        metadata.insert("used_units".to_string(), window.used.to_string());
        metadata.insert("used_dollars".to_string(), format!("{:.6}", used_dollars));
        metadata.insert("reset_at".to_string(), reset_str.clone());
        metadata.insert("percent_used".to_string(), format!("{:.2}", percent_used));

        metadata
    }
}

impl Segment for CubenceSegment {
    fn collect(&self, _input: &InputData) -> Option<SegmentData> {
        let (api_url, cache_duration, timeout) = Self::get_options();

        let info = match SubscriptionApiClient::get_with_cache(&api_url, timeout, cache_duration) {
            Ok(info) => info,
            Err(error_msg) => {
                // Failed to get cubence info, return error segment with detailed error message
                let mut metadata = HashMap::new();
                metadata.insert("error".to_string(), "fetch_failed".to_string());
                metadata.insert("error_message".to_string(), error_msg.clone());
                return Some(SegmentData {
                    primary: format!("Cubence - API Error: {}", error_msg),
                    secondary: String::new(),
                    metadata,
                });
            }
        };

        let five_hour = &info.subscription_window.five_hour;
        let weekly = &info.subscription_window.weekly;
        let balance = &info.normal_balance;

        // Check if has subscription (limit > 0)
        let has_subscription = five_hour.limit > 0 || weekly.limit > 0;

        let mut primary = if has_subscription {
            // Format: Cubence - 订阅[5h $used/$limit | week $used/$limit]  余额[$balance]
            let five_used = SubscriptionApiClient::format_units_to_dollars(five_hour.used);
            let five_limit = SubscriptionApiClient::format_units_to_dollars(five_hour.limit);
            let week_used = SubscriptionApiClient::format_units_to_dollars(weekly.used);
            let week_limit = SubscriptionApiClient::format_units_to_dollars(weekly.limit);

            format!(
                "Cubence - 订阅[5h ${:.2}/${:.2} | week ${:.2}/${:.2}]  余额[${:.2}]",
                five_used, five_limit, week_used, week_limit, balance.amount_dollar
            )
        } else {
            // Format: Cubence - 余额[$balance]
            format!("Cubence - 余额[${:.2}]", balance.amount_dollar)
        };

        // Check health endpoint latency
        let base_url = credentials::get_anthropic_base_url()
            .unwrap_or_else(|| "https://cubence.com/api".to_string());

        let latency_result = SubscriptionApiClient::check_health_latency(&base_url, timeout);
        let latency_str = match &latency_result {
            Ok(latency_ms) => format!(" 延迟[{}ms]", latency_ms),
            Err(_) => " 延迟[timeout]".to_string(),
        };

        primary.push_str(&latency_str);

        let secondary = String::new();

        // Build metadata
        let mut metadata = HashMap::new();

        // Balance metadata
        metadata.insert(
            "balance_dollars".to_string(),
            format!("{:.6}", balance.amount_dollar),
        );
        metadata.insert(
            "balance_units".to_string(),
            balance.amount_units.to_string(),
        );

        // Subscription metadata
        metadata.insert("has_subscription".to_string(), has_subscription.to_string());
        metadata.insert("timestamp".to_string(), info.timestamp.to_string());

        // Five hour window metadata
        let five_meta = Self::format_window_for_metadata(five_hour);
        for (k, v) in five_meta {
            metadata.insert(format!("five_hour_{}", k), v);
        }

        // Weekly window metadata
        let weekly_meta = Self::format_window_for_metadata(weekly);
        for (k, v) in weekly_meta {
            metadata.insert(format!("weekly_{}", k), v);
        }

        // Add latency to metadata
        if let Ok(latency_ms) = latency_result {
            metadata.insert("latency_ms".to_string(), latency_ms.to_string());
        }

        Some(SegmentData {
            primary,
            secondary,
            metadata,
        })
    }

    fn id(&self) -> SegmentId {
        SegmentId::Cubence
    }
}
