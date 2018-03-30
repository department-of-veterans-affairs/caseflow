class Fakes::UserRepository
  def self.can_access_task?(_css_id, _vacols_id)
    true
  end

  def self.vacols_role(_css_id)
    "Attorney"
  end

  def self.vacols_uniq_id(css_id)
    css_id
  end
end
