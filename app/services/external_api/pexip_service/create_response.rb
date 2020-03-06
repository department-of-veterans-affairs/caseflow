# frozen_string_literal: true

class ExternalApi::PexipService::CreateResponse < ExternalApi::PexipService::Response
  def data
    return if resp.headers["Location"].nil?

    { "conference_id": resp.headers["Location"].split("/")[-1].to_s }
  end
end
