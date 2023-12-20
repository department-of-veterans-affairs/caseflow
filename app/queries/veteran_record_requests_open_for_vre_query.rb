# frozen_string_literal: true

class VeteranRecordRequestsOpenForVREQuery
  # @return [ActiveRecord::Relation] VeteranRecordRequest tasks that are
  #   both open and assigned to the 'Veterans Readiness and Employment' business
  #   line (f.k.a 'Vocational Rehabilitation and Employment')
  def self.call
    vre_business_line =
      BusinessLine.where(name: Constants::BENEFIT_TYPES["voc_rehab"])

    VeteranRecordRequest.open.where(assigned_to: vre_business_line)
  end
end
