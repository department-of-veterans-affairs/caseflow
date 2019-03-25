# frozen_string_literal: true

##
# Task assigned to the Hearing Admin organization when a user elects to change a hearing's disposition
# or automatically 48 hours after a hearing was held to remind a judge to add a disposition.
class ChangeDispositionTask < DispositionTask
  class << self
    def create_change_disposition_task!(appeal, parent, hearing)
      change_disposition_task = ChangeDispositionTask.create!(
        appeal: appeal,
        parent: parent,
        assigned_to: HearingAdmin.singleton
      )

      HearingTaskAssociation.find_or_create_by!(hearing: hearing, hearing_task: parent)

      change_disposition_task
    end
  end
end
