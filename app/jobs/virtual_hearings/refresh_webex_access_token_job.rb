# frozen_string_literal: true

require "rcredstash"

class VirtualHearings::RefreshWebexAccessTokenJob < CaseflowJob
  queue_as :low_priority

  def perform
    webex_service = WebexService.new
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
