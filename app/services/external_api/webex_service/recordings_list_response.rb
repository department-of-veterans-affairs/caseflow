# frozen_string_literal: true

class ExternalApi::WebexService::RecordingsListResponse < ExternalApi::WebexService::Response
  def ids
    data["items"].blank? ? [] : data["items"].pluck("id")
  end
end
