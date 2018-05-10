class AppealIntake < Intake
  def find_or_build_initial_detail
    TemporaryAppeal.new(veteran_file_number: veteran_file_number)
  end

  def ui_hash
    super.merge(
      receipt_date: detail.receipt_date,
      docket_type: detail.docket_type
    )
  end

  def review!(request_params)
    detail.update(request_params.permit(:receipt_date, :docket_type), context: :intake_review)
  end

  def review_errors
    detail.errors.messages
  end
end
