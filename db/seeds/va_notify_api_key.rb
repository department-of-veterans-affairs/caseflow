# frozen_string_literal: true

# create annotation seeds

module Seeds
  class VaNotifyApiKey
    def seed!
      create_api_key
    end

    private

    def create_api_key
      ApiKey.create!(consumer_name: "VANotifyTestApiKey", key_string: "test")
    end
  end
end
