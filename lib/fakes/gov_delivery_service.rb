# frozen_string_literal: true

class Fakes::GovDeliveryService
  def initialize(**args)
    @status_code = args[:status_code]
  end

  def create_webhook(*)
    return ExternalApi::GovDeliveryService::CreateResponse.new(HTTPI::Response.new(@status_code, {}, {})) if error?

    ExternalApi::GovDeliveryService::CreateResponse.new(HTTPI::Response.new(200, {}, {}))
  end

  def delete_webhook(*)
    return ExternalApi::GovDeliveryService::DeleteResponse.new(HTTPI::Response.new(@status_code, {}, {})) if error?

    ExternalApi::GovDeliveryService::DeleteResponse.new(HTTPI::Response.new(200, {}, {}))
  end

  def list_all_webhooks(*)
    return ExternalApi::GovDeliveryService::Response.new(HTTPI::Response.new(@status_code, {}, {})) if error?

    ExternalApi::GovDeliveryService::Response.new(HTTPI::Response.new(200, {}, {}))
  end

  private

  def error?
    [401, 403, 404, 500, 502, 503].include? @status_code
  end
end
