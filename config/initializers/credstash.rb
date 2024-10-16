# frozen_string_literal: true

CredStash.configure do |config|
  # Table name will probably change
  config.table_name = "appeals-rotating-tokens"
  config.storage = (Rails.env.development? || Rails.env.test?) ? :dynamodb_local : :dynamodb
end
