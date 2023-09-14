# frozen_string_literal: true

class WorkQueue::RegionalOfficeTaskSerializer < WorkQueue::TaskSerializer
  include JSONAPI::Serializer

  attribute :previous_task do
    {
      assigned_at: nil
    }
  end

  attribute(:document_id) { nil }

  attribute :decision_prepared_by do
    {
      first_name: nil,
      last_name: nil
    }
  end

  attribute(:available_actions) { [] }
end
