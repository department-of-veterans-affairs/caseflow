# frozen_string_literal: true

class ExternalApi::WebexService::AccessTokenRefreshResponse < ExternalApi::WebexService::Response
  def access_token
    data["access_token"]
  end

  def refresh_token
    data["refresh_token"]
  end
end
