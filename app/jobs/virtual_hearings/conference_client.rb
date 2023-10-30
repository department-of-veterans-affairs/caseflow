# frozen_string_literal: true

module VirtualHearings::ConferenceClient
  def client(virtual_hearing)
    case virtual_hearing.conference_provider
    when "pexip"
      @client ||= PexipService.new(
        host: ENV["PEXIP_MANAGEMENT_NODE_HOST"],
        port: ENV["PEXIP_MANAGEMENT_NODE_PORT"],
        user_name: ENV["PEXIP_USERNAME"],
        password: ENV["PEXIP_PASSWORD"],
        client_host: ENV["PEXIP_CLIENT_HOST"]
      )
    when "webex"
      @client ||= WebexService.new(
        host: ENV["WEBEX_HOST"],
        port: ENV["WEBEX_PORT"],
        aud: ENV["WEBEX_ORGANIZATION"],
        apikey: ENV["WEBEX_BOTTOKEN"],
        domain: ENV["WEBEX_DOMAIN"],
        api_endpoint: ENV["WEBEX_API"]
      )
    else
      msg = "Conference Provider for the Virtual Hearing Not Found"
      fail Caseflow::Error::MeetingTypeNotFoundError, message: msg
    end
  end
end
