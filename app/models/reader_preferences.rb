# frozen_string_literal: true
class ReaderPreferences

  def self.get(preference)
    # return unless prefrences.include?(prefrence)
    client.get(preference)&.to_i
  end

  def self.set(preference, value)
    # check if preference is in the preferences yml file
    client.set(preference, value)
  end

  def self.delete(preference)
    return unless preference

    client.del preference
  end

  def self.client
    # Use separate Redis namespace for test to avoid conflicts between test and dev environments
    @cache_namespace ||= Rails.env.test? ? :reader_preferences_test : :reader_preferences
    @client ||= Redis::Namespace.new(@cache_namespace, redis: redis)
  end

  def self.redis
    @redis ||= Redis.new(url: Rails.application.secrets.redis_url_cache)
  end

# TO DO
  # def self.sync!(config_file_string)
  #   config_hash = validate_config(config_file_string)
  #   existing_features = features
  #   client.multi do
  #     features_from_file = []
  #     config_hash.each do |feature_hash|
  #       feature = feature_hash["feature"]
  #       features_from_file.push(feature)
  #       client.sadd FEATURE_LIST_KEY, feature
  #       data = {}
  #       data[:users] = feature_hash["users"] if feature_hash.key?("users")
  #       data[:regional_offices] = feature_hash["regional_offices"] if feature_hash.key?("regional_offices")
  #       set_data(feature, data)
  #     end
  #     existing_features.each { |feature| remove_feature(feature) unless features_from_file.include?(feature.to_s) }
  #   end
  # end

  class << self
    private

  end
end
