class SlackService
  include ActiveModel::Model

  attr_accessor :url

  def http_service
    HTTPClient.new
  end

  def send_notification(msg)
    return unless url
    body = { "text": msg }.to_json
    params = { body: body, headers: { "Content-Type" => "application/json" } }
    http_service.post(url, params)
  end
end
