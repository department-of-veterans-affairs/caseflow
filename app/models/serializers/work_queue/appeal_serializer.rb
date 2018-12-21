class WorkQueue::AppealSerializer < ActiveModel::Serializer
  attribute :assigned_attorney
  attribute :assigned_judge

  attribute :timeline

  attribute :issues do
    object.eligible_request_issues.map do |issue|
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

  attribute :decision_issues do
    object.decision_issues.uniq.map do |issue|
      {
        id: issue.id,
        disposition: issue.disposition,
        description: issue.description,
        benefit_type: "compensation",
        remand_reasons: issue.remand_reasons,
        request_issue_ids: issue.request_decision_issues.pluck(:request_issue_id)
      }
    end
  end

  attribute :hearings do
    []
  end

  attribute :location_code do
    object.location_code
  end

  attribute :completed_hearing_on_previous_appeal? do
    false
  end

  attribute :appellant_full_name do
    object.claimants[0].name if object.claimants&.any?
  end

  attribute :appellant_address do
    if object.claimants&.any?
      object.claimants[0].address
    end
  end

  attribute :appellant_relationship do
    object.claimants[0].relationship if object.claimants&.any?
  end

  attribute :veteran_file_number do
    object.veteran_file_number
  end

  attribute :veteran_full_name do
    object.veteran ? object.veteran.name.formatted(:readable_full) : "Cannot locate"
  end

  attribute :external_id do
    object.uuid
  end

  attribute :type do
    "Original"
  end

  attribute :aod do
    object.advanced_on_docket
  end

  attribute :docket_name do
    object.docket_name
  end

  attribute :docket_number do
    object.docket_number
  end

  attribute :decision_date do
    object.decision_date
  end

  attribute :certification_date do
    nil
  end

  attribute :paper_case do
    false
  end

  attribute :regional_office do
  end

  attribute :caseflow_veteran_id do
    object.veteran ? object.veteran.id : nil
  end
end
