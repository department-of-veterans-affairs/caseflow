class PowerOfAttorneyRepository
  # :nocov:
  include PowerOfAttorneyMapper
  # returns either the data or false
  #
  def self.poa_query
    # TODO: include the rep table instead of the folder
    VACOLS::Case.includes(:folder).find(poa.vacols_id)
  end

  def self.load_vacols_data(poa)
    case_record = MetricsService.record("VACOLS POA: load_vacols_data #{poa.vacols_id}",
                                        service: :vacols,
                                        name: "PowerOfAttorneyRepository.load_vacols_data") do
      poa_query
    end

    set_vacols_values(poa: poa, case_record: case_record)

    true

  rescue ActiveRecord::RecordNotFound
    return false
  end

  def self.set_vacols_values(poa:, case_record:)
    rep_info = get_poa_from_vacols_poa(case_record.bfso)

    poa.assign_from_vacols(
      vacols_representative_type: rep_info[:represenative_type],
      vacols_representative_name: rep_info[:represenative_name]
    )
  end
  # :nocov:
end
