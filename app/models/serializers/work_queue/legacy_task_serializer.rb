class WorkQueue::LegacyTaskSerializer < ActiveModel::Serializer
  attribute :is_legacy do
    true
  end
  attribute :type do
    object.class.name
  end
  attribute :assigned_on
  attribute :due_on
  attribute :docket_name
  attribute :docket_date
  attribute :appeal_id
  attribute :user_id
  attribute :added_by_name
  attribute :added_by_css_id
  attribute :task_id
  attribute :label
  attribute :document_id
  attribute :work_product
  attribute :appeal_type
  attribute :previous_task do
    {
      assigned_on: object.previous_task.try(:assigned_at)
    }
  end

  attribute :assigned_by do
    {
      first_name: object.assigned_by_first_name,
      last_name: object.assigned_by_last_name,
      css_id: object.assigned_by_css_id,
      pg_id: object.assigned_by_pg_id
    }
  end

  attribute :assigned_to do
    {
      css_id: object.user_id,
      type: "User",
      id: object.assigned_to_pg_id
    }
  end

  attribute :case_type do
    object.appeal.type
  end

  attribute :aod do
    object.appeal.aod
  end

  attribute :external_appeal_id do
    object.appeal.vacols_id
  end

  attribute :docket_number do
    object.appeal.docket_number
  end

  attribute :veteran_full_name do
    object.appeal.veteran_full_name
  end

  attribute :veteran_file_number do
    object.appeal.veteran_file_number
  end

  attribute :issue_count do
    object.appeal.undecided_issues.count
  end

  attribute :paper_case do
    object.appeal.file_type.eql? "Paper"
  end

  attribute :available_actions do
    object.available_actions(@instance_options[:role])
  end
end
