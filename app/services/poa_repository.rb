class PoaRepository
  # :nocov:
  #
  # returns either the data or false
  def self.load_vacols_data(poa)
    case_record = MetricsService.record("VACOLS: load_vacols_data #{poa.vacols_id}",
                                        service: :vacols,
                                        name: "load_vacols_data") do
      VACOLS::Case.includes(:folder).find(poa.vacols_id)
    end

    set_vacols_values(poa: poa, case_record: case_record)

    true

  rescue ActiveRecord::RecordNotFound
    return false
  end

  def self.set_vacols_values(poa:, case_record:)
    poa = get_poa_from_vacols_poa(case_record.bfso)

    poa.assign_from_vacols(poa)
  end
end
