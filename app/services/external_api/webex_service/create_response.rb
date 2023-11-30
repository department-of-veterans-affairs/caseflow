# frozen_string_literal: true

class ExternalApi::WebexService::CreateResponse < ExternalApi::WebexService::Response
  def data
    JSON.parse(resp.raw_body)
  end

  def base_url
    data["baseUrl"]
  end

  def host_link
    "#{base_url}#{data.dig('host', 0, 'short')}"
  end

  def guest_link
    "#{base_url}#{data.dig('guest', 0, 'short')}"
  end
end
