# frozen_string_literal: true

##
# Task that will serve as the parent task for the entirety of the pre docket workflow. This task will be assigned to
# the Bva organization and remain "on hold" until the AssessDocumentationTask is completed.

class PreDocketTask < Task
  class << self
    def create_pre_docket_task!(appeal)
      pre_docket_task = create!(
        appeal: appeal,
        assigned_to: Bva.singleton
      )

      pre_docket_task.put_on_hold_due_to_new_child_task
    end
  end
end
