# frozen_string_literal: true

##
# The Claimant model associates a claimant to a decision review.
# There are several subclasses, such as VeteranClaimant, DependentClaimant, and AttorneyClaimant.

class Claimant < CaseflowRecord
  include HasDecisionReviewUpdatedSince

  belongs_to :decision_review, polymorphic: true
  belongs_to :person, primary_key: :participant_id, foreign_key: :participant_id
  has_one :unrecognized_appellant, dependent: :destroy

  validates :participant_id,
            uniqueness: { scope: [:decision_review_id, :decision_review_type],
                          on: :create }

  delegate :date_of_birth,
           :advanced_on_docket?,
           :advanced_on_docket_based_on_age?,
           :advanced_on_docket_motion_granted?,
           :name,
           :first_name,
           :last_name,
           :middle_name,
           :email_address,
           to: :person
  delegate :address,
           :address_line_1,
           :address_line_2,
           :address_line_3,
           :city,
           :country,
           :state,
           :zip,
           to: :bgs_address_service
  delegate :representative_name,
           :representative_type,
           :representative_address,
           :representative_email_address,
           :poa_last_synced_at,
           to: :power_of_attorney,
           allow_nil: true

  def self.create_without_intake!(participant_id:, payee_code:, type:)
    create!(
      participant_id: participant_id,
      payee_code: payee_code,
      type: type
    )
    Person.find_or_create_by_participant_id(participant_id)
  end

  def power_of_attorney
    @power_of_attorney ||= find_power_of_attorney
  end

  def should_delete_power_of_attorney?
    return true if power_of_attorney && power_of_attorney.bgs_record == :not_found

    false
  end

  def representative_participant_id
    power_of_attorney&.participant_id
  end

  def person
    @person ||= Person.find_or_create_by_participant_id(participant_id)
  end

  private

  # to be overridden by any subclasses if a different approach is preferable
  def find_power_of_attorney
    BgsPowerOfAttorney.find_or_fetch_by(participant_id: participant_id)
  end

  def bgs_address_service
    @bgs_address_service ||= BgsAddressService.new(participant_id: participant_id)
  end
end
