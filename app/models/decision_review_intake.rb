class DecisionReviewIntake < Intake
  def ui_hash(ama_enabled)
    super.merge(
      receipt_date: detail.receipt_date,
      claimant: detail.claimant_participant_id,
      veteran_is_not_claimant: detail.veteran_is_not_claimant,
      payeeCode: detail.payee_code,
      legacy_opt_in_approved: detail.legacy_opt_in_approved,
      legacyAppeals: detail.serialized_legacy_appeals,
      ratings: detail.serialized_ratings,
      requestIssues: detail.request_issues.map(&:ui_hash),
      activeNonratingRequestIssues: detail.active_nonrating_request_issues.map(&:ui_hash),
      contestableIssuesByDate: detail.contestable_issues.map(&:serialize)
    )
    rescue Rating::NilRatingProfileListError, Rating::LockedRatingError
      cancel!(reason: "system_error")
      raise
  end

  def cancel_detail!
    detail.remove_claimants!
    super
  end

  def review_errors
    detail.errors.messages
  end

  def complete!(request_params, &additional_transactions)
    return if complete? || pending?

    req_issues = request_params[:request_issues] || []
    transaction do
      start_completion!
      detail.request_issues.destroy_all unless detail.request_issues.empty?
      detail.create_issues!(build_issues(req_issues))
      additional_transactions.call
      complete_with_status!(:success)
    end
  end

  def build_issues(request_issues_data)
    request_issues_data.map { |data| detail.request_issues.from_intake_data(data) }
  end
end
