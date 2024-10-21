# frozen_string_literal: true

if Rails.env.development? || Rails.env.test?
  Aws.config.update(
    endpoint: "http://localhost:4566",
    access_key_id: ENV["AWS_SECRET_ACCESS_KEY"],
    secret_access_key: 'ENV["AWS_ACCESS_KEY_ID"]',
    region: ENV["AWS_DEFAULT_REGION"] || "us-east-1"
  )
end
