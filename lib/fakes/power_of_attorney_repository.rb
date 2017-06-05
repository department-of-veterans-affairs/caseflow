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

  def self.update_vacols_rep_type!(case_record:, vacols_rep_type:)
    nil
  end

  def self.update_vacols_rep_name!(case_record:, first_name:, middle_initial:, last_name:)
    nil
  end

  def self.update_vacols_rep_address_one!(case_record:, address_one:)
    nil
  end
end
