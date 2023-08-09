# frozen_string_literal: true

class VirtualHearingNotCreatedError < StandardError; end
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
      @client ||= WebexService.new(
        host: ENV["WEBEX_MANAGEMENT_NODE_HOST"],
        port: ENV["WEBEX_MANAGEMENT_NODE_PORT"],
        user_name: ENV["WEBEX_USERNAME"],
        password: ENV["WEBEX_PASSWORD"],
        client_host: ENV["WEBEX_CLIENT_HOST"]
      )
    else
      fail VirtualHearingNotCreatedError, "Invalid meeting type"
    end
  end
end
