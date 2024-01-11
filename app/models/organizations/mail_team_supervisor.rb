# frozen_string_literal: true

class MailTeamSupervisor < Organization
  def self.singleton
    MailTeamSupervisor.first ||
      MailTeamSupervisor.create(name: "Mail Team Supervisor", url: "mail-team-supervisor")
  end

  # :reek:UtilityFunction
  def selectable_in_queue?
    FeatureToggle.enabled?(:correspondence_queue, user: RequestStore.store[:current_user])
  end
end
