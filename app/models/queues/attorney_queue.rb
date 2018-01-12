class AttorneyQueue
  include ActiveModel::Model

  def self.tasks(user_id)
    css_id = User.find(user_id).css_id
    case_assignments = Appeal.repository.load_user_case_assignments_from_vacols(css_id)

    case_assignment.map do |assignment|
      DraftDecision.from_vacols(assignment, user_id)
    end
  end
end
