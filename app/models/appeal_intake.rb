class AppealIntake < DecisionReviewIntake
  def find_or_build_initial_detail
    Appeal.new(veteran_file_number: veteran_file_number)
  end

  def ui_hash(ama_enabled)
    super.merge(docket_type: detail.docket_type)
  end

  def review!(request_params)
    detail.create_claimants!(
      participant_id: request_params[:claimant] || veteran.participant_id,
      payee_code: request_params[:payee_code] || "00"
    )
    detail.assign_attributes(request_params.permit(:receipt_date, :docket_type, :legacy_opt_in_approved))
    detail.save(context: :intake_review)
  end

  def complete!(request_params)
    return if complete? || pending?
    start_completion!

    detail.create_issues!(request_issues_data: request_params[:request_issues] || [])
    detail.update!(established_at: Time.zone.now)
    detail.create_tasks_on_intake_success!
    complete_with_status!(:success)
  end
end
