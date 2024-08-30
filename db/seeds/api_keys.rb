# frozen_string_literal: true

# create annotation seeds

module Seeds
  require './app/models/api_key.rb'

  class ApiKeys
    def seed!
      create_api_keys
    end

    private

    def create_api_keys
      ApiKey.create!(consumer_name: "TestApiKey", key_string: "test")
    end
  end
end
