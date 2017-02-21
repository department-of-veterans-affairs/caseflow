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
    establish_claim = EstablishClaim.find_or_create_by(appeal: create_appeal)

    # Admin has to confirm appeal has a decision document
    if establish_claim.may_prepare?
      establish_claim.prepare!
    else
      @error_message = "This appeal did not have a decision document in VBMS."
    end

  rescue MultipleAppealsByVBMSIDError
    @error_message = "There were multiple appeals matching this VBMS ID."
  rescue ActiveRecord::RecordNotFound
    @error_message = "Appeal not found for that decision type." \
      "Make sure to add the 'S' or 'C' to the end of the file number."
  rescue UnrecognizedDecisionTypeError
    @error_message = "You must select a decision type"
  end

  def create_appeal
    appeal = Appeal.find_or_initialize_by(vbms_id: vbms_id)
    Appeal.repository.load_vacols_data_by_vbms_id(appeal: appeal, decision_type: decision_type)
    appeal.save!

    appeal
  end
end
