# frozen_string_literal: true

module WebexConcern
  extend ActiveSupport::Concern

  def recordings_config(query)
    {
      host: ENV["WEBEX_HOST_MAIN"],
      port: ENV["WEBEX_PORT"],
      aud: ENV["WEBEX_ORGANIZATION"],
      apikey: WebexService.access_token,
      domain: ENV["WEBEX_DOMAIN_MAIN"],
      api_endpoint: ENV["WEBEX_API_MAIN"],
      query: query
    }
  end
end
