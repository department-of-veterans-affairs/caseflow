# This class used FeatureToggle as a reference
class Functions
  # :nocov:
  # Keeps track of all enabled functions
  FUNCTIONS_LIST_KEY = :functions_list_key

  def self.functions
    client.smembers(FUNCTIONS_LIST_KEY)
  end

  # Functions.grant!("Reader", users: ["CSS_ID_1", "CSS_ID_2"])
  def self.grant!(function, users:)
    # redis method: sadd (add item to a set, ignore existing members)
    client.sadd FUNCTIONS_LIST_KEY, function

    enable(function: function, value: users)

    # Remove the function completely if users become empty
    remove_function(function) if is_empty?(function)

    true
  end

  # Functions.deny!("Reader", users: ["CSS_ID_1"])
  def self.deny!(function, users:)
    client.sadd FUNCTIONS_LIST_KEY, function

    disable(function: function, value: users)

    remove_function(function) if is_empty?(function)

    true
  end

  # Method to check if a given function is granted for a user
  # Functions.granted?("Reader", "CSS_ID_1")
  def self.granted?(function, user)
    return false unless functions.include?(function)

    data = function_enabled_hash(function)
    data[:granted].include?(user)
  end

    # Method to check if a given function is denied to a user
  # Functions.denied?("Reader", "CSS_ID_1")
  def self.denied?(function, user)
    return false unless functions.include?(function)

    data = function_enabled_hash(function)
    data[:denied].include?(user)
  end

  # Returns a hash result for a given function
  def self.details_for(function)
    function_enabled_hash(function) if functions.include?(function)
  end

  def self.client
    # Use separate Redis namespace for test to avoid conflicts between test and dev environments
    namespace = Rails.env.test? ? :functions_test : :functions
    @client ||= Redis::Namespace.new(namespace, redis: redis)
  end

  def self.redis
    @redis ||= Redis.new(url: Rails.application.secrets.redis_url_cache)
  end

  # Removes all the keys for this namespace
  def self.delete_all_keys!
    client.del(*client.keys) unless client.keys.empty?
  end

  class << self
    private

    def enable(function:, value:)
      value = value.compact.uniq
      data = function_enabled_hash(function)
      data[:denied] = data[:denied] - value
      data[:granted] = value

      set_data(function, data)
    end

    def disable(function:, value:)
      value = value.compact.uniq
      data = function_enabled_hash(function)
      data[:granted] = data[:granted] - value
      data[:denied] = value

      set_data(function, data)
    end

    def function_enabled_hash(function)
      data = client.get(function)
      data && JSON.parse(data).symbolize_keys || {:granted => [], :denied => []}
    end

    def remove_function(function)
      client.multi do
        # redis method: srem (remove item from a set)
        client.srem FUNCTIONS_LIST_KEY, function
        client.del function
      end
    end

    def is_empty?(function)
      function_enabled_hash(function)[:granted].empty? && function_enabled_hash(function)[:denied].empty?
    end

    def set_data(function, data)
      client.set(function, data.to_json)
    end
  end
  # :nocov:
end
