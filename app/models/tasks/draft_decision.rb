class DraftDecision
  include ActiveModel::Model
  include ActiveModel::Serialization

  # TODO: move to generic superclass
  ATTRS = [:appeal_id, :user_id, :due_on, :assigned_on, :docket_name, :docket_date]
  attr_accessor(*ATTRS)

  def type
    "DraftDecision"
  end

  def complete!
    # update VACOLS assignments
  end

  # TODO: move to generic superclass
  def to_hash
    serializable_hash
  end

  # TODO: move to generic superclass
  def attributes
    DraftDecision::ATTRS.each_with_object({}) { |attr, obj| obj[attr] = send(attr) }
  end
end
