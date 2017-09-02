# This class used FeatureToggle as a reference
class Caseflow::Functions
  # Keeps track of all enabled functions
  FUNCTIONS_LIST_KEY = :function_list_key

  def self.functions
    client.smembers(FUNCTIONS_LIST_KEY)
  end

  # Functions.grant("Reader", users: ["CSS_ID_1", "CSS_ID_2"])
  def self.grant(function, users:)
    # redis method: sadd (add item to a set)
    client.sadd FUNCTIONS_LIST_KEY, function unless functions.include?(function)

    enable(function: function, value: users) if users.present?

    true
  end

  # Functions.deny!("Reader", users: ["CSS_ID_1"])
  def self.deny(function, users:)
    disable(function: function, value: users)

    # This is if we want to remove function when there are no users with that function
    # disable the function completely if users become empty
    remove_function(function) if function_enabled_hash(function).empty?
    true
  end

  # Method to check if a given function is granted for a user
  # Functions.granted!("Reader", "CSS_ID_1")
  def self.granted?(function, user)
    return false unless functions.include?(function)

    data = function_enabled_hash(function)
    return data[:users].include?(user)
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

  class << self
    private

    def enable(function:, value:)
      return unless value
      data = Hash[:users, value.compact.uniq]

      set_data(function, data)
    end

    def disable(function:, value:)
      return unless value

      data = function_enabled_hash(function)
      return unless data[:users]

      data[:users] = data[:users] - value

      # Delete :users if empty
      data.delete(:users) if data[:users].empty?

      set_data(function, data)
    end

    def function_enabled_hash(function)
      data = client.get(function)
      data && JSON.parse(data).symbolize_keys || {}
    end

    def remove_function(function)
      client.multi do
        # redis method: srem (remove item from a set)
        client.srem FUNCTIONS_LIST_KEY, function
        client.del function
      end
    end

    def set_data(function, data)
      client.set(function, data.to_json)
    end
  end
end
