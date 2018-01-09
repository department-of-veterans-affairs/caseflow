class Fakes::PowerOfAttorneyRepository < PowerOfAttorneyRepository
  class FakeInvalidRepTypeError < StandardError; end

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
    fail(FakeInvalidRepTypeError) unless VACOLS::Case::REPRESENTATIVES.include?(vacols_rep_type)
    return nil if case_record
  end

  def self.update_vacols_rep_name!(*)
    nil
  end

  def self.update_vacols_rep_address!(*)
    nil
  end
end
