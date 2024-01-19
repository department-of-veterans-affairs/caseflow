# frozen_string_literal: true

# This class is the parent class for different events that Caseflow receives from appeals-consumer
class Event < CaseflowRecord
  has_many :event_records

  def completed?
    completed_at?
  end
end
