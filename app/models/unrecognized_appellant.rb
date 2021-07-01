# frozen_string_literal: true

class UnrecognizedAppellant < CaseflowRecord
  include HasUnrecognizedPartyDetail

  belongs_to :claimant
  belongs_to :unrecognized_party_detail, dependent: :destroy
  belongs_to :unrecognized_power_of_attorney, class_name: "UnrecognizedPartyDetail", dependent: :destroy

  has_many :versions, class_name: "UnrecognizedAppellant", foreign_key: "current_version_id"
  belongs_to :current_version, class_name: "UnrecognizedAppellant"

  belongs_to :created_by, class_name: "User"

  def power_of_attorney
    @power_of_attorney ||= begin
      if poa_participant_id
        AttorneyPowerOfAttorney.new(poa_participant_id)
      elsif unrecognized_power_of_attorney_id
        UnrecognizedPowerOfAttorney.new(unrecognized_power_of_attorney)
      end
    end
  end

  # Returns the initially created unrecognized appellant. Returns itself if no other versions
  def first_version
    versions.where.not(id: current_version_id).first || self
  end

  def update_with_versioning!(params, user)
    transaction do
      create_version
      update(params.except(:unrecognized_party_detail).merge(created_by: user))
      unrecognized_party_detail.update(params[:unrecognized_party_detail])
    end
  rescue ActiveRecord::RecordInvalid
    false
  end

  private

  def create_version
    # Make a copy of self
    version = dup
    # Make a copy of self's unrecognized_party_detail
    version_party_detail = unrecognized_party_detail.dup
    # Point the copied self at the copy of unrecognized_party_detail and set current_version to self
    version.update(unrecognized_party_detail: version_party_detail, current_version: self)
  end
end
