# frozen_string_literal: true

class VeteranRecordRequestsOpenForVREQuery
  VRE_BUSINESS_LINE_NAME = "Veterans Readiness and Employment"

  # @return [ActiveRecord::Relation] VeteranRecordRequest tasks that are
  #   both open and assigned to the 'Veterans Readiness and Employment' business
  #   line (f.k.a 'Vocational Rehabilitation and Employment')
  def self.call
    vre_business_line = BusinessLine.where(name: VRE_BUSINESS_LINE_NAME)
    VeteranRecordRequest.open.where(assigned_to: vre_business_line)
  end
end
