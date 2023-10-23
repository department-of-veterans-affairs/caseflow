# frozen_string_literal: true

class ExternalApi::WebexService::CreateResponse < ExternalApi::WebexService::Response
  def data
    # resp.raw_body
    if !resp.body? nil
      response = JSON.parse(resp.body)
      { "conference_id": response.first.last }
    end
  end
end
