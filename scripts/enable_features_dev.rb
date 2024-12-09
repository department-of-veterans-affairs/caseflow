# frozen_string_literal: true

# bundle exec rails runner scripts/enable_features_dev.rb

# Flags that are turned off by default because
#   - they make significantly drastic changes in Dev/Demo compared to Production
#   - the work around the feature has been paused
#   - the flag is only being used to disable functionality
disabled_flags = %w[
  legacy_das_deprecation
  cavc_dashboard_workflow
  poa_auto_refresh
  interface_version_2
  cc_vacatur_visibility
  acd_disable_legacy_lock_ready_appeals
  justification_reason
  disable_legacy_distribution_stats
]

all_features = AllFeatureToggles.new.call.flatten.uniq
all_features.map! { |feature| feature.split(",")[0] }
all_features.reject! { |toggle| disabled_flags.include? toggle }

all_features.each_with_object([]) do |feature, result|
  result << { "feature" => feature, "enable_all" => true }
  FeatureToggle.sync! result.to_yaml
end

puts "Enabled #{all_features.count} features: #{all_features.sort.join(', ')}"
