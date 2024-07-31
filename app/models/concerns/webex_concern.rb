# frozen_string_literal: true

# Shared Webex methods used for Webex related functions
module WebexConcern
  extend ActiveSupport::Concern

  # Purpose: Set up the configuration for calling the recordings endpoint
  #
  # Params: query - additional details for how returned data should be displayed
  #
  # Return: Object with header information for the endpoin
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

  # Purpose: Set up the configuration for calling the rooms endpoint
  #
  # Params: query - additional details for how returned data should be displayed
  #
  # Return: Object with header information for the endpoint
  def rooms_config(query = nil)
    {
      host: ENV["WEBEX_HOST_MAIN"],
      port: ENV["WEBEX_PORT"],
      aud: ENV["WEBEX_ORGANIZATION"],
      apikey: ENV["WEBEX_BOTTOKEN"],
      domain: ENV["WEBEX_DOMAIN_MAIN"],
      api_endpoint: ENV["WEBEX_API_MAIN"],
      query: query
    }
  end

  # Purpose: Set up the configuration for calling the instant connect endpoint
  #
  # Params: query - additional details for how returned data should be displayed
  #
  # Return: Object with header information for the endpoint
  def instant_connect_config(query = nil)
    {
      host: ENV["WEBEX_HOST_IC"],
      port: ENV["WEBEX_PORT"],
      aud: ENV["WEBEX_ORGANIZATION"],
      apikey: ENV["WEBEX_BOTTOKEN"],
      domain: ENV["WEBEX_DOMAIN_IC"],
      api_endpoint: ENV["WEBEX_API_IC"],
      query: query
    }
  end
end
