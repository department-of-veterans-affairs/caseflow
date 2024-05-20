# frozen_string_literal: true

# This file defines the RefreshWebexAccessTokenJob class, a job that refreshes the access token
# used for Webex API calls. This job is part of the VirtualHearings module.
#
# The job has the following key behaviors:
# 1. The perform method creates a new instance of WebexService and calls its
#    refresh_access_token method to get a new access token from the Webex API.
# 2. If the response from the Webex API is successful, the new access and refresh tokens are
#    stored in CredStash with the keys webex_#{Rails.deploy_env}_access_token and
#    webex_#{Rails.deploy_env}_refresh_token respectively.
# 3. If an error occurs during the process, it is caught and logged using the log_error method.
#
# This job is queued with low priority, indicating that it does not need to be run immediately
# and can wait until the system is less busy.

class Hearings::RefreshWebexAccessTokenJob < CaseflowJob
  queue_with_priority :low_priority

  def perform
    webex_service = WebexService.new(
      host: ENV["WEBEX_HOST_MAIN"],
      port: nil,
      aud: nil,
      apikey: nil,
      domain: ENV["WEBEX_DOMAIN_MAIN"],
      api_endpoint: ENV["WEBEX_API_MAIN"],
      query: nil
    )
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
