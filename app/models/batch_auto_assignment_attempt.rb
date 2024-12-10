# frozen_string_literal: true

class BatchAutoAssignmentAttempt < CaseflowRecord
  include AutoAssignable

  belongs_to :user, optional: false

  has_many :individual_auto_assignment_attempts, dependent: :destroy
end
