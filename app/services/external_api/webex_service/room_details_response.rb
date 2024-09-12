# frozen_string_literal: true

class ExternalApi::WebexService::RoomDetailsResponse < ExternalApi::WebexService::Response
  def meeting_id
    data["meetingId"]
  end
end
