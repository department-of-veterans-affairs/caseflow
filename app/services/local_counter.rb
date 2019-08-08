# frozen_string_literal: true

class LocalCounter
  ON_BUTTON = "local_counter_enabled"
  KEY_SUFFIX = "_local_request_attempt_count"

  def self.enable
    return unless valid_env?

    Rails.cache.write(ON_BUTTON, true)
  end

  def self.disable
    Rails.cache.delete_matched("*#{KEY_SUFFIX}")
    Rails.cache.delete(ON_BUTTON)
  end

  def self.increment_counter(category)
    return unless enabled?

    initialize_counter(category)
    current_val = get_counter(category)
    set_counter(category, current_val + 1)
  end

  def self.get_counter(category)
    key = get_key_name(category)
    Rails.cache.fetch(key)
  end

  private_class_method def self.enabled?
    valid_env? && Rails.cache.fetch(ON_BUTTON)
  end

  private_class_method def self.valid_env?
    Rails.env.development? || Rails.env.test?
  end

  private_class_method def self.initialize_counter(category)
    return if get_counter(category)

    set_counter(category, 0)
  end

  private_class_method def self.set_counter(category, val)
    key = get_key_name(category)
    Rails.cache.write(key, val)
  end

  private_class_method def self.get_key_name(category)
    "#{category}#{KEY_SUFFIX}"
  end
end
