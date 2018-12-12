class AppealIntake < DecisionReviewIntake
  attr_reader :request_params

  def find_or_build_initial_detail
    Appeal.new(veteran_file_number: veteran_file_number)
  end

  def ui_hash(ama_enabled)
    super.merge(docket_type: detail.docket_type)
  end

  def review!(request_params)
    @request_params = request_params

    transaction do
      detail.assign_attributes(review_params)
      Claimant.create!(
        participant_id: claimant_participant_id,
        payee_code: nil,
        review_request: detail
      )
      update_person!
      detail.save(context: :intake_review)
    end
  rescue ActiveRecord::RecordInvalid => _err
    # propagate the error from invalid column to the user-visible reason
    if detail.errors.messages[:veteran_is_not_claimant].include?(ClaimantValidator::CLAIMANT_REQUIRED)
      claimant_error = ClaimantValidator::BLANK
    end

    detail.validate
    detail.errors[:claimant] << claimant_error if claimant_error
    return false
  end

  def complete!(request_params)
    super(request_params) do
      detail.update!(established_at: Time.zone.now)
      detail.create_tasks_on_intake_success!
    end
  end

  private

  def claimant_participant_id
    (request_params[:veteran_is_not_claimant] == true) ? request_params[:claimant] : veteran.participant_id
  end

  def review_params
    request_params.permit(
      :receipt_date,
      :docket_type,
      :veteran_is_not_claimant,
      :legacy_opt_in_approved
    )
  end
end
