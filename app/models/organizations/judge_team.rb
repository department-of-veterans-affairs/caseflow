class JudgeTeam < Organization
  def self.for_judge(user)
    user.administered_teams.select { |team| team.is_a?(JudgeTeam) }.first
  end

  def self.create_for_judge(user)
    create!(name: user.css_id).tap do |org|
      OrganizationsUser.make_user_admin(user, org)
    end
  end

  def can_receive_task?(_task)
    false
  end
end
