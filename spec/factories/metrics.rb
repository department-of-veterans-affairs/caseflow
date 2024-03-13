FactoryBot.define do
  factory :metric do
    app_name { "caseflow" }
    metric_class { "MetricsService" }
    metric_message { "metric message" }
    metric_name { "metric" }
    metric_product { "reader" }
    metric_type { "performance" }
    sent_to { ["rails_console"] }
    association :user

  end
end