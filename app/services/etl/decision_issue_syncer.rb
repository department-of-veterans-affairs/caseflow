# frozen_string_literal: true

class ETL::DecisionIssueSyncer < ETL::Syncer
  def origin_class
    ::DecisionIssue
  end

  def target_class
    ETL::DecisionIssue
  end
end
