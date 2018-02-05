class DraftDecision
  include ActiveModel::Model
  include ActiveModel::Serialization

  ATTRS = [:appeal_id, :user_id, :due_on, :assigned_on, :docket_name,
           :docket_date, :added_by_name, :added_by_css_id].freeze
  attr_accessor(*ATTRS)

  # The serializer requires a method with the name `id`
  def id
    appeal_id
  end

  def self.from_vacols(case_assignment, user_id)
    new(
      assigned_on: case_assignment.date_assigned,
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
      user_id: user_id
    )
  end
end
