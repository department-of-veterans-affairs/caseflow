class HearingsManagement < Organization
  def self.singleton
    HearingsManagement.first || HearingsManagement.create(name: "Hearings Management")
  end

  def user_has_access?(user)
    return true
  end
end