# frozen_string_literal: true

FactoryBot.define do
  factory :metric do
    user { User.find_by_css_id("DEFAULT_USER") }
    app_name { Metric::APP_NAMES[:caseflow] }
    metric_type { Metric::METRIC_TYPES.values.sample }
    metric_product { Metric::PRODUCT_TYPES.values.sample }
    metric_group { Metric::METRIC_GROUPS.values.sample }
    sent_to { ["javascript_console"] }
    metric_class { Metrics::V2::LogsController }
    metric_message { "metric_message" }
    metric_name { "Javascript request" }
  end
end
