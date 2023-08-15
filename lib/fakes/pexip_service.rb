
# frozen_string_literal: true

class Fakes::PexipService
  def initialize(**args)
    @status_code = args[:status_code]
  end

  def create_conference(*)
    return ExternalApi::PexipService::CreateResponse.new(HTTPI::Response.new(@status_code, {}, {})) if error?

    ExternalApi::PexipService::CreateResponse.new(
      HTTPI::Response.new(201, { "Location" => "api/admin/configuration/v1/conference/9001" }, {})
    )
  end

  def delete_conference(*)
    return ExternalApi::PexipService::DeleteResponse.new(HTTPI::Response.new(@status_code, {}, {})) if error?

    ExternalApi::PexipService::DeleteResponse.new(HTTPI::Response.new(204, {}, {}))
  end

  private

  def error?
    [400, 404, 405, 501].include? @status_code
  end
end
