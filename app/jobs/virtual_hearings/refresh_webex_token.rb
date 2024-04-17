# frozen_string_literal: true

require "rcredstash"

class RefreshWebexAccessTokenJob < CaseflowJob
  queue_as :low_priority

  def perform
    webex_service = WebexService.new(
      host: ENV["WEBEX_HOST"],
      port: ENV["WEBEX_PORT"],
      aud: ENV["WEBEX_AUD"],
      apikey: ENV["WEBEX_API_KEY"],
      domain: ENV["WEBEX_DOMAIN"],
      api_endpoint: ENV["WEBEX_API_ENDPOINT"]
    )
    response = webex_service.refresh_access_token

    if response.success?
      new_access_token = response["access_token"]
      new_refresh_token = response["refresh_token"]

      CredStash.put("webex_access_token", new_access_token, version: 1)
      CredStash.put("webex_refresh_token", new_refresh_token, version: 1)

    end
  rescue StandardError => error
    log_error(error)
  end
end
