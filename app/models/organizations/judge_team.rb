class JudgeTeam < Organization
  def self.for_judge(user)
    find_by(name: user.css_id)
  end

  def self.create_for_judge(user)
    create!(name: user.css_id)
  end
end
