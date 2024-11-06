# frozen_string_literal: true

module Seeds
  require "./app/models/api_key.rb"

  class ApiKeys < Base
    def seed!
      create_api_keys
    end

    private

    def create_api_keys
      ApiKey.create!(consumer_name: "TestApiKey", key_string: "test")
      ApiKey.create(consumer_name: "appeals_consumer",
                    key_digest: "z1VxSVb2iae07+bYq8ZjQZs3ll4ZgSeVIUC9O5u+HfA=",
                    key_string: "5ecb5d7b440e429bb5fac331419c7e1a")
    end
  end
end
