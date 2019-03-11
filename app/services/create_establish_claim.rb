# frozen_string_literal: true

# Service object used by Caseflow System Admins
# to manually create Establish Claims tasks
class CreateEstablishClaim
  include ActiveModel::Model

  DECISION_TYPES = ["Full Grant", "Partial Grant or Remand"].freeze

  ERROR_MESSAGES = {
    already_prepared: "A task already exists for this appeal.",
    missing_decision: "This appeal did not have a decision document in VBMS.",
    multiple_appeals: "There were multiple appeals matching this VBMS ID.",
    missing_decision_type: "You must select a decision type",
    invalid: "The appeal found is was not valid for claims establishment",
    appeal_not_found: "Appeal not found for that decision type." \
      "Make sure to add the 'S' or 'C' to the end of the file number.",
    default: "Something went wrong when creating the task."
  }.freeze

  attr_accessor :vbms_id, :decision_type

  def perform!
    perform_and_validate

    !@error_code
  end

  def error_message
    @error_code && (ERROR_MESSAGES[@error_code] || ERROR_MESSAGES[:default])
  end

  private

  def perform_and_validate
    return unless validate_decision_type

    @error_code = prepare_establish_claim unless prepare_establish_claim == :success
  rescue ActiveRecord::RecordNotFound
    @error_code = :appeal_not_found
  rescue Caseflow::Error::MultipleAppealsByVBMSID
    @error_code = :multiple_appeals
  end

  def prepare_establish_claim
    @prepare_establish_claim ||= establish_claim.prepare_with_decision!
  end

  def establish_claim
    @establish_claim ||= EstablishClaim.find_or_create_by(appeal: create_appeal)
  end

  def validate_decision_type
    unless DECISION_TYPES.include?(decision_type)
      @error_code = :missing_decision_type
    end

    !@error_code
  end

  def load_vacols_data_for(appeal)
    LegacyAppeal.repository.load_vacols_data_by_vbms_id(appeal: appeal, decision_type: decision_type)
  end

  def create_appeal
    appeal = LegacyAppeal.find_or_initialize_by(vbms_id: vbms_id)

    fail ActiveRecord::RecordNotFound unless load_vacols_data_for(appeal)

    appeal.save!

    appeal
  end
end
