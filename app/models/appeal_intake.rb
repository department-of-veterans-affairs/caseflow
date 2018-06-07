class AppealIntake < Intake
  def find_or_build_initial_detail
    Appeal.new(veteran_file_number: veteran_file_number)
  end

  def ui_hash
    super.merge(
      receipt_date: detail.receipt_date,
      docket_type: detail.docket_type,
      ratings: veteran.cached_serialized_timely_ratings
    )
  end

  def cancel_detail!
    detail.remove_claimants!
    super
  end

  def review!(request_params)
    detail.assign_attributes(request_params.permit(:receipt_date, :docket_type))
    detail.save(context: :intake_review)
    detail.create_claimants!(claimant_data: request_params[:claimant] || veteran.participant_id)
  end

  def review_errors
    detail.errors.messages
  end

  def complete!(request_params)
    return if complete? || pending?
    start_completion!

    detail.create_issues!(request_issues_data: request_params[:request_issues] || [])
    detail.update!(established_at: Time.zone.now)
    complete_with_status!(:success)
  end
end
