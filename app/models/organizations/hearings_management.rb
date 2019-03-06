# frozen_string_literal: true

class HearingsManagement < Organization
  def self.singleton
    HearingsManagement.first || HearingsManagement.create(name: "Hearing Management", url: "hearing-management")
  end
end
