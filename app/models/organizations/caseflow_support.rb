# frozen_string_literal: true

class CaseflowSupport < Organization
  def self.singleton
    CaseflowSupport.first || CaseflowSupport.create(name: "Caseflow Support", url: "caseflow_support")
  end

  def can_receive_task?(_task)
    false
  end
end
