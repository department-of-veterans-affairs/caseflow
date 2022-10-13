# frozen_string_literal: true

class SplitCorrelationTable < CaseflowRecord

  def create_split_record
    # Performs a query to see if the orginal apeal UUID has been split
    if SplitCorrelation.find_by_
end