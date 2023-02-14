# frozen_string_literal: true

class SplitCorrelationTable < CaseflowRecord
  # to remove old columns
  self.ignored_columns = [:split_request_issue_ids, :original_request_issue_ids]
end
