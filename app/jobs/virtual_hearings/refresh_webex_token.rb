# app/jobs/refresh_webex_access_token_job.rb

class RefreshWebexAccessTokenJob < ApplicationJob
  queue_as :default

  def perform
    webex_service = ExternalApi::WebexService.new(host: ENV['WEBEX_HOST'], port: ENV['WEBEX_PORT'], aud: ENV['WEBEX_AUD'], apikey: ENV['WEBEX_API_KEY'], domain: ENV['WEBEX_DOMAIN'], api_endpoint: ENV['WEBEX_API_ENDPOINT'])
    response = webex_service.refresh_access_token

    if response.present?
      new_token = JSON.parse(response)['access_token']
      CredstashService.update_access_token(new_token)
    else
      # Retry logic here
  end
  
  rescue => e
    # Error handler logic here
  ensure
    # Schedule the job to run again in 24 hours
    self.class.set(wait: 24.hours).perform_later
  end
end
