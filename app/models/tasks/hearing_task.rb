##
# Task tracking a Veterans Law Judge hearing.

class HearingTask < GenericTask
  has_one :hearing_task_association
end
