class RampRefilingIntake < Intake
  class TooManyCompletedRampElections < StandardError; end

  enum error_code: {
    no_complete_ramp_election: "no_complete_ramp_election",
    ramp_election_is_active: "ramp_election_is_active",
    ramp_election_no_issues: "ramp_election_no_issues"
  }.merge(Intake::ERROR_CODES)

  def preload_intake_data!
    ramp_election && ramp_election.recreate_issues_from_contentions!
  end

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

  def complete!(request_params)
    detail.create_issues!(source_issue_ids: request_params[:issue_ids])
    detail.update!(has_ineligible_issue: request_params[:has_ineligible_issue])

    detail.create_end_product_and_contentions! if detail.needs_end_product?

    complete_with_status!(:success)
  end

  def review_errors
    detail.errors.messages
  end

  def ui_hash
    super.merge(
      option_selected: detail.option_selected,
      receipt_date: detail.receipt_date,
      election_receipt_date: detail.election_receipt_date,
      issues: ramp_election.issues.map(&:ui_hash)
    )
  end

  private

  def validate_detail_on_start
    if !ramp_election
      self.error_code = :no_complete_ramp_election
    elsif ramp_election.established_end_product.active?
      self.error_code = :ramp_election_is_active
    elsif ramp_election.issues.empty?
      self.error_code = :ramp_election_no_issues
    end
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

  def ramp_election
    initial_ramp_refiling.ramp_election
  end

  def fetch_ramp_election
    ramp_elections = RampElection.completed.where(veteran_file_number: veteran_file_number).all

    # There should only be one RAMP election sent to each veteran
    # if there was more than one, raise an error so we know about it
    fail TooManyCompletedRampElections if ramp_elections.length > 1

    ramp_elections.first
  end
end
