class AutoCaseDistributor < Organization
  def self.singleton
    AutoCaseDistributor.first || AutoCaseDistributor.create(name: "AutoCaseDistributor", url: "auto_case_distributor")
  end
end
