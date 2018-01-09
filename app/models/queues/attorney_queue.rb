class AttorneyQueue
  include ActiveModel::Model

  def self.tasks(user_id = nil, css_id = nil)
    css_id = User.find(user_id).css_id if css_id.nil?
    user_id = User.find(css_id: css_id) if user_id.nil?

    case_assignments = Appeal.repository.load_user_case_assignments_from_vacols(css_id)

    case_assignments.map do |assignment|
      from_vacols_case_assignment(assignment, user_id)
    end
  end

  def self.from_vacols_case_assignment(case_assignment, user_id)
    DraftDecision.new(
      assigned_on: case_assignment.date_assigned,
      due_on: case_assignment.date_due,
      docket_name: "legacy",
      docket_date: case_assignment.docket_date,
      appeal_id: case_assignment.id,
      user_id: user_id
    )
  end
end


