# frozen_string_literal: true

class ReaderPreferences
  def self.get(preference)
    preference_name = preference.to_s.upcase
    value = client.get(preference_name) || ENV[preference_name]

    if value
      return value.to_i
    end

    "#{preference_name} is not in the list of allowed preferences.. #{valid_preferences}"
  end

  def self.set(preference, new_value)
    preference_name = preference.to_s.upcase

    current_value = client.get(preference_name) || ENV[preference_name]

    if current_value
      client.set(preference_name, new_value.to_s)
      "#{preference_name} set to #{new_value}"
    else
      "#{preference_name} is not in the list of allowed preferences.. #{valid_preferences}"
    end
  end

  def self.delete(preference)
    preference_name = preference.to_s.upcase

    current_value = client.get(preference_name)

    if current_value
      client.del preference_name

      "#{preference_name} was reset to default value #{ENV[preference_name]}"
    else
      "#{preference_name} is not set to a custom value"
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
  # READER_DELAY_BEFORE_PROGRESS_BAR: 1000
  # READER_SHOW_PROGRESS_BAR_THRESHOLD: 3000

  # prodtest:
  # READER_DELAY_BEFORE_PROGRESS_BAR: 1000
  # READER_SHOW_PROGRESS_BAR_THRESHOLD: 3000

  # preprod:
  # READER_DELAY_BEFORE_PROGRESS_BAR: 1000
  # READER_SHOW_PROGRESS_BAR_THRESHOLD: 3000

  # uat:
  # READER_DELAY_BEFORE_PROGRESS_BAR: 1000
  # READER_SHOW_PROGRESS_BAR_THRESHOLD: 3000

  def self.valid_preferences
    @valid_preferences ||= ENV.select { |feature, _value| feature.include?("READER") }.keys
  end
end
