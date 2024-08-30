# frozen_string_literal: true

# create annotation seeds

module Seeds
    class ApiKeys < Base
    def seed!
      create_api_keys
    end

    private

    def create_api_keys
      ApiKey.create!(consumer_name: "TestApiKey", key_string: "test")
    end
  end
end
