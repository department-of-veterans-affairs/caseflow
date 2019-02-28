##
# Task assigned to the BvaOrganization after a hearing is scheduled, created after the ScheduleHearingTask is completed.
# When the associated hearing's disposition is set, the appropriate tasks are set as children
#   (e.g., TranscriptionTask, EvidenceWindowTask, etc.).
# The task is marked complete when these children tasks are completed.
#
# This task is deprecated and replaced by DispositionTask as of March 1, 2019.
#
class HoldHearingTask < GenericTask
  class << self
    def create_hold_hearing_task!(appeal, parent, hearing)
      HoldHearingTask.create!(
        appeal: appeal,
        parent: parent,
        assigned_to: Bva.singleton
      )
      HearingTaskAssociation.create!(hearing: hearing, hearing_task: parent)
    end
  end
end
