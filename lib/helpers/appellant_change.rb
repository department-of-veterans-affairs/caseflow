# frozen_string_literal: true

class AppellantChange
  VALID_CLAIMANT_TYPES = %w[
    VeteranClaimant
    DependentClaimant
    AttorneyClaimant
  ].freeze

  def self.run_appellant_change(**kwargs)
    new(kwargs).__send__(:run_appellant_change)
  end

  private

  def initialize(**kwargs)
    @@appeal_uuid = kwargs[:appeal_uuid]
    @claimant_participant_id = kwargs[:claimant_participant_id]
    @claimant_type = kwargs[:claimant_type]
    @claimant_payee_code = kwargs[:claimant_payee_code]
  end

  def run_appellant_change(**kwargs)
    RequestStore[:current_user] = User.system_user

    unless (appeal = Appeal.find_by(uuid: @appeal_uuid))
      puts "Appeal not found for UUID"
      return
    end

    unless VALID_CLAIMANT_TYPES.include?(@claimant_type)
      puts "Invalid claimant type"
      return
    end

    begin
      ActiveRecord::Base.transaction do
        appeal.claimant&.destroy!
        appeal.update!(veteran_is_not_claimant: @claimant_type != "VeteranClaimant")

        Claimant.create!(
          participant_id: @claimant_participant_id,
          payee_code: @claimant_payee_code,
          type: @claimant_type,
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
