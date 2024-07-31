# frozen_string_literal: true

module VirtualHearings::ConferenceClient
  include WebexConcern

  def client(virtual_hearing)
    @client ||= case virtual_hearing.conference_provider
                when "pexip" then create_pexip_client
                when "webex" then create_webex_client
                when nil
                  virtual_hearing.set_default_meeting_type

                  return create_pexip_client if virtual_hearing.conference_provider == "pexip"

                  return create_webex_client if virtual_hearing.conference_provider == "webex"

                  raise_not_found_error
                else
                  raise_not_found_error
                end
  end

  private

  def raise_not_found_error
    msg = "Conference Provider for the Virtual Hearing Not Found"

    fail Caseflow::Error::MeetingTypeNotFoundError, message: msg
  end

  def create_webex_client
    WebexService.new(instant_connect_config)
  end

  def create_pexip_client
    PexipService.new(
      host: ENV["PEXIP_MANAGEMENT_NODE_HOST"],
      port: ENV["PEXIP_MANAGEMENT_NODE_PORT"],
      user_name: ENV["PEXIP_USERNAME"],
      password: ENV["PEXIP_PASSWORD"],
      client_host: ENV["PEXIP_CLIENT_HOST"]
    )
  end
end
