# frozen_string_literal: true

class ExternalApi::WebexService::CreateResponse < ExternalApi::WebexService::Response
  def base_url
    data["baseUrl"]
  end

  def host_link
    "#{base_url}#{data.dig('host', 0, 'short')}"
  end

  def co_host_link
    "#{base_url}#{data.dig('host', 1, 'short')}"
  end

  def guest_link
    "#{base_url}#{data.dig('guest', 0, 'short')}"
  end
end
