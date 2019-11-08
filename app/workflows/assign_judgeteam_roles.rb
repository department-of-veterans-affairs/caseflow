# frozen_string_literal: true

# Migrates our old admin-judge based JudgeTeams to use the JudgeTeamRole, invoked via Rake

class AssignJudgeteamRoles
  def perform_dry_run
    @dry_run = true

    process
  end

  def process
    judge_teams = JudgeTeam.all
    judge_teams.each do |judge_team|
      if judge_team.users.empty?
        warn "Judge Team ID #{judge_team.id} has no members. Probably requires manual cleanup"
        next
      end

      admins = judge_team.admins
      if process_admins(admins: admins, judge_team: judge_team)
        nonadmins = judge_team.attorneys
        process_nonadmins(nonadmins: nonadmins, judge_team: judge_team)
      end
    end
  end

  private

  def process_admins(admins, judge_team)
    if incorrect_admin_count?(admins.count)
      return false
    end

    admins.each do |admin|
      message = "#{admin.css_id} JudgeTeamLead of #{judge_team.name}"
      if @dry_run
        warn "Would make #{message}"
      else
        org_user = OrganizationsUser.existing_record(admin, judge_team)
        JudgeTeamLead.find_or_create_by(organizations_user: org_user)
        Rails.logger.info("Setting #{message}")
      end
    end

    true
  end

  def incorrect_admin_count?(_admin_count)
    if admins.empty?
      warn "Judge Team ID #{judge_team.id} has no admin members. Requires manual cleanup. \
        Not assigning roles to team."
      return true
    end

    if admins.count > 1
      warn "Judge Team ID #{judge_team.id} has multiple admin members. Requires manual cleanup. \
        Not assigning roles to team."
      return true
    end

    false
  end

  def process_nonadmins(nonadmins, judge_team)
    nonadmins.each do |atty|
      message = "#{atty.css_id} DecisionDraftingAttorney of #{judge_team.name}"
      if @dry_run
        warn "Would make #{message}"
      else
        org_user = OrganizationsUser.existing_record(atty, judge_team)
        DecisionDraftingAttorney.find_or_create_by(organizations_user: org_user)
        Rails.logger.info("Setting #{message}")
      end
    end
  end
end
