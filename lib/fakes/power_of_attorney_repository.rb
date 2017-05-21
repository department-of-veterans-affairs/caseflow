
class Fakes::PowerOfAttorneyRepository
  def self.load_vacols_data(poa)
    # timing a hash access is unnecessary but this adds coverage to MetricsService in dev mode
    record = MetricsService.record "load appeal #{appeal.vacols_id}" do
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
