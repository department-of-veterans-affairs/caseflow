# frozen_string_literal: true

class UnrecognizedAppellant < CaseflowRecord
  include HasUnrecognizedPartyDetail

  belongs_to :claimant
  belongs_to :unrecognized_party_detail, dependent: :destroy
  belongs_to :unrecognized_power_of_attorney, class_name: "UnrecognizedPartyDetail", dependent: :destroy
  belongs_to :not_listed_power_of_attorney, dependent: :destroy

  has_many :versions, class_name: "UnrecognizedAppellant", foreign_key: "current_version_id"
  belongs_to :current_version, class_name: "UnrecognizedAppellant"

  belongs_to :created_by, class_name: "User"

  def power_of_attorney
    @power_of_attorney ||= begin
      if poa_participant_id
        AttorneyPowerOfAttorney.new(poa_participant_id)
      elsif unrecognized_power_of_attorney_id
        UnrecognizedPowerOfAttorney.new(unrecognized_power_of_attorney)
      elsif not_listed_power_of_attorney_id
        not_listed_power_of_attorney
      end
    end
  end

  # Returns the initially created unrecognized appellant. Returns itself if no other versions
  def first_version
    versions.where.not(id: current_version_id).first || self
  end

  def set_current_version_to_self!
    update!(current_version: self)
    self
  end

  def copy_with_details(updated_claimant: claimant)
    dup.tap do |appellant|
      appellant.claimant = updated_claimant
      new_party_detail = unrecognized_party_detail.dup
      appellant.unrecognized_party_detail = new_party_detail
      appellant.save
    end
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

  def update_power_of_attorney!(params)
    poa_participant_id = params[:poa_participant_id]
    if poa_participant_id
      update(poa_participant_id: poa_participant_id)
    else
      update(unrecognized_power_of_attorney: UnrecognizedPartyDetail.new(params[:unrecognized_power_of_attorney]))
    end
  end

  private

  def create_version
    # Make a copy of self
    version = copy_with_details
    # Point the copied self at the copy of unrecognized_party_detail and set current_version to self
    version.update(current_version: self)
  end
end
