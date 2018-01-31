class RampElectionIntake < Intake
  include CachedAttributes

  enum error_code: {
    did_not_receive_ramp_election: "did_not_receive_ramp_election",
    ramp_election_already_complete: "ramp_election_already_complete",
    no_eligible_appeals: "no_eligible_appeals",
    no_active_appeals: "no_active_appeals"
  }.merge(Intake::ERROR_CODES)

  def ramp_election
    detail
  end

  def find_or_build_initial_detail
    matching_ramp_election
  end

  def review!(request_params)
    ramp_election.start_review!
    ramp_election.update_attributes(request_params.permit(:receipt_date, :option_selected))
  end

  def review_errors
    ramp_election.errors.messages
  end

  def complete!(_request_params)
    transaction do
      complete_with_status!(:success)

      Appeal.close(
        appeals: eligible_appeals,
        user: user,
        closed_on: Time.zone.today,
        disposition: "RAMP Opt-in"
      ) do
        ramp_election.create_end_product!
      end
    end
  end

  def cancel!
    transaction do
      detail.update_attributes!(receipt_date: nil, option_selected: nil)
      complete_with_status!(:canceled)
    end
  end

  cache_attribute :cached_serialized_appeal_issues, expires_in: 10.minutes do
    serialized_appeal_issues
  end

  def serialized_appeal_issues
    eligible_appeals.map do |appeal|
      {
        id: appeal.id,
        issues: appeal.issues.map(&:description_attributes)
      }
    end
  end

  def ui_hash
    super.merge(
      notice_date: ramp_election.notice_date,
      option_selected: ramp_election.option_selected,
      receipt_date: ramp_election.receipt_date,
      end_product_description: ramp_election.end_product_description,
      appeals: serialized_appeal_issues
    )
  end

  private

  # Appeals in VACOLS that will be closed out in favor of a new format review
  def eligible_appeals
    active_veteran_appeals.select(&:eligible_for_ramp?)
  end

  def active_veteran_appeals
    @veteran_appeals ||= Appeal.fetch_appeals_by_file_number(veteran_file_number).select(&:active?)
  end

  def validate_detail_on_start
    if matching_ramp_election.successfully_received?
      self.error_code = :ramp_election_already_complete
      @error_data = { notice_date: veteran_ramp_elections.last.notice_date }

    elsif active_veteran_appeals.empty?
      self.error_code = :no_active_appeals

    elsif eligible_appeals.empty?
      self.error_code = :no_eligible_appeals
    end
  end

  def matching_ramp_election
    @ramp_election_on_create ||= veteran_ramp_elections.all.first || veteran_ramp_elections.build
  end

  def veteran_ramp_elections
    RampElection.where(veteran_file_number: veteran_file_number)
  end
end
