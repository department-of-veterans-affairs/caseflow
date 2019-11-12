# frozen_string_literal: true

class JudgeTeamRoleChecker < DataIntegrityChecker
  def call
    # Ensure JudgeTeams have only one User with the JudgeTeamLead role
    self.class.judge_teams_with_incorrect_number_of_leads_messages.each { |msg| add_to_report(msg) }

    # Ensure JudgeTeamLeads are always identified as admins in the associated OrganizationsUser model
    self.class.non_admin_judge_team_leads_messages.each { |msg| add_to_report(msg) }
  end

  class << self
    def judge_teams_with_incorrect_number_of_leads
      JudgeTeam.all.reject { |jt| jt.judge_team_roles.select { |role| role.is_a?(JudgeTeamLead) }.count == 1 }
    end

    def non_admin_judge_team_leads
      JudgeTeamLead.all.reject { |lead| lead.organizations_user.admin? }
    end

    def judge_teams_with_incorrect_number_of_leads_messages
      judge_teams_with_incorrect_number_of_leads.map do |jt|
        lead_count = jt.judge_team_roles.select { |role| role.is_a?(JudgeTeamLead) }.count
        "JudgeTeam #{jt.name} has the incorrect number of associated JudgeTeamLeads: #{lead_count}."
      end
    end

    def non_admin_judge_team_leads_messages
      non_admin_judge_team_leads.map do |lead|
        admin_css_ids = lead.organization.admins.map { |admin| admin.user.css_id }
        id_string = admin_css_ids.any? ? admin_css_ids.join(", ") : "(no admins)"
        "JudgeTeamLead #{lead.user.css_id} is not an admin of JudgeTeam #{lead.organization.name}. "\
        "Admins are #{id_string}"
      end
    end
  end
end
