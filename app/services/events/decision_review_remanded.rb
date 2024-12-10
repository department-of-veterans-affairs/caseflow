# frozen_string_literal: true

# This class handles the backfill creation of Automatically established Remand Claims (auto remands)
# and their RequestIssues following the VBMS workflow where the original HLR is completed
# and there are DTA/DOO errors that require a new Remand SC to be created.
class Events::DecisionReviewRemanded
  include RedisMutex::Macro

  class << self
    def create!(params, headers, payload);end
  end
end
