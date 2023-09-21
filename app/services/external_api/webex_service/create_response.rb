# frozen_string_literal: true

class ExternalApi::PexipService::CreateResponse < ExternalApi::PexipService::Response
  def data
    fail NotImplementedError
  end
end
