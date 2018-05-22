class RampElectionIntake < Intake
  include CachedAttributes

  enum error_code: {
    did_not_receive_ramp_election: "did_not_receive_ramp_election",
    ramp_election_already_complete: "ramp_election_already_complete",
    no_eligible_appeals: "no_eligible_appeals",
    no_active_compensation_appeals: "no_active_compensation_appeals",
    no_active_fully_compensation_appeals: "no_active_fully_compensation_appeals",
    no_active_appeals: "no_active_appeals",
    # This status will be set on successful intakes to signify that we had to
    # connect an existing EP, which in theory, shouldn't happen, but does in practice.
    connected_preexisting_ep: "connected_preexisting_ep"
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
    return if complete? || pending?
    start_complete!

    create_or_connect_end_product

    close_eligible_appeals!

    transaction do
      complete_with_status!(:success)
      eligible_appeals.each do |appeal|
        RampClosedAppeal.create!(
          vacols_id: appeal.vacols_id,
          ramp_election_id: ramp_election.id,
          nod_date: appeal.nod_date
        )
      end
    end
  end

  def cancel_detail!
    detail.update_attributes!(
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
    super.merge(
      notice_date: ramp_election.notice_date,
      option_selected: ramp_election.option_selected,
      receipt_date: ramp_election.receipt_date,
      end_product_description: ramp_election.end_product_description,
      appeals: serialized_appeal_issues
    )
  end

  private

  def create_or_connect_end_product
    if ramp_election.create_or_connect_end_product! == :connected
      update!(error_code: "connected_preexisting_ep")
    end
  rescue StandardError => e
    clear_pending!
    raise e
  end

  def close_eligible_appeals!
    LegacyAppeal.close(
      appeals: eligible_appeals,
      user: user,
      closed_on: Time.zone.today,
      disposition: "RAMP Opt-in",
      election_receipt_date: ramp_election.receipt_date
    )
  end

  # Appeals in VACOLS that will be closed out in favor of a new format review
  def eligible_appeals
    active_fully_compensation_appeals.select(&:eligible_for_ramp?)
  end

  # Temporarily only allow RAMP appeals with 100% compensation issues.
  # TODO: Take this out when we allow partial closing of appeals.
  def active_fully_compensation_appeals
    active_veteran_appeals.select(&:fully_compensation?)
  end

  def active_compensation_appeals
    active_veteran_appeals.select(&:compensation?)
  end

  def active_veteran_appeals
    @veteran_appeals ||= LegacyAppeal.fetch_appeals_by_file_number(veteran_file_number).select(&:active?)
  end

  def validate_detail_on_start
    if matching_ramp_election.established?
      self.error_code = :ramp_election_already_complete
      @error_data = { receipt_date: matching_ramp_election.receipt_date }

    elsif active_veteran_appeals.empty?
      self.error_code = :no_active_appeals

    elsif active_compensation_appeals.empty?
      self.error_code = :no_active_compensation_appeals

    elsif active_fully_compensation_appeals.empty?
      self.error_code = :no_active_fully_compensation_appeals

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
