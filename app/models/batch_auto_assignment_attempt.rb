# frozen_string_literal: true

class BatchAutoAssignmentAttempt < CaseflowRecord
  include AutoAssignable

  has_many :individual_auto_assignment_attempts, dependent: :destroy
end
