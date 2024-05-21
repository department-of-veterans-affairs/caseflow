# frozen_string_literal: true

class ExternalApi::WebexService::RecordingsListResponse < ExternalApi::WebexService::Response
  def ids
    data.nil? ? [] : data["items"].pluck("id")
  end
end
