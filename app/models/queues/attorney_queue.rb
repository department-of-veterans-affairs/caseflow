class AttorneyQueue
  include ActiveModel::Model

  def self.tasks(user_id = nil, css_id = nil)
    css_id = User.find(user_id).css_id if css_id.nil?
    user_id = User.find(css_id: css_id) if user_id.nil?

    case_assignment = Appeal.repository.load_user_case_assignments_from_vacols(css_id)

    case_assignments.map do |case_assignment|
      DraftDecision.new(
        assigned_on: case_assignment.date_assigned
        docket_name: "legacy",
        appeal_id: case_assignment.id,
        user_id: user_id,
        docket_date: case_assignment.docket_date,
        assigned_at: case_assignment.date_assigned,
        due_at: case_assignment.date_due,
      )
    end
  end
end


