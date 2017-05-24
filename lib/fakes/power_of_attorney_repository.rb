class Fakes::PowerOfAttorneyRepository < PowerOfAttorneyRepository
  # TODO: should we use the appeal generator for this?
  # TODO: set up more and better test data
  class FakePoaRecord
    def self.bfso
      "A"
    end
  end

  def self.poa_query
    FakePoaRecord
  end
end
