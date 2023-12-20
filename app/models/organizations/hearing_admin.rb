# frozen_string_literal: true

class HearingAdmin < Organization
  def show_regional_office_in_queue?
    true
  end

  def self.singleton
    HearingAdmin.first || HearingAdmin.create(name: "Hearing Admin", url: "hearing-admin")
  end
end
