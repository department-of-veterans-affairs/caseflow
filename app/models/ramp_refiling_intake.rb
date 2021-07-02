# frozen_string_literal: true

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

  def review!(request_params, _current_user)
    detail.start_review!
    detail.update(request_params.permit(:receipt_date, :option_selected, :appeal_docket))
  end

  def save_error!(code:)
    self.error_code = code
    transaction do
      detail.try(:destroy!)
      complete_with_status!(:error)
    end
  end

  def complete!(request_params)
    return if complete? || pending?

    start_completion!

    detail.update!(
      establishment_submitted_at: Time.zone.now,
      has_ineligible_issue: request_params[:has_ineligible_issue]
    )
    detail.create_issues!(source_issue_ids: request_params[:issue_ids] || [])

    create_end_product_and_contentions
    complete_with_status!(:success)

    detail.update!(established_at: Time.zone.now) unless detail.established_at
  rescue StandardError => error
    abort_completion!
    raise error
  end

  def review_errors
    detail.errors.messages
  end

  def ramp_elections_with_decisions
    ramp_elections.reject(&:end_product_active?)
  end

  def ui_hash
    Intake::RampRefilingIntakeSerializer.new(self).serializable_hash[:data][:attributes]
  end

  private

  def create_end_product_and_contentions
    if detail.needs_end_product?
      detail.create_end_product_and_contentions!
    else
      detail.update!(establishment_processed_at: Time.zone.now)
    end
  end

  def validate_detail_on_start
    if !veteran.valid?(:bgs)
      self.error_code = :veteran_not_valid
      @error_data = veteran_invalid_fields
    elsif ramp_elections.empty?
      self.error_code = :no_complete_ramp_election
    elsif ramp_elections.all?(&:end_product_active?)
      self.error_code = :ramp_election_is_active
    elsif ramp_elections.all? { |election| election.issues.empty? }
      self.error_code = :ramp_election_no_issues
    elsif ramp_refiling_already_processed?
      # For now caseflow does not support processing the multiple ramp refilings
      # for the same veteran, unless previous ones have been cancelled
      self.error_code = :ramp_refiling_already_processed
    end
  end

  def ramp_refiling_already_processed?
    duplicate_refilings = RampRefiling.where(veteran_file_number: veteran_file_number)
    end_product_establishments = duplicate_refilings.map(&:end_product_establishment)
    end_product_establishments.present? && !end_product_establishments.all?(&:status_cancelled?)
  end

  def find_or_build_initial_detail
    initial_ramp_refiling
  end

  def initial_ramp_refiling
    @initial_ramp_refiling ||= RampRefiling.new(
      veteran_file_number: veteran_file_number
    )
  end

  def ramp_elections
    RampElection.established.where(veteran_file_number: veteran_file_number).all
  end
end
