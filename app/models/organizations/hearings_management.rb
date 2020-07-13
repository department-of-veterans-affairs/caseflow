# frozen_string_literal: true

class HearingsManagement < Organization
  def self.singleton
    HearingsManagement.first || HearingsManagement.create(name: "Hearings Management", url: "hearings-management")
  end

  def show_regional_office_in_queue?
    true
  end
end
