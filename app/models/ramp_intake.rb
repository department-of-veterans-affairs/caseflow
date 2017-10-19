class RampIntake < Intake
  def find_or_create_initial_detail
    matching_ramp_election
  end

  def complete!
    transaction do
      complete_with_status!(:success)

      legacy_appeals_to_close.each do |appeal|
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

  private

  # Appeals in VACOLS that will be closed out in favor
  # of a new format review
  def legacy_appeals_to_close
    Appeal.fetch_appeals_by_file_number(veteran_file_number)
  end

  def validate_detail_on_start
    @error_code = :did_not_receive_ramp_election if !matching_ramp_election
  end

  def matching_ramp_election
    @matching_ramp_election ||= RampElection.find_by(veteran_file_number: veteran_file_number)
  end
end
