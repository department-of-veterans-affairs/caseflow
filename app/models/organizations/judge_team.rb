# frozen_string_literal: true

class JudgeTeam < Organization
  class << self
    def for_judge(user)
      if use_judge_team_roles?
        # Collect all JudgeTeams this user administers
        judge_teams_administered = user.administered_teams.select { |team| team.is_a?(JudgeTeam) }
        return unless judge_teams_administered.any?

        # Find the one, if any, we're the JudgeTeamLead for
        judge_teams_administered.each do |judge_team|
          if user == judge_team.judge
            return judge_team
          end
        end
        nil
      else
        user.administered_teams.detect { |team| team.is_a?(JudgeTeam) }
      end
    end

    def create_for_judge(user)
      fail(Caseflow::Error::DuplicateJudgeTeam, user_id: user.id) if JudgeTeam.for_judge(user)

      # TODO: Becomes: fail if already a JudgeTeamLead on a judge team

      # TODO: Might be already correct?
      create!(name: user.css_id, url: user.css_id.downcase).tap do |org|
        # TODO: clarify this note? v
        # Add the JudgeTeamLead record in org.add_user which gets triggered by OrganizationsUser.make_user_admin
        OrganizationsUser.make_user_admin(user, org)
      end
    end

    def use_judge_team_roles?
      FeatureToggle.enabled?(:use_judge_team_role)
    end
  end

  # Use the size of the organization to determine if we have just created a JudgeTeam for a judge,
  # or just added a user to an existing JudgeTeam. We assume the first user will always be a judge.
  # All subsequent members of the team will be attorneys, by default
  def add_user(user)
    super.tap do |org_user|
      class_name = (users.count == 1) ? JudgeTeamLead : DecisionDraftingAttorney
      class_name.create!(organizations_user: org_user)
    end
  end

  def judge
    if use_judge_team_roles?
      judge_team_roles.detect { |role| role.is_a?(JudgeTeamLead) }.organizations_user.user
      # TODO: doublcheck this is a DB constraint
    else
      admins.first
    end
  end

  def attorneys
    if use_judge_team_roles?
      atty_roles = judge_team_roles.select { |role| role.is_a?(DecisionDraftingAttorney) }
      atty_roles.map { |atty_role| atty_role.organizations_user.user }
    else
      non_admins
    end
  end

  def can_receive_task?(_task)
    false
  end

  def selectable_in_queue?
    false
  end

  private

  def use_judge_team_roles?
    JudgeTeam.use_judge_team_roles?
  end
end
