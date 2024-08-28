# frozen_string_literal: true

# create annotation seeds

module Seeds
  class ApiKey
    def seed!
      create_api_key
    end

    private

    def create_api_key
      ApiKey.create!(consumer_name: "TestApiKey", key_string: "test")
    end
  end
end
