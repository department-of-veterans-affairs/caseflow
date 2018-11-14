class JudgeTeam < Organization
  def self.for_judge(user)
    find_by(name: user.css_id)
  end

  def self.create_for_judge(user)
    org = create!(name: user.css_id)
    OrganizationsUser.add_user_to_organization(user, org).update!(admin: true)
    org
  end
end
