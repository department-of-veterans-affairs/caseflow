# frozen_string_literal: true

class ExternalApi::WebexService::RecordingsListResponse < ExternalApi::WebexService::Response
  def data
    JSON.parse(resp.raw_body)
  end

  def ids
    data["items"].pluck("id")
  end
end
