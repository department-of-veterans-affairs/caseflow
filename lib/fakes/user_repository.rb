class Fakes::UserRepository
  def self.can_access_task?(_css_id, _vacols_id)
    true
  end

  def self.vacols_role(_css_id)
    "Attorney"
  end

  def self.vacols_attorney_id(_css_id)
    rand(1000)
  end

  def self.vacols_group_id(_css_id)
    "Attorney/Judge Group"
  end

  def self.vacols_uniq_id(css_id)
    css_id
  end

  def self.vacols_full_name(_css_id)
    %w[George John Thomas].sample + " " + %w[Washington King Jefferson].sample
  end
end
