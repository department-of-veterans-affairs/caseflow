# frozen_string_literal: true

class VbmsDistribution < CaseflowRecord
  has_one :vbms_communication_package
  has_one :vbms_distribution_destination
end
