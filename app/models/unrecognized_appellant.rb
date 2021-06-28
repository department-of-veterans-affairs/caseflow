# frozen_string_literal: true

class UnrecognizedAppellant < CaseflowRecord
  include HasUnrecognizedPartyDetail

  belongs_to :claimant
  belongs_to :unrecognized_party_detail, dependent: :destroy
  belongs_to :unrecognized_power_of_attorney, class_name: "UnrecognizedPartyDetail", dependent: :destroy

  has_many :versions, class_name: "UnrecognizedAppellant", foreign_key: "current_version_id"
  belongs_to :current_version, class_name: "UnrecognizedAppellant", optional: true

  belongs_to :created_by, class_name: "User", optional: true

  def power_of_attorney
    @power_of_attorney ||= begin
      if poa_participant_id
        AttorneyPowerOfAttorney.new(poa_participant_id)
      elsif unrecognized_power_of_attorney_id
        UnrecognizedPowerOfAttorney.new(unrecognized_power_of_attorney)
      end
    end
  end

  def original_version
    versions.where.not(id: current_version_id).first || self
  end
end
