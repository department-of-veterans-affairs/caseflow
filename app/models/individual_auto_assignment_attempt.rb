# frozen_string_literal: true

class IndividualAutoAssignmentAttempt < CaseflowRecord
  include AutoAssignable

  belongs_to :user, optional: false
  belongs_to :correspondence, optional: false
  belongs_to :batch_auto_assignment_attempt, optional: false

  validates :nod, inclusion: [true, false]
end
