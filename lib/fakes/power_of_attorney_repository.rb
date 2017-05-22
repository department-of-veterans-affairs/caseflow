class Fakes::PowerOfAttorneyRepository
  def self.load_vacols_data(poa)
    record = MetricsService.record "load appeal #{appeal.vacols_id}" do
      # TODO: work out a more thorough set of test data
      { bfso: "A" }
    end

    set_vacols_values(poa, record)

    true
  end

  def self.set_vacols_values(poa, record)
    poa = PoaMapper.get_poa_from_vacols_poa(record[:bfso])

    poa.assign_from_vacols(
      vacols_representative_type: poa[:representative_type],
      vacols_representative_name: poa[:representative_name]
    )
  end
end
