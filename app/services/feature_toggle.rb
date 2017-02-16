class FeatureToggle
  class FeatureIsNotEnabledError < StandardError
    def message
      "Feature is not enabled"
    end
  end

  class FeatureIsAlreadyEnabledError < StandardError
    def message
      "Feature is already enabled"
    end
  end

  # Keeps track of all enabled features
  FEATURES = :features

  # Adds a feature to the set of known features.
  def self.enable_feature(feature)
    fail FeatureIsAlreadyEnabledError if feature_enabled?(feature)
    client.sadd FEATURES, feature
    true
  end

  # Removes a feature from the set of known features.
  def self.disable_feature(feature)
    fail FeatureIsNotEnabledError unless feature_enabled?(feature)
    client.multi do
      client.srem FEATURES, feature
      client.del feature
    end
    true
  end

  def self.feature_enabled?(feature)
    features.include?(feature.to_s)
  end

  # The set of known features.
  def self.features
    client.smembers(FEATURES)
  end

  # Adds a group to a given feature
  def self.enable_group(feature, group)
    fail FeatureIsNotEnabledError unless feature_enabled?(feature)
    client.sadd feature, group
    true
  end

  # Removes a group from a given feature
  def self.disable_group(feature, group)
    fail FeatureIsNotEnabledError unless feature_enabled?(feature)
    client.srem feature, group
    true
  end

  # Lists all groups for a given feature
  def self.list_groups(feature)
    fail FeatureIsNotEnabledError unless feature_enabled?(feature)
    client.smembers(feature)
  end

  # Removes all groups from a given feature
  def self.clear_all_groups(feature)
    fail FeatureIsNotEnabledError unless feature_enabled?(feature)
    client.del(feature)
    true
  end

  # Checks if a given feature is enabled for a specific group
  def self.enabled_for_group?(feature, group)
    client.sismember(feature, group)
  end

  # Checks if a given feature is disabled for a specific group
  def self.disabled_for_group?(feature, group)
    !enabled_for_group?(feature, group)
  end

  def self.client
    @client ||= Redis.new(url: Rails.application.secrets.redis_url_cache)
  end
end
