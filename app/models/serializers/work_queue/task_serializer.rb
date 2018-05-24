class WorkQueue::TaskSerializer < ActiveModel::Serializer
  attribute :assigned_on do
    "not implemented"
  end
  attribute :due_on do
    "not implemented"
  end
  attribute :docket_name do
    "not implemented"
  end
  attribute :docket_date do
    "not implemented"
  end
  attribute :appeal_id
  attribute :user_id do
    "not implemented"
  end
  attribute :added_by_name do
    "not implemented"
  end
  attribute :added_by_css_id do
    "not implemented"
  end
  attribute :task_id do
    rand(10000)
  end
  attribute :task_type do
    object.type
  end
  attribute :document_id do
    "not implemented"
  end
  attribute :assigned_by_first_name do
    "not implemented"
  end
  attribute :assigned_by_last_name do
    "not implemented"
  end
end
