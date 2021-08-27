# frozen_string_literal: true

class Fakes::GovDeliveryService
  def self.get_recipients_from_event(*)
    ExternalApi::GovDeliveryService::Response.new(HTTPI::Response.new(200, {}, {}))
  end
end
