# frozen_string_literal: true

class JudgeTeam < Organization
  def self.for_judge(user)
    # JudgeTeamLead.all.detect { |role| role.user == user }&.organization
    user.administered_teams.detect { |team| team.is_a?(JudgeTeam) }
  end

  def self.create_for_judge(user)
    create!(name: user.css_id, url: user.css_id.downcase).tap do |org|
      OrganizationsUser.make_user_admin(user, org)
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
