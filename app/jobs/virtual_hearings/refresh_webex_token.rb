
# app/jobs/refresh_webex_access_token_job.rb

class RefreshWebexAccessTokenJob < ApplicationJob
  queue_as :default

  def perform
    new_token = VirtualHearings::ConferenceClient.refresh_webex_access_token

    if new_token.present?
      CredstashService.update_access_token(new_token)
    else
      # Retry logic here
    end
  rescue => e
    # Error handler logic here
  end
end
