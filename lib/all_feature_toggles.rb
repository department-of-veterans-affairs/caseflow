# frozen_string_literal: true

class AllFeatureToggles
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
