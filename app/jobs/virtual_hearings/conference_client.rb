# frozen_string_literal: true

module VirtualHearings::ConferenceClient
  def client
    case RequestStore.store[:current_user].meeting_type
    when "pexip"
      @client ||= PexipService.new(
        host: ENV["PEXIP_MANAGEMENT_NODE_HOST"],
        port: ENV["PEXIP_MANAGEMENT_NODE_PORT"],
        user_name: ENV["PEXIP_USERNAME"],
        password: ENV["PEXIP_PASSWORD"],
        client_host: ENV["PEXIP_CLIENT_HOST"]
      )
    when "webex"
      @client ||= ExternalApi::WebexService.new
    else
      msg = "Meeting type for the user is invalid"
      fail Caseflow::Error::MeetingTypeNotFoundError, message: msg
    end
  end
end
