# frozen_string_literal: true

class SupervisorySeniorCounsel < Organization
  alias_attribute :full_name, :name

  def self.singleton
    SupervisorySeniorCounsel.first || SupervisorySeniorCounsel.create(
      name: "Supervisory Senior Counsel",
      url: "supervisory-senior-counsel"
    )
  end

  def can_receive_task?(_task)
    false
  end

  def users_can_create_mail_task?
    true
  end
end
