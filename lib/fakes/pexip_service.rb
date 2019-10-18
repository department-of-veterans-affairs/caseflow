# frozen_string_literal: true

class Fakes::PexipService < ExternalApi::PexipService
  def initialize(*); end

  def create_conference(**args)
    return ExternalApi::PexipService::CreateResponse.new(HTTPI::Response.new(400, {}, {})) if args[:error]

    { "conference_id": "9001" }
  end

  def delete_conference(**args)
    ExternalApi::PexipService::DeleteResponse.new(HTTPI::Response.new(404, {}, {})) if args[:error]
  end
end
