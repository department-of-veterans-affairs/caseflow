# frozen_string_literal: true

##
# A task used to track all related hearing subtasks.
# A hearing task is associated with a hearing record in Caseflow and might have several child tasks to resolve
# in order to schedule a hearing, hold it, and mark the disposition.

class HearingTask < GenericTask
  has_one :hearing_task_association
end
