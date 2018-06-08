class RampRefilingIntake < Intake
  class TooManyCompletedRampElections < StandardError; end

  enum error_code: {
    no_complete_ramp_election: "no_complete_ramp_election",
    ramp_election_is_active: "ramp_election_is_active",
    ramp_election_no_issues: "ramp_election_no_issues",
    ramp_refiling_already_processed: "ramp_refiling_already_processed",
    ineligible_for_higher_level_review: "ineligible_for_higher_level_review"
  }.merge(Intake::ERROR_CODES)

  def preload_intake_data!
    ramp_elections.map(&:recreate_issues_from_contentions!)
  end

  def review!(request_params)
    detail.start_review!
    detail.update_attributes(request_params.permit(:receipt_date, :option_selected, :appeal_docket))
  end

  def save_error!(code:)
    self.error_code = code
    transaction do
      detail.destroy!
      complete_with_status!(:error)
    end
  end

  def complete!(request_params)
    return if complete? || pending?
    start_completion!

    detail.create_issues!(source_issue_ids: request_params[:issue_ids] || [])
    detail.update!(has_ineligible_issue: request_params[:has_ineligible_issue])

    create_end_product_and_contentions

    complete_with_status!(:success)
    detail.update!(established_at: Time.zone.now) unless detail.established_at
  end

  def review_errors
    detail.errors.messages
  end

  def ui_hash
    super.merge(
      option_selected: detail.option_selected,
      receipt_date: detail.receipt_date,
      election_receipt_date: detail.election_receipt_date,
      appeal_docket: detail.appeal_docket,
      issues: ramp_elections.map(&:issues).flatten.map(&:ui_hash),
      end_product_description: detail.end_product_description
    )
  end

  private

  def create_end_product_and_contentions
    detail.create_end_product_and_contentions! if detail.needs_end_product?
  rescue StandardError => e
    abort_completion!
    raise e
  end

  def validate_detail_on_start
    if ramp_elections.empty?
      self.error_code = :no_complete_ramp_election
    elsif ramp_elections.any?(&:end_product_active?)
      self.error_code = :ramp_election_is_active
    elsif ramp_elections.all? { |election| election.issues.empty? }
      self.error_code = :ramp_election_no_issues
    elsif ramp_refiling_already_processed?
      # For now caseflow does not support processing the multiple ramp refilings
      # for the same veteran
      self.error_code = :ramp_refiling_already_processed
    end
  end

  def ramp_refiling_already_processed?
    !RampRefiling.where(veteran_file_number: veteran_file_number).empty?
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

  def ramp_elections
    RampElection.established.where(veteran_file_number: veteran_file_number).all
  end

  def fetch_ramp_election
    ramp_elections = RampElection.established.where(veteran_file_number: veteran_file_number).all

    # There should only be one RAMP election sent to each veteran
    # if there was more than one, raise an error so we know about it
    fail TooManyCompletedRampElections if ramp_elections.length > 1

    ramp_elections.first
  end
end
