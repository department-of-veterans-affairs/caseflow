# frozen_string_literal: true

class DecisionReviewIntake < Intake
  include RunAsyncable

  def ui_hash
    Intake::DecisionReviewIntakeSerializer.new(self).serializable_hash[:data][:attributes]
  rescue Rating::NilRatingProfileListError, PromulgatedRating::LockedRatingError
    cancel!(reason: "system_error")
    raise
  end

  def cancel_detail!
    detail&.remove_claimants!
    super
  end

  def review_errors
    detail.errors.messages
  end

  def complete!(request_params)
    return if complete? || pending?

    req_issues = request_params[:request_issues] || []
    transaction do
      start_completion!
      detail.request_issues.destroy_all unless detail.request_issues.empty?
      detail.create_issues!(build_issues(req_issues))
      yield
      complete_with_status!(:success)
    end
  end

  def build_issues(request_issues_data)
    request_issues_data.map { |data| RequestIssue.from_intake_data(data, decision_review: detail) }
  end

  private

  def create_claimant!
    # Existing claimant can be changed in any way, including their class type. Destroying and
    # re-creating ensures that associated records get cleaned up and the correct validations run.
    Claimant.find_by(decision_review: detail)&.destroy!

    claimant = claimant_class_name.constantize.create!(
      decision_review: detail,
      participant_id: participant_id,
      payee_code: (need_payee_code? ? request_params[:payee_code] : nil)
    )

    if claimant.is_a?(OtherClaimant)
      claimant.save_unrecognized_details!(
        request_params[:unlisted_claimant],
        request_params[:poa],
        current_user
      )
    end
    update_person!
  end

  # :nocov:
  def need_payee_code?
    fail Caseflow::Error::MustImplementInSubclass
  end
  # :nocov:

  def set_review_errors
    fetch_claimant_errors
    detail.validate
    set_claimant_errors
    false
    # we just swallow the exception otherwise, since we want the validation errors to return to client
  end

  def fetch_claimant_errors
    payee_code_error
    claimant_required_error
    claimant_address_error
  end

  def set_claimant_errors
    detail.errors[:payee_code] << payee_code_error if payee_code_error
    detail.errors[:claimant] << claimant_required_error if claimant_required_error
    detail.errors[:claimant] << claimant_address_error if claimant_address_error
  end

  def claimant_address_error
    @claimant_address_error ||= [
      ClaimantValidator::ERRORS[:claimant_address_required],
      ClaimantValidator::ERRORS[:claimant_address_invalid],
      ClaimantValidator::ERRORS[:claimant_address_city_invalid]
    ].find do |error|
      detail.errors.messages[:claimant].include?(error)
    end
  end

  def claimant_required_error
    @claimant_required_error ||=
      detail.errors.messages[:veteran_is_not_claimant].include?(
        ClaimantValidator::ERRORS[:claimant_required]
      ) && ClaimantValidator::ERRORS[:blank]
  end

  def payee_code_error
    @payee_code_error ||=
      detail.errors.messages[:benefit_type].include?(
        ClaimantValidator::ERRORS[:payee_code_required]
      ) && ClaimantValidator::ERRORS[:blank]
  end

  # run during start!
  def after_validated_pre_start!
    epes = EndProductEstablishment.established.where(veteran_file_number: veteran.file_number)
    epes.each do |epe|
      epe.sync!
    rescue EndProductEstablishment::EstablishedEndProductNotFound => error
      Raven.capture_exception(error: error)
      next
    end
  end

  def claimant_class_name
    "#{request_params[:claimant_type]&.capitalize}Claimant"
  end

  def veteran_is_not_claimant
    claimant_class_name != "VeteranClaimant"
  end

  # If user has specified a different claimant, use that
  # Otherwise we use the veteran's participant_id, even for OtherClaimant
  def participant_id
    if %w[VeteranClaimant OtherClaimant].include? claimant_class_name
      veteran.participant_id
    else
      request_params[:claimant]
    end
  end

  # :nocov:
  def review_param_keys
    fail Caseflow::Error::MustImplementInSubclass
  end
  # :nocov:

  def review_params
    params = request_params.permit(*review_param_keys)
    params[:veteran_is_not_claimant] = veteran_is_not_claimant
    params
  end
end
