# frozen_string_literal: true

class WorkQueue::DecisionReviewSerializer
  include JSONAPI::Serializer
  attribute :issues do
    object.request_issues.active.map do |issue|
      {
        id: issue.id,
        disposition: issue.disposition,
        program: object.benefit_type,
        description: issue.description,
        notes: issue.notes,
        remand_reasons: issue.remand_reasons
      }
    end
  end

  attribute :type do
    object.class.name
  end

  attribute :external_id do
    object.id
  end

  attribute :veteran_full_name do
    object.veteran_full_name
  end

  attribute :veteran_file_number do
    object.veteran_file_number
  end

  attribute :external_appeal_id do
    object.external_id
  end

  attribute :aod do
    object.try(:advanced_on_docket?)
  end

  attribute :issue_count do
    object.number_of_issues
  end
end
