class WorkQueue::HigherLevelReviewSerializer < ActiveModel::Serializer

  attribute :issues do
    object.request_issues.map do |issue|
      # Hard code program for October 1st Pilot, we don't have all the info for how we'll
      # break down request issues yet but all RAMP appeals will be 'compensation'
      {
        id: issue.id,
        disposition: issue.disposition,
        program: "compensation",
        description: issue.description,
        notes: issue.notes,
        remand_reasons: issue.remand_reasons
      }
    end
  end

  attribute :type do
    "HigherLevelReview"
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
    object.try(:advanced_on_docket)
  end

  attribute :issue_count do
    object.number_of_issues
  end
end
