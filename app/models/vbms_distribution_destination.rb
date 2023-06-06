# frozen_string_literal: true

class VbmsDistributionDestination < CaseflowRecord
  include MailRequestValidator::DistributionDestination

  belongs_to :vbms_distribution, optional: false
end
