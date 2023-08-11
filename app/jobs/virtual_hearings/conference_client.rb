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
      msg = "You hit the Webex Service!"
      fail Caseflow::Error::WebexApiError, message: msg
    else
      begin
        fail ConferenceCreationError::MeetingTypeNotFoundError
      rescue ConferenceCreationError::MeetingTypeNotFoundError => error
        Rails.logger.error(error)
        Raven.capture_exception(error)
      end
    end
  end
end
