class ExternalApi::BgsVeteranStationUserConflict
  def initialize(veteran_participant_id:, client: nil)
    @veteran_participant_id = veteran_participant_id
    @client = client
  end

  # logic detailed in https://github.com/department-of-veterans-affairs/caseflow/issues/10087#issuecomment-507783830
  def call
    DBService.release_db_connections

    # simple case if DTOs exist and do not contain a Veteran record
    return true if station_dtos.any? && !veteran_dto

    # otherwise we must check sensitivity reason

  end

  private

  attr_reader :veteran_participant_id

  def current_user_station
    RequestStore[:current_user].station_id.to_s
  end

  def station_dtos
    [employee_dtos[:station]].flatten
  end

  def veteran_dto
    station_dtos.find { |dto| dto[:ptcpnt_rlnshp_type_nm] == "Veteran" }
  end

  def veteran_at_same_station?
    return false unless station_dtos

    return false unless veteran_dto

    return veteran_dto[:station_number] == current_user_station
  end

  def veteran_station_id
    "#{sensitivity_level[:fclty_type_cd]}#{sensitivity_level[:cd]}"
  end

  def sensitivity_reason
    sensitivity_level[:sntvty_reason_type_nm]
  end

  def violates_sensitivity_reason?
    ["Relative of Local VA Employee", "VBA Employee", "Veteran", "Work Study"].include?(sensitivity_reason)
  end

  def employee_dtos
    @employee_dtos ||= MetricsService.record("BGS: fetch employee by participant id: #{veteran_participant_id}",
                                             service: :bgs,
                                             name: "people.find_employee_by_participant_id") do
      client.people.find_employee_by_participant_id(veteran_participant_id)
    end
  end

  def sensitivity_level
    @sensitivity_level ||= MetricsService.record("BGS: fetch sensitivity level by participant id: #{veteran_participant_id}",
                                                 service: :bgs,
                                                 name: "security.find_sensitivity_level_by_participant_id") do
      client.security.find_sensitivity_level_by_participant_id(veteran_participant_id)
    end
  end

  def client
    @client ||= ExternalApi::BGSService.new.client
  end
end
