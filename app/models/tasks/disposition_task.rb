##
# Task assigned to the BvaOrganization after a hearing is scheduled, created after the ScheduleHearingTask is completed.
# When the associated hearing's disposition is set, the appropriate tasks are set as children
#   (e.g., TranscriptionTask, EvidenceWindowTask, etc.).
# The task is marked complete when these children tasks are completed.
class DispositionTask < GenericTask
  before_create :check_parent_type

  class << self
    def create_disposition_task!(appeal, parent, hearing)
      DispositionTask.create!(
        appeal: appeal,
        parent: parent,
        assigned_to: Bva.singleton
      )

      HearingTaskAssociation.create!(hearing: hearing, hearing_task: parent)
    end
  end

  def label
    "Hearing disposition to be selected"
  end

  def check_parent_type
    if parent.type != "HearingTask"
      fail(
        Caseflow::Error::InvalidParentTask,
        task_type: self.class.name,
        assignee_type: assigned_to.class.name
      )
    end
  end
end
