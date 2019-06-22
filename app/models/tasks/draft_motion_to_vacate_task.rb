# frozen_string_literal: true

##
# When Litigation Support receives a motion to vacate mail task, it gets assigned to a judge to draft a decision

class DraftMotionToVacateTask < GenericTask
  before_validation :set_assignee

  def ready_for_distribution!
    update!(status: :assigned, assigned_at: Time.zone.now)
  end

  def ready_for_distribution?
    assigned?
  end

  def ready_for_distribution_at
    assigned_at
  end

  private

  def set_assignee
    self.assigned_to ||= MailTeam.singleton
  end
end
