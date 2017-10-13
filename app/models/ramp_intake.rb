class RampIntake < Intake
  def find_or_create_initial_detail
    matching_ramp_election
  end

  private

  def validate_detail_on_start
    @error_code = :did_not_receive_ramp_election if !matching_ramp_election
  end

  def matching_ramp_election
    @matching_ramp_election ||= RampElection.find_by(veteran_file_number: veteran_file_number)
  end
end
