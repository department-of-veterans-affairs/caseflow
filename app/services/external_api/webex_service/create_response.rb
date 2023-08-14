# frozen_string_literal: true

class ExternalApi::WebexService::CreateResponse < ExternalApi::WebexService::Response
  def data
    return if resp.headers["Location"].nil?

    { "conference_id": resp.headers["Location"].split("/")[-1].to_s }
  end
end
