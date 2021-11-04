# frozen_string_literal: true

##
# The VAMC associated with an Assess Documentation Task, which is assigned by a Program Office when assigning to a VISN

class TaskVamc < CaseflowRecord
  belongs_to :task
end
