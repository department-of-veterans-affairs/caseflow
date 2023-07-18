# frozen_string_literal: true

class VbmsDistribution < CaseflowRecord
  include MailRequestValidator::Distribution

  belongs_to :vbms_communication_package
  has_many :vbms_distribution_destinations
end
