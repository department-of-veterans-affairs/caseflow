# Service object used by Caseflow System Admins
# to manually create Establish Claims tasks
class CreateEstablishClaim
  include ActiveModel::Model

  DECISION_TYPES = ["Full Grant", "Partial Grant or Remand"].freeze

  attr_accessor :vbms_id, :decision_type
  attr_accessor :error_message

  def perform!
    perform_create_establish_claim

    !error_message
  end

  private

  def perform_create_establish_claim
    return unless validate_decision_type
    return unless validate_establish_claim

    establish_claim.prepare!

  rescue MultipleAppealsByVBMSIDError
    @error_message = "There were multiple appeals matching this VBMS ID."
  rescue ActiveRecord::RecordNotFound
    @error_message = "Appeal not found for that decision type." \
      "Make sure to add the 'S' or 'C' to the end of the file number."
  end

  def validate_establish_claim
    if !establish_claim.may_prepare?
      @error_message = "A task already exists for this appeal."
    elsif establish_claim.appeal.decisions.empty?
      @error_message = "This appeal did not have a decision document in VBMS."
    end

    !error_message
  end

  def establish_claim
    @establish_claim ||= EstablishClaim.find_or_create_by(appeal: create_appeal)
  end

  def validate_decision_type
    unless DECISION_TYPES.include?(decision_type)
      @error_message = "You must select a decision type"
    end

    !error_message
  end

  def create_appeal
    appeal = Appeal.find_or_initialize_by(vbms_id: vbms_id)
    Appeal.repository.load_vacols_data_by_vbms_id(appeal: appeal, decision_type: decision_type)
    appeal.save!

    appeal
  end
end
