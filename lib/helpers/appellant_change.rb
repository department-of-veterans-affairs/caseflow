# frozen_string_literal: true

class AppellantChange
  VALID_CLAIMANT_TYPES = %w[
    VeteranClaimant
    DependentClaimant
    AttorneyClaimant
  ].freeze

  def initialize
    @errors = []
  end

  def run_appellant_change(appeal_uuid:, claimant_participant_id:, claimant_type:, claimant_payee_code:)
    RequestStore[:current_user] = User.system_user

    unless appeal = Appeal.find_by(uuid: appeal_uuid)
      puts "Appeal not found for UUID"
      return
    end

    unless VALID_CLAIMANT_TYPES.include?(claimant_type)
      puts "Invalid claimant type"
      return
    end

    begin
      ActiveRecord::Base.transaction do
        appeal.claimant&.destroy!
        appeal.update!(veteran_is_not_claimant: claimant_type != "VeteranClaimant")

        Claimant.create!(
          participant_id: claimant_participant_id,
          payee_code: claimant_payee_code,
          type: claimant_type,
          decision_review_id: appeal.id,
          decision_review_type: "Appeal"
        )
      end
    rescue StandardError => error
      puts error.message
      puts "\n\n"
      puts "An error occurred. Appeal claimant not changed."
    end
  end
end
