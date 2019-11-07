# frozen_string_literal: true

class AssignJudgeteamRoles

  # add any errors

  def perform_dry_run
    @dry_run = true

    process
  end

  def process
    judge_teams = JudgeTeam.all
    # TODO: only one admin should be made JTL
    judge_teams.each do |judge_team|
      admins = judge_team.admins
      admins.each do |admin|
        JudgeTeamRole.create(organizations_user: OrganizationsUser.existing_record(admin, judge_team))
      end
    # no members?
    #   warn
    #   if none? error
    #   if one, set that user with a JudgeTeamLead
    #   if multiple, and one has JTL continue to non-admins
    #   if multiple and no JTL, error
    # find all the non-admin members
    #   set each user with a DecisionDraftingAttorney
    #   None? that's okay. Note it?
    end
    #
    #
    # THINGS TO THINK ABOUT
    # If the user already has this new role?
    #   That is fine, no error, no attempt to duplicate
    # If there are no judge teams, warn about that? but don't blow up
  end
end
