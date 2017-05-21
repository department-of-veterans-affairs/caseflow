class PowerOfAttorneyRepository
  # :nocov:
  #
  # returns either the data or false
  def self.load_vacols_data(poa)
    case_record = MetricsService.record("VACOLS: load_vacols_data #{poa.vacols_id}",
                                        service: :vacols,
                                        name: "load_vacols_data") do
      # TODO: include the rep table of folder
      VACOLS::Case.includes(:folder).find(poa.vacols_id)
    end

    set_vacols_values(poa: poa, case_record: case_record)

    true

  rescue ActiveRecord::RecordNotFound
    return false
  end

  def self.set_vacols_values(poa:, case_record:)
    poa = PoaMapper.get_poa_from_vacols_poa(case_record.bfso)

    poa.assign_from_vacols(
      vacols_representative_type: poa[:represenative_type],
      vacols_representative_name: poa[:represenative_name]
    )
  end
  # :nocov:
end
