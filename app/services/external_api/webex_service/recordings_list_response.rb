# frozen_string_literal: true

class ExternalApi::WebexService::RecordingsListResponse < ExternalApi::WebexService::Response
  def ids
    data["items"].pluck("id")
  end

  def topics
    data["items"].pluck("topic")
  end
end
