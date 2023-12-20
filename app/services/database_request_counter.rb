# frozen_string_literal: true

class DatabaseRequestCounter
  ON_BUTTON = "db_request_counter_enabled"
  KEY_SUFFIX = "_db_request_attempt_count"

  class DatabaseRequestCounterNotEnabledError < StandardError; end

  class << self
    def enable
      return unless valid_env?

      Rails.cache.write(ON_BUTTON, true)
    end

    def disable
      Rails.cache.delete_matched(".*#{KEY_SUFFIX}")
      Rails.cache.delete(ON_BUTTON)
    end

    def increment_counter(category)
      return unless enabled?

      current_val = get_counter(category) || 0

      key = get_key_name(category)
      Rails.cache.write(key, current_val + 1)
    end

    def get_counter(category)
      fail(DatabaseRequestCounterNotEnabledError) unless enabled?

      key = get_key_name(category)
      Rails.cache.fetch(key)
    end

    def valid_env?
      Rails.env.development? || Rails.env.test?
    end

    private

    def enabled?
      valid_env? && Rails.cache.fetch(ON_BUTTON)
    end

    def get_key_name(category)
      "#{category}#{KEY_SUFFIX}"
    end
  end
end
