# frozen_string_literal: true

class UnrecognizedPowerOfAttorney < CaseflowRecord
  include HasUnrecognizedEntityDetail

  has_one :unrecognized_appellant
end
