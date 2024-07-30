# frozen_string_literal: true

class CavcDecisionReason < CaseflowRecord
  def parent
    return nil unless parent_decision_reason_id

    CavcDecisionReason.find(parent_decision_reason_id)
  end

  def children
    CavcDecisionReason.where(parent_decision_reason_id: id)
  end
end
