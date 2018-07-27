class Fakes::UserRepository
  def self.can_access_task?(_css_id, _vacols_id)
    true
  end

  def self.user_info_from_vacols(css_id)
    {
      uniq_id: css_id,
      roles: css_id.eql?("BVAAABSHIRE") ? ["judge"] : ["attorney"],
      attorney_id: rand(1000),
      group_id: "Attorney/Judge Group",
      full_name: %w[George John Thomas].sample + " " + %w[Washington King Jefferson].sample
    }
  end  

  def self.user_info_for_idt(css_id)
    {}
  end
end
