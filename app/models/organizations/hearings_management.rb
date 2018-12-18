class HearingsManagement < Organization
  def self.singleton
    HearingsManagement.first || HearingsManagement.create(name: "Hearings Management")
  end
end
