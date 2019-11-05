# frozen_string_literal: true

class JudgeTeam < Organization
  def self.for_judge(user)
    user.administered_teams.detect { |team| team.is_a?(JudgeTeam) }
  end

  def self.create_for_judge(user)
    fail(Caseflow::Error::DuplicateJudgeTeam, user_id: user.id) if JudgeTeam.for_judge(user)

    create!(name: user.css_id, url: user.css_id.downcase).tap do |org|
      # Add the JudgeTeamLead record in org.add_user which gets triggered by OrganizationsUser.make_user_admin
      OrganizationsUser.make_user_admin(user, org)
    end
  end

  # Use the size of the organization to determine if we have just created a JudgeTeam for a judge,
  # or just added a user to an existing JudgeTeam. We assume the first user will always be a judge.
  # All subsequent members of the team will be attorneys.
  def add_user(user)
    super.tap do |org_user|
      class_name = (users.count == 1) ? JudgeTeamLead : DecisionDraftingAttorney
      class_name.create!(organizations_user: org_user)
    end
  end

  def judge
    admins.first
  end

  def attorneys
    non_admins
  end

  def can_receive_task?(_task)
    false
  end

  def selectable_in_queue?
    false
  end
end
