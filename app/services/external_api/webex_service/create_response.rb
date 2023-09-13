# frozen_string_literal: true

class ExternalApi::WebexService::CreateResponse < ExternalApi::WebexService::Response
  def data
    if !response.body? nil
      response = JSON.parse(resp.body)
      { "conference_id": response.first.last }
    end
  end
end
