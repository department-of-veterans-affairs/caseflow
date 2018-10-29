class DecisionReviewIntake < Intake
  def ui_hash(ama_enabled)
    super.merge(
      receipt_date: detail.receipt_date,
      claimant: detail.claimant_participant_id,
      claimant_not_veteran: detail.claimant_not_veteran,
      payee_code: detail.payee_code,
      legacy_opt_in_approved: detail.legacy_opt_in_approved,
      ratings: detail.serialized_ratings,
      requestIssues: detail.request_issues.map(&:ui_hash)
    )
  end

  def find_or_build_initial_detail
    fail Caseflow::Error::MustImplementInSubclass
  end

  def cancel_detail!
    detail.remove_claimants!
    super
  end

  def review_errors
    detail.errors.messages
  end
end
