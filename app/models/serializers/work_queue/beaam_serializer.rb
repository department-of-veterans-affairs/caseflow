# frozen_string_literal: true

class WorkQueue::BeaamSerializer
  include FastJsonapi::ObjectSerializer
  attribute :previous_task do
    {
      assigned_on: nil
    }
  end

  attribute :assigned_by do
    {
      first_name: nil,
      last_name: nil,
      pg_id: nil
    }
  end

  attribute :assigned_to do
    {
      css_id: nil,
      type: nil,
      id: nil
    }
  end

  attribute :docket_name

  attribute :case_type do
    "BEAAM"
  end

  attribute :docket_number
  attribute :veteran_full_name, &:veteran_name
  attribute :veteran_file_number
  attribute :external_appeal_id, &:external_id
  attribute :aod, &:advanced_on_docket

  attribute :issue_count do |object|
    object.request_issues.active.count
  end
end
