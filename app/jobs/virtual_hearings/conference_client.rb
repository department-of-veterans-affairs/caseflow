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
        host: ENV["WEBEX_HOST_IC"],
        port: ENV["WEBEX_PORT"],
        aud: ENV["WEBEX_ORGANIZATION"],
        apikey: ENV["WEBEX_BOTTOKEN"],
        domain: ENV["WEBEX_DOMAIN_IC"],
        api_endpoint: ENV["WEBEX_API_IC"],
        query: nil
      )
    else
      msg = "Conference Provider for the Virtual Hearing Not Found"
      fail Caseflow::Error::MeetingTypeNotFoundError, message: msg
    end
  end
end
