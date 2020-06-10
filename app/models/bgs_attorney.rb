# frozen_string_literal: true

# This is for caching (POA) attorney records from BGS for use in adding claimants
# who might not already be associated with a record (hence the use of a different model/table)

class BgsAttorney < CaseflowRecord
  include AssociatedBgsRecord
  include BgsService

  class BgsAttorneyNotFound < StandardError; end

  class << self
    def fetch_bgs_attorneys
      # Implement connection to existing BGS service method
      # client.data.find_power_of_attorneys
      # bgs.find_power_of_attorneys
    end
  end
end
