class JudgeTeam < Organization
  def self.for_judge(user)
    user.administrated_teams.select { |team| team.is_a?(JudgeTeam) }.first
  end

  def self.create_for_judge(user)
    org = create!(name: user.css_id)
    OrganizationsUser.make_user_admin(user, org)
    org
  end
end
