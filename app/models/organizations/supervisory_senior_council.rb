# frozen_string_literal: true

class SupervisorySeniorCouncil < Organization
  alias_attribute :full_name, :name

  def self.singleton
    SupervisorySeniorCouncil.first || SupervisorySeniorCouncil.create(
      name: "Supervisory Senior Council",
      url: "supervisory-senior-council"
    )
  end

  def can_receive_task?(_task)
    false
  end

  def users_can_create_mail_task?
    true
  end
end
