# frozen_string_literal: true

class MailTeamSupervisor < Organization
  def self.singleton
    MailTeamSupervisor.first ||
      MailTeamSupervisor.create(name: "Mail Team Supervisor", url: "mail-team-supervisor")
  end
end

