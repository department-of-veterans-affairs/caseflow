# frozen_string_literal: true

class VirtualHearingSerializer
  include FastJsonapi::ObjectSerializer

  attribute :appellant_tz
  attribute :representative_tz
  attribute :appellant_email
  attribute :representative_email
  attribute :status
  attribute :request_cancelled
  attribute :alias_with_host, &:formatted_alias_or_alias_with_host
  attribute :host_pin
  attribute :guest_pin
  attribute :host_link, &:host_link
  attribute :guest_link, &:guest_link
  attribute :job_completed, &:job_completed?
end
