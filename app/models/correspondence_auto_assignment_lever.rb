# frozen_string_literal: true

class CorrespondenceAutoAssignmentLever < CaseflowRecord
  has_paper_trail on: [:update, :destroy]

  class << self
    def capacity_rule
      find_by(name: "capacity")
    end

    def max_capacity
      CorrespondenceAutoAssignmentLever.capacity_rule&.value ||
        Constants.CORRESPONDENCE_AUTO_ASSIGNMENT.max_assigned_tasks
    end
  end
end
