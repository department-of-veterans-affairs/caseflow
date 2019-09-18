# frozen_string_literal: true

# tests are all via ExternalApi::BGSService
class ExternalApi::BgsVeteranStationUserConflict
  # :nocov:
  def initialize(veteran_participant_id:, client: nil)
    @veteran_participant_id = veteran_participant_id
    @client = client
  end

  # we do not allow users to do Intakes if the Veteran or a Veteran's relative is employed at the same
  # station as the user.
  # logic detailed in https://github.com/department-of-veterans-affairs/caseflow/issues/10087#issuecomment-507783830
  # a good example in production is veteran_participant_id 3309696 and user id 2321
  # "true" return value in this case means there is a conflict.
  # "false" means no conflict.
  # a "DTO" is a Data Type Object which is just BGS SOAP API speak.
  def conflict?
    DBService.release_db_connections

    return false unless station_dtos.any?

    # simple case if DTOs exist and contain a Veteran record
    return true if veteran_at_same_station

    # likewise for spouse
    return true if spouse_at_same_station

    # otherwise we must check sensitivity reason
    return true if violates_sensitivity_reason?

    # default is no conflict
    false
  end

  private

  attr_reader :veteran_participant_id

  def current_user_station
    RequestStore[:current_user].station_id.to_s
  end

  def station_dtos
    [employee_dtos[:station]].flatten
  end

  def veteran_at_same_station
    veteran_dto && veteran_dto[:station_number].to_s == current_user_station
  end

  def veteran_dto
    station_dtos.find { |dto| dto[:ptcpnt_rlnshp_type_nm] == "Veteran" }
  end

  def spouse_at_same_station
    spouse_dto && spouse_dto[:station_number].to_s == current_user_station
  end

  def spouse_dto
    station_dtos.find { |dto| dto[:ptcpnt_rlnshp_type_nm] == "Spouse" }
  end

  def sensitivity_station_id
    "#{sensitivity_level[:fclty_type_cd]}#{sensitivity_level[:cd]}"
  end

  def sensitivity_reason
    sensitivity_level[:sntvty_reason_type_nm]
  end

  def violates_sensitivity_reason?
    return false unless sensitivity_level
    return false unless sensitivity_station_id == current_user_station

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
    @sensitivity_level ||= MetricsService.record(
      "BGS: fetch sensitivity level by participant id: #{veteran_participant_id}",
      service: :bgs,
      name: "security.find_sensitivity_level_by_participant_id"
    ) do
      client.security.find_sensitivity_level_by_participant_id(veteran_participant_id)
    end
  end

  def client
    @client ||= ExternalApi::BGSService.new.client
  end
  # :nocov:
end
