# frozen_string_literal: true

module DecisionDocumentable
  extend ActiveSupport::Concern

  class_methods do
    def has_zero_decision_documents
      left_joins(:decision_documents).where(decision_documents: { id: nil })
    end
  end
end
