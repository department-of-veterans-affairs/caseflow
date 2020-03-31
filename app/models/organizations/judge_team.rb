# frozen_string_literal: true

class JudgeTeam < Organization
  class << self
    def for_judge(user)
      if use_judge_team_roles?
        administered_judge_teams = user.administered_judge_teams

        # Find the one, if any, we're the JudgeTeamLead for
        administered_judge_teams.detect { |jt| user == jt.judge }
      else
        user.administered_teams.detect { |team| team.is_a?(JudgeTeam) && team.judge.eql?(user) }
      end
    end

    def create_for_judge(user)
      fail(Caseflow::Error::DuplicateJudgeTeam, user_id: user.id) if JudgeTeam.for_judge(user)

      create!(name: user.css_id, url: user.css_id.downcase).tap do |org|
        # make_user_admin invokes add_user, which handles adding the JudgeTeamLead JudgeTeamRole
        OrganizationsUser.make_user_admin(user, org)
      end
    end

    def use_judge_team_roles?
      FeatureToggle.enabled?(:judge_admin_scm)
    end
  end

  # Use the size of the organization to determine if we have just created a JudgeTeam for a judge,
  # or just added a user to an existing JudgeTeam. We assume the first user will always be a judge.
  # All subsequent members of the team will be attorneys, by default
  def add_user(user)
    super.tap do |org_user|
      class_name = (users.count == 1) ? JudgeTeamLead : DecisionDraftingAttorney
      class_name.find_or_create_by(organizations_user: org_user)
    end
  end

  def judge
    if use_judge_team_roles?
      judge_team_roles.detect { |role| role.is_a?(JudgeTeamLead) }.organizations_user.user
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
