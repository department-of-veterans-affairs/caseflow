# frozen_string_literal: true

class SplitCorrelationTable < CaseflowRecord
  include UpdatedByUserConcern
  include CreatedByUserConcern

  private
end