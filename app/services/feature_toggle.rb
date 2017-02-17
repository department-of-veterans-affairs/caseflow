class FeatureToggle

  # Keeps track of all enabled features
  FEATURE_LIST_KEY = :feature_list_key

  def self.features
    client.smembers(FEATURE_LIST_KEY)
  end

  # Method to enable a feature globally or for a specfic set of regional offices
  # Examples:
  # FeatureToggle.enable!(:foo)
  # FeatureToggle.enable!(:bar, regional_offices: ["RO01", "RO02"])
  def self.enable!(feature, regional_offices: [])
    # redis method: sadd (add item to a set)
    client.sadd FEATURE_LIST_KEY, feature unless features.include?(feature.to_s)

    enable_group(feature: feature,
                  key: :regional_offices,
                  value: regional_offices) if regional_offices.present?
    true
  end


  # Method to disable a feature globally or for a specfic set of regional offices
  # Examples:
  # FeatureToggle.disable!(:foo)
  # FeatureToggle.disable!(:bar, regional_offices: ["RO01", "RO02"])
  def self.disable!(feature, regional_offices: [])
    client.multi do
      # redis method: srem (remove item from a set)
      client.srem FEATURE_LIST_KEY, feature
      client.del feature
    end unless regional_offices.present?

    disable_group(feature: feature,
                  key: :regional_offices,
                  value: regional_offices) if regional_offices.present?
    true
  end

  # Method to check if a given feature is enabled for a user
  def self.enabled?(feature, current_user)
    return false unless features.include?(feature.to_s)

    data = details_for(feature)
    if data && data["regional_offices"].present?
      return false unless data["regional_offices"].include?(current_user.regional_office)
    end
    true
  end

  # Returns a hash result for a given feature
  def self.details_for(feature)
    get_data_for_feature(feature) || {} if features.include?(feature.to_s)
  end

  def self.client
    @client ||= Redis::Namespace.new(:feature_toggle, redis: Redis.new(url: Rails.application.secrets.redis_url_cache))
  end

  class << self

    private

    def enable_group(feature:, key:, value:)
      data = get_data_for_subkey(feature, key.to_s)
      data = data.present? ? data + value : value
      set_data_for_subkey(feature, key, data)
    end

    def disable_group(feature:, key:, value:)
      data = get_data_for_subkey(feature, key.to_s)
      return unless data
      data = data - value
      set_data_for_subkey(feature, key, data)
    end

    def get_data_for_feature(feature)
      data = client.get(feature)
      JSON.parse(data) if data
    end

    def get_data_for_subkey(feature, key)
      data = get_data_for_feature(feature)
      data[key] if data
    end

    def set_data_for_subkey(feature, key, data)
      client.set(feature, { key => data.uniq }.to_json)
    end
  end
end
