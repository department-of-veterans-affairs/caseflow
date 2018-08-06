class WorkQueue::BeaamSerializer < ActiveModel::Serializer
  attribute :previous_task do
    {
      assigned_on: nil
    }
  end

  attribute :docket_name do
    object.docket_name
  end

  attribute :case_type do
    object.type
  end

  attribute :docket_number do
    object.docket_number
  end

  attribute :veteran_full_name do
    object.veteran_name
  end

  attribute :veteran_file_number do
    object.veteran_file_number
  end

  attribute :external_appeal_id do
    object.external_id
  end

  attribute :aod do
    object.advanced_on_docket
  end

  attribute :issue_count do
    object.request_issues.count
  end
end
