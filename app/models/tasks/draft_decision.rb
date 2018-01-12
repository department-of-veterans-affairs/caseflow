class DraftDecision
  include ActiveModel::Model
  include ActiveModel::Serialization

  # TODO: move to generic superclass
  ATTRS = [:appeal, :appeal_id, :user_id, :due_on, :assigned_on, :docket_name, :docket_date].freeze
  attr_accessor(*ATTRS)

  # TODO: move to generic superclass
  def to_hash
    serializable_hash
  end

  # TODO: move to generic superclass
  def attributes
    DraftDecision::ATTRS.each_with_object({}) { |attr, obj| obj[attr] = send(attr) }
  end

  def self.from_vacols(case_assignment, user_id)
    new(
      assigned_on: case_assignment.date_assigned,
      due_on: case_assignment.date_due,
      docket_name: "legacy",
      docket_date: case_assignment.docket_date,
      appeal_id: case_assignment.vacols_id,
      user_id: user_id
    )
  end
end
