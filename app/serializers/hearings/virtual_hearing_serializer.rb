# frozen_string_literal: true

class VirtualHearingSerializer
  include FastJsonapi::ObjectSerializer

  attribute :veteran_email
  attribute :representative_email
  attribute :status
end
