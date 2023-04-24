# frozen_string_literal: true

class VbmsDistrobution < CaseflowRecord
  belongs_to :vbms_communication_package
  has_many :vbms_distribution_destinations
end
