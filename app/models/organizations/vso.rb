# frozen_string_literal: true

class Vso < Representative
  def can_bulk_assign_tasks?
    bulk_assign_vso_names = [
      "American Legion",
      "Disabled American Veterans",
      "Veterans of Foreign Wars"
    ]

    Vso.where(name: bulk_assign_vso_names).include?(self)
  end
end
