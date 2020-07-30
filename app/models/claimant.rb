# frozen_string_literal: true

##
# The Claimant model associates a claimant to a decision review.

class Claimant < CaseflowRecord
  include HasDecisionReviewUpdatedSince

  belongs_to :decision_review, polymorphic: true
  belongs_to :person, primary_key: :participant_id, foreign_key: :participant_id

  validates :participant_id,
            uniqueness: { scope: [:decision_review_id, :decision_review_type],
                          on: :create }

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

  delegate :representative_name,
           :representative_type,
           :representative_address,
           :representative_email_address,
           to: :power_of_attorney,
           allow_nil: true


end
