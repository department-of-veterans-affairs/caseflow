# frozen_string_literal: true

require "rcredstash"

class VirtualHearings::RefreshWebexAccessTokenJob < CaseflowJob
  queue_with_priority :low_priority

  def perform
    webex_service = WebexService.new(host: nil, port: nil, aud: nil, apikey: nil, domain: nil, api_endpoint: nil)
    response = webex_service.refresh_access_token

    if response.success?
      new_access_token = response.access_token
      new_refresh_token = response.refresh_token

      CredStash.put("webex_#{Rails.deploy_env}_access_token", new_access_token)
      CredStash.put("webex_#{Rails.deploy_env}_refresh_token", new_refresh_token)

    end
  rescue StandardError => error
    log_error(error)
  end
end
