# frozen_string_literal: true

##
# Task that signals that an appeal is ready for distribution to a judge, including for auto case distribution.

class DistributionTask < GenericTask
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
