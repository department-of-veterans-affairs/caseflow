# frozen_string_literal: true

class DecisionReviewIntake < Intake
  include RunAsyncable

  def ui_hash
    super.merge(
      receipt_date: detail.receipt_date,
      claimant: detail.claimant_participant_id,
      veteran_is_not_claimant: detail.veteran_is_not_claimant,
      payeeCode: detail.payee_code,
      legacy_opt_in_approved: detail.legacy_opt_in_approved,
      legacyAppeals: detail.serialized_legacy_appeals,
      ratings: detail.serialized_ratings,
      requestIssues: detail.request_issues.active_or_ineligible.map(&:serialize),
      activeNonratingRequestIssues: detail.active_nonrating_request_issues.map(&:serialize),
      contestableIssuesByDate: detail.contestable_issues.map(&:serialize),
      veteranValid: veteran&.valid?(:bgs),
      veteranInvalidFields: veteran_invalid_fields
    )
  rescue Rating::NilRatingProfileListError, Rating::LockedRatingError
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
      epe.veteran = veteran
      epe.sync!
    end
  end
end
