class RampRefilingIntake < Intake
  class TooManyCompletedRampElections < StandardError; end

  enum error_code: {
    no_complete_ramp_election: "no_complete_ramp_election"
  }.merge(Intake::ERROR_CODES)

  def cancel!
    transaction do
      detail.destroy!
      complete_with_status!(:canceled)
    end
  end

  def review!(request_params)
    detail.start_review!
    detail.update_attributes(request_params.permit(:receipt_date, :option_selected))
  end

  def review_errors
    detail.errors.messages
  end

  def ui_hash
    super.merge(
      option_selected: detail.option_selected,
      receipt_date: detail.receipt_date
    )
  end

  private

  def validate_detail_on_start
    return true if initial_ramp_refiling.ramp_election

    self.error_code = :no_complete_ramp_election
  end

  def find_or_build_initial_detail
    initial_ramp_refiling
  end

  def initial_ramp_refiling
    @initial_ramp_refiling ||= RampRefiling.new(
      veteran_file_number: veteran_file_number,
      ramp_election: fetch_ramp_election
    )
  end

  def fetch_ramp_election
    ramp_elections = RampElection.completed.where(veteran_file_number: veteran_file_number).all

    # There should only be one RAMP election sent to each veteran
    # if there was more than one, raise an error so we know about it
    fail TooManyCompletedRampElections if ramp_elections.length > 1

    ramp_elections.first
  end
end
