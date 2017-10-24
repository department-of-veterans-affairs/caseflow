class RampIntake < Intake
  include CachedAttributes

  def find_or_create_initial_detail
    matching_ramp_election
  end

  def complete!
    transaction do
      complete_with_status!(:success)

      eligible_appeals.each do |appeal|
        appeal.close!(user: user, closed_on: Time.zone.today, disposition: "RAMP Opt-in")
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

  private

  # Appeals in VACOLS that will be closed out in favor
  # of a new format review
  def eligible_appeals
    Appeal.fetch_appeals_by_file_number(veteran_file_number).select(&:eligible_for_ramp?)
  end

  def validate_detail_on_start
    if !matching_ramp_election
      @error_code = :did_not_receive_ramp_election

    elsif eligible_appeals.empty?
      @error_code = :no_eligible_appeals
    end
  end

  def matching_ramp_election
    @matching_ramp_election ||= RampElection.find_by(veteran_file_number: veteran_file_number)
  end
end
