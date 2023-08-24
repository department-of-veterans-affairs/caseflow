# frozen_string_literal: true

class RemandReason < CaseflowRecord
  validates :code, inclusion: { in: Constants::AMA_REMAND_REASONS_BY_ID.values.map(&:keys).flatten }
  belongs_to :decision_issue
end
