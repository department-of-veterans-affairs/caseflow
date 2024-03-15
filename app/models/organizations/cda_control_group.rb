# frozen_string_literal: true

class CDAControlGroup < Organization
  alias_attribute :full_name, :name

  def self.singleton
    CDAControlGroup.first || CDAControlGroup.create(
      name: "Case Distro Algorithm Control",
      url: "cda-control-group"
    )
  end

  def users_can_view_levers?
    true
  end

  def can_receive_task?(_task)
    false
  end
end
