##
# Task assigned to the BvaOrganization after a hearing is scheduled.
# Created after the ScheduleHearingTask is completed and the hearing is scheduled.
# Marked complete when the hearing is held.

class HoldHearingTask < GenericTask
  class << self
    def create_hold_hearing_task!(appeal, parent, hearing)
      HoldHearingTask.create!(
        appeal: appeal,
        parent: parent,
        assigned_to: Bva.singleton
      )

      if parent.is_a? HearingTask
        HearingTaskAssociation.create!(hearing: hearing, hearing_task: parent)
      end
    end
  end
end
