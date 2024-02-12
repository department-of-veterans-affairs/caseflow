# frozen_string_literal: true

class ExternalApi::WebexService::RecordingDetailsResponse < ExternalApi::WebexService::Response
  def data
    JSON.parse(resp.raw_body)
  end

  def download_links
    nil
  end
end
