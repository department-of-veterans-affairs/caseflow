class Fakes::PowerOfAttorneyRepository < PowerOfAttorneyRepository
  # TODO: should we use the appeal generator for this?
  # TODO: set up more and better test data
  class FakePoaRecord
    def self.bfso
      "A"
    end

    def self.representative
      nil
    end
  end

  def self.poa_query(_poa)
    FakePoaRecord
  end

  def self.update_vacols_rep_type!(_case_record, _vacols_rep_type)
    nil
  end

  def self.update_vacols_rep_name!(_case_record, _first_name, _middle_initial, _last_name)
    nil
  end

  def self.update_vacols_rep_address_one!(_case_record, _address_one)
    nil
  end
end
