# frozen_string_literal: true

# create ApiKey seeds

module Seeds
  class ConsumerApiKey < Base
    def seed!
      create_api_key
    end

    private

    def create_api_key
      ApiKey.create(consumer_name: "appeals_consumer", key_digest: "z1VxSVb2iae07+bYq8ZjQZs3ll4ZgSeVIUC9O5u+HfA=",
                                key_string: "5ecb5d7b440e429bb5fac331419c7e1a")
    end
  end
end
