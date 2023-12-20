# frozen_string_literal: true

class ETL::DecisionDocumentSyncer < ETL::Syncer
  def origin_class
    ::DecisionDocument
  end

  def target_class
    ETL::DecisionDocument
  end
end
