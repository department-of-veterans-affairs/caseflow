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

      if admins.empty?
        warn "Judge Team ID #{judge_team.id} has no admin members. Requires manual cleanup. Not assigning roles to team."
        next
      end

      if admins.count > 1
        warn "Judge Team ID #{judge_team.id} has multiple admin members. Requires manual cleanup. Not assigning roles to team."
        next
      end

      admins.each do |admin|
        message =  "#{admin.css_id} JudgeTeamLead of #{judge_team.name}"
        if @dry_run
          puts "Would make #{message}"
        else
          org_user = OrganizationsUser.existing_record(admin, judge_team)
          JudgeTeamLead.find_or_create_by(organizations_user: org_user)
          Rails.logger.info("Setting #{message}")
        end
      end
      nonadmins = judge_team.attorneys
      nonadmins.each do |atty|
        message = "#{atty.css_id} DecisionDraftingAttorney of #{judge_team.name}"
        if @dry_run
          puts "Would make #{message}"
        else
          org_user = OrganizationsUser.existing_record(atty, judge_team)
          DecisionDraftingAttorney.find_or_create_by(organizations_user: org_user)
          Rails.logger.info("Setting #{message}")
        end
      end
    end
  end
end
