# frozen_string_literal: true

class ExternalApi::WebexService
  BASE_URL = "#{ENV['WEBEX_HOST']}#{ENV['WEBEX_DOMAIN']}"
  AUTH_URL = "/v1/access_token"
  GRANT_TYPE = "refresh_token"
  CLIENT_ID = ENV["WEBEX_CLIENT_ID"]
  CLIENT_SECRET = ENV["WEBEX_CLIENT_SECRET"]
  REFRESH_TOKEN = ENV["WEBEX_REFRESH_TOKEN"]
  HEADERS = {
    "Content-Type": "application/x-www-form-urlencoded", Accept: "application/json"
  }.freeze

  def create_conference(*)
    fail NotImplementedError
  end

  def delete_conference(*)
    fail NotImplementedError
  end

  # Purpose: Refreshing the access token to access the API
  # Return: The response body
  def refresh_access_token
    url = URI::DEFAULT_PARSER.escape(BASE_URL + GET_TOKEN_ENDPOINT)
    params = {
      grant_type: GRANT_TYPE,
      client_id: CLIENT_ID,
      client_secret: CLIENT_SECRET,
      refresh_token: REFRESH_TOKEN
    }
    encoded_params = URI.encode_www_form(params)
    response = Faraday.post(url, encoded_params)
    response.body
  end
end
