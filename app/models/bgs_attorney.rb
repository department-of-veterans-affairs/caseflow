# frozen_string_literal: true

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
