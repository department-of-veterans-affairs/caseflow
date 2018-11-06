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
      payee_code: nil
    )
    detail.assign_attributes(request_params.permit(:receipt_date, :docket_type, :legacy_opt_in_approved))
    detail.save(context: :intake_review)
  end

  def complete!(request_params)
    super(request_params) do
      detail.update!(established_at: Time.zone.now)
      detail.create_tasks_on_intake_success!
    end
  end
end
