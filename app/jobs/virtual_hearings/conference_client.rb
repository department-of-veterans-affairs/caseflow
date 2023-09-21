# frozen_string_literal: true

module VirtualHearings::ConferenceClient
  def client
    case RequestStore.store[:current_user].conference_provider
    when "pexip"
      @client ||= PexipService.new(
        host: ENV["PEXIP_MANAGEMENT_NODE_HOST"],
        port: ENV["PEXIP_MANAGEMENT_NODE_PORT"],
        user_name: ENV["PEXIP_USERNAME"],
        password: ENV["PEXIP_PASSWORD"],
        client_host: ENV["PEXIP_CLIENT_HOST"]
      )
    when "webex"
      msg = "You hit the Webex Service!"
      fail Caseflow::Error::WebexApiError, message: msg
      # @client ||= WebexService.new(
      #   host: ENV["WEBEX_MANAGEMENT_NODE_HOST"],
      #   port: ENV["WEBEX_MANAGEMENT_NODE_PORT"],
      #   user_name: ENV["WEBEX_USERNAME"],
      #   password: ENV["WEBEX_PASSWORD"],
      #   client_host: ENV["WEBEX_CLIENT_HOST"]
      # )
    else
      msg = "Meeting type for the user is invalid"
      fail Caseflow::Error::MeetingTypeNotFoundError, message: msg
    end
  end
end
