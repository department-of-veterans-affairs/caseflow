class VacolsAssignment
  include ActiveModel::Model
  include ActiveModel::Serialization

  ATTRS = [:appeal_id, :user_id, :due_on, :assigned_on, :docket_name,
           :docket_date, :added_by_name, :added_by_css_id, :task_id,
           :task_type, :document_id, :assigned_by_first_name,
           :assigned_by_last_name].freeze

  attr_accessor(*ATTRS)

  # The serializer requires a method with the name `id`
  def id
    appeal_id
  end

  def self.from_vacols(case_assignment, user_id)
    task_id = if case_assignment.created_at
                case_assignment.vacols_id + "-" + case_assignment.created_at.strftime("%Y-%m-%d")
              end

    new(
      due_on: case_assignment.date_due,
      docket_name: "legacy",
      added_by_name: FullName.new(
        case_assignment.added_by_first_name,
        case_assignment.added_by_middle_name,
        case_assignment.added_by_last_name
      ).formatted(:readable_full),
      added_by_css_id: case_assignment.added_by_css_id.presence || "",
      docket_date: case_assignment.docket_date,
      appeal_id: case_assignment.vacols_id,
      user_id: user_id,
      task_id: task_id,
      document_id: case_assignment.document_id,
      assigned_by_first_name: case_assignment.assigned_by_first_name,
      assigned_by_last_name: case_assignment.assigned_by_last_name
    )
  end
end
