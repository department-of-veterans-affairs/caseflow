# frozen_string_literal: true

class PrivacyTeam < Organization
  def self.singleton
    PrivacyTeam.first || PrivacyTeam.create(name: "Privacy Team", url: "privacy")
  end

  def can_bulk_assign_tasks?
    true
  end
end
