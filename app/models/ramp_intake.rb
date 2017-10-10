class RampIntake < Intake
  private

  def validate_detail_on_start
    @error_code = :didnt_receive_ramp_election if !ramp_election
  end

  def ramp_election
    @ramp_election ||= RampElection.find_by(veteran_file_number: veteran_file_number)
  end
end
