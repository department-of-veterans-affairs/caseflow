# frozen_string_literal: true

class HearingsManagement < Organization
  def can_bulk_assign_tasks?
    true
  end

  def self.singleton
    HearingsManagement.first || HearingsManagement.create(name: "Hearing Management", url: "hearing-management")
  end
end
