# frozen_string_literal: true
class ReaderPreferences

  def self.get(preference)
    preference_name = normalize(preference)
    value = client.get(preference_name) || ENV[preference_name]

    if value
      return value.to_i
    end
  end

  def self.set(preference, new_value)
    preference_name = normalize(preference)

    current_value = client.get(preference_name) || ENV[preference_name]

    if current_value
      client.set(preference_name, new_value.to_s)
      details_for(preference_name)
    end
  end

  def self.delete(preference)
    preference_name = normalize(preference)

    current_value = client.get(preference_name)

    if current_value
      client.del preference_name
      details_for(preference_name)
    end
  end

  # Returns an array with current key and value for a given preference
  def self.details_for(preference)
    preference_name = normalize(preference)
    value = get(preference_name)
    if value
      ["#{preference_name}", value]
    end
  end

  def self.normalize(preference)
    if preference.is_a?(String) || preference.is_a?(Symbol)
      preference.to_s.upcase
    end
  end

  def self.client
    # Use separate Redis namespace for test to avoid conflicts between test and dev environments
    @cache_namespace ||= Rails.env.test? ? :reader_preferences_test : :reader_preferences
    @client ||= Redis::Namespace.new(@cache_namespace, redis: redis)
  end

  def self.redis
    @redis ||= Redis.new(url: Rails.application.secrets.redis_url_cache)
  end

    # Default values are stored as ENV enviroment dependent values in the file
    # appeals-deployment/ansible/roles/caseflow-certification/defaults/main.yml
    # Example:
    # http_env_specific_environment:
    # prod:
    #   READER_DELAY_BEFORE_PROGRESS_BAR: 1000
    #   READER_SHOW_PROGRESS_BAR_THRESHOLD: 3000

    # prodtest:
    #   READER_DELAY_BEFORE_PROGRESS_BAR: 1000
    #   READER_SHOW_PROGRESS_BAR_THRESHOLD: 3000

    # preprod:
    #   READER_DELAY_BEFORE_PROGRESS_BAR: 1000
    #   READER_SHOW_PROGRESS_BAR_THRESHOLD: 3000

    # uat:
    #   READER_DELAY_BEFORE_PROGRESS_BAR: 1000
    #   READER_SHOW_PROGRESS_BAR_THRESHOLD: 3000
end
