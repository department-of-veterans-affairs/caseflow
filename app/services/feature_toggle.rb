class FeatureToggle
  # Keeps track of all enabled features
  FEATURE_LIST_KEY = :feature_list_key

  def self.features
    client.smembers(FEATURE_LIST_KEY).map(&:to_sym)
  end

  # Method to enable a feature globally or for a specfic set of regional offices
  # Examples:
  # FeatureToggle.enable!(:foo)
  # FeatureToggle.enable!(:bar, regional_offices: ["RO01", "RO02"])
  def self.enable!(feature, regional_offices: nil)
    # redis method: sadd (add item to a set)
    client.sadd FEATURE_LIST_KEY, feature unless features.include?(feature)

    if regional_offices.present?
      enable(feature: feature,
             key: :regional_offices,
             value: regional_offices)
    end
    true
  end

  # Method to disable a feature globally or for a specfic set of regional offices
  # Examples:
  # FeatureToggle.disable!(:foo)
  # FeatureToggle.disable!(:bar, regional_offices: ["RO01", "RO02"])
  def self.disable!(feature, regional_offices: nil)
    unless regional_offices
      client.multi do
        # redis method: srem (remove item from a set)
        client.srem FEATURE_LIST_KEY, feature
        client.del feature
      end
      return true
    end

    disable(feature: feature,
            key: :regional_offices,
            value: regional_offices)

    true
  end

  # Method to check if a given feature is enabled for a user
  def self.enabled?(feature, current_user: nil)
    return false unless features.include?(feature)
    regional_offices = get_subkey(feature, :regional_offices)
    # if regional_offices key is set and a user is passed, check if the feature
    # is enabled for the user's ro. Otherwise, it is enabled globally
    if current_user && regional_offices.present? && !regional_offices.include?(current_user.regional_office)
      return false
    end

    true
  end

  # Returns a hash result for a given feature
  def self.details_for(feature)
    feature_hash(feature) || {} if features.include?(feature)
  end

  def self.client
    @client ||= Redis::Namespace.new(:feature_toggle, redis: Redis.new(url: Rails.application.secrets.redis_url_cache))
  end

  class << self
    private

    def enable(feature:, key:, value:)
      data = get_subkey(feature, key)
      data = data.present? ? data + value : value
      set_subkey(feature, key, data)
    end

    def disable(feature:, key:, value:)
      data = get_subkey(feature, key)
      return unless data
      set_subkey(feature, key, data - value)
    end

    def feature_hash(feature)
      data = client.get(feature)
      JSON.parse(data).symbolize_keys if data
    end

    def get_subkey(feature, key)
      data = feature_hash(feature)
      data[key] if data
    end

    def set_subkey(feature, key, data)
      client.set(feature, { key => data.uniq }.to_json)
    end
  end
end
