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
end
