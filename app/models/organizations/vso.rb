# frozen_string_literal: true

class Vso < Representative
  def can_bulk_assign_tasks?
    [
      "American Legion",
      "Disabled American Veterans",
      "Veterans of Foreign Wars"
    ].include?(name)
  end
end
