# frozen_string_literal: true

class RampElectionIntake < Intake
  include CachedAttributes

  enum error_code: {
    did_not_receive_ramp_election: "did_not_receive_ramp_election",
    no_eligible_appeals: "no_eligible_appeals",
    no_active_compensation_appeals: "no_active_compensation_appeals",
    no_active_appeals: "no_active_appeals",
    # This is a legacy error_code from when we only allowed one RAMP election
    ramp_election_already_complete: "ramp_election_already_complete",
    # This is a legacy error_code from when we did not allow RAMP elections on mixed comp/non-comp appeals
    no_active_fully_compensation_appeals: "no_active_fully_compensation_appeals",
    # This status will be set on successful intakes to signify that we had to
    # connect an existing EP, which in theory, shouldn't happen, but does in practice.
    connected_preexisting_ep: "connected_preexisting_ep"
  }.merge(Intake::ERROR_CODES)

  def ramp_election
    detail
  end

  def find_or_build_initial_detail
    # This is temporary if there are already ramp elections.
    # It will NOT find existing ramp elections since we can't compare type as we
    # don't know it yet. Later we will switch to existing matching elections.
    new_intake_ramp_election
  end

  def review!(request_params, _current_user = nil)
    ramp_election.start_review!
    ramp_election.update(request_params.permit(:receipt_date, :option_selected))
  end

  def review_errors
    ramp_election.errors.messages
  end

  def complete!(_request_params)
    return if complete? || pending?

    start_completion!

    if existing_ramp_election_active?
      use_existing_ramp_election
    else
      create_or_connect_end_product
    end

    transaction do
      complete_with_status!(:success)
      create_ramp_closed_appeals!
    end

    @ramp_closed_appeals.each(&:close!)
  end

  def cancel_detail!
    detail.update!(
      receipt_date: nil,
      option_selected: nil
    )
  end

  cache_attribute :cached_serialized_appeal_issues, expires_in: 10.minutes do
    serialized_appeal_issues
  end

  def serialized_appeal_issues
    eligible_appeals.map do |appeal|
      {
        id: appeal.id,
        issues: appeal.compensation_issues.map(&:description_attributes)
      }
    end
  end

  def ui_hash
    Intake::RampElectionIntakeSerializer.new(self).serializable_hash[:data][:attributes]
  end

  private

  def create_or_connect_end_product
    if ramp_election.create_or_connect_end_product! == :connected
      update!(error_code: "connected_preexisting_ep")
    end
  rescue StandardError => error
    abort_completion!
    raise error
  end

  def create_ramp_closed_appeals!
    @ramp_closed_appeals = eligible_appeals.map do |appeal|
      RampClosedAppeal.create!(
        vacols_id: appeal.vacols_id,
        ramp_election_id: ramp_election.id,
        nod_date: appeal.nod_date,
        closed_on: Time.zone.now,
        user: user,
        partial_closure_issue_sequence_ids:
          (appeal.fully_compensation? ? nil : appeal.compensation_issues.map(&:vacols_sequence_id))
      )
    end
  end

  # Appeals in VACOLS that will be closed out in favor of a new format review
  def eligible_appeals
    active_compensation_appeals.select(&:eligible_for_ramp?)
  end

  def active_compensation_appeals
    active_veteran_appeals.select(&:compensation?)
  end

  def active_veteran_appeals
    @active_veteran_appeals ||= LegacyAppeal.fetch_appeals_by_file_number(veteran_file_number).select(&:active?)
  end

  def validate_detail_on_start
    if !veteran.valid?(:bgs)
      self.error_code = :veteran_not_valid
      @error_data = veteran_invalid_fields

    elsif active_veteran_appeals.empty?
      self.error_code = :no_active_appeals

    elsif active_compensation_appeals.empty?
      self.error_code = :no_active_compensation_appeals

    elsif eligible_appeals.empty?
      self.error_code = :no_eligible_appeals
    end
  end

  def new_intake_ramp_election
    @new_intake_ramp_election ||= RampElection.new(
      veteran_file_number: veteran_file_number
    )
  end

  def existing_ramp_election
    @existing_ramp_election ||= RampElection.established.where(
      veteran_file_number: veteran_file_number,
      option_selected: detail.option_selected
    ).where.not(id: detail_id).first
  end

  def existing_ramp_election_active?
    existing_ramp_election&.end_product_active?
  end

  def use_existing_ramp_election
    transaction do
      detail.destroy!
      update!(detail: existing_ramp_election)
    end
  end
end
