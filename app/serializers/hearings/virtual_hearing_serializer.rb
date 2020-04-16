# frozen_string_literal: true

class VirtualHearingSerializer
  include FastJsonapi::ObjectSerializer

  attribute :veteran_email
  attribute :representative_email
  attribute :status
  attribute :client_host do
    ENV["PEXIP_CLIENT_HOST"] || "care.evn.va.gov"
  end
  attribute :alias
  attribute :host_pin
  attribute :guest_pin
  attribute :job_completed, &:job_completed?
end
