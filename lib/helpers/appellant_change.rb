# frozen_string_literal: true

# This is a method for changing the Claimant on an Appeal by taking in the Appeal UUID
# and atrributes of the proposed claimant substitution to create a new Claimant object
# for the appeal

# Disable :reek:InstanceVariableAssumption
# Disable :reek:TooManyInstanceVariables
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
    @appeal_uuid = kwargs[:appeal_uuid]
    @claimant_participant_id = kwargs[:claimant_participant_id]
    @claimant_type = kwargs[:claimant_type]
    @claimant_payee_code = kwargs[:claimant_payee_code]
  end

  def run_appellant_change
    RequestStore[:current_user] = User.system_user

    unless appeal
      puts "Appeal not found for UUID"
      return
    end

    unless claimant_type_valid?
      puts "Invalid claimant type"
      return
    end

    begin
      change_appellant!
    rescue StandardError => error
      puts error.message
      puts "\n\n"
      puts "An error occurred. Appeal claimant not changed."
    end
  end

  def appeal
    return @appeal if defined?(@appeal)

    @appeal = Appeal.find_by(uuid: @appeal_uuid)
  end

  def claimant_type_valid?
    VALID_CLAIMANT_TYPES.include?(@claimant_type)
  end

  def change_appellant!
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
  end
end
