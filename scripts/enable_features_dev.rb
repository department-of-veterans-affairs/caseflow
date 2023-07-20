# frozen_string_literal: true

# bundle exec rails runner scripts/enable_features_dev.rb

class AllFeatureToggles
  def call
    files.each_with_object([]) do |file, result|
      result << FeatureToggleSearch.new(file: file, regex: feature_toggle_regex).call
      result << FeatureToggleSearch.new(file: file, regex: feature_enabled_regex).call
    end
  end

  private

  def files
    app_rb_files + app_erb_files
  end

  def app_rb_files
    Dir.glob("app/**/*.rb")
  end

  def app_erb_files
    Dir.glob("app/views/**/*.erb")
  end

  def feature_toggle_regex
    /FeatureToggle.enabled\?\(:(.+?(, user:.+)*)\)/
  end

  def feature_enabled_regex
    /feature_enabled\?\(:(.+?)\)/
  end
end

class FeatureToggleSearch
  def initialize(file:, regex:)
    @file = file
    @regex = regex
  end

  def call
    File.open(file, "r").each_with_object([]) do |line, result|
      line.match(regex) { |found| result << found[1] }
    end
  end

  private

  attr_reader :file, :regex
end

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
]

all_features = AllFeatureToggles.new.call.flatten.uniq
all_features.map! { |feature| feature.split(",")[0] }
all_features.reject! { |toggle| disabled_flags.include? toggle }

all_features.each_with_object([]) do |feature, result|
  result << { "feature" => feature, "enable_all" => true }
  FeatureToggle.sync! result.to_yaml
end

puts "Enabled #{all_features.count} features: #{all_features.sort.join(', ')}"
