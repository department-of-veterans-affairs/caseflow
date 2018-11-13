class HearingsManagement < Organization
  def self.singleton
    HearingsManagement.first || HearingsManagement.create!(name: "Hearings Management")
  end

  def user_has_access?(_user)
    true
  end
end
