class WorkQueue::AppealSerializer < ActiveModel::Serializer
  attribute :assigned_attorney
  attribute :assigned_judge

  attribute :issues do
    object.request_issues
  end

  attribute :hearings do
    []
  end

  attribute :appellant_full_name do
    object.claimants[0].name if object.claimants && object.claimants.any?
  end

  attribute :appellant_address do
    if object.claimants && object.claimants.any?
      object.claimants[0].address
    end
  end

  attribute :appellant_relationship do
    object.claimants[0].relationship if object.claimants && object.claimants.any?
  end

  attribute :veteran_full_name do
    object.veteran ? object.veteran.name.formatted(:readable_full) : "Cannot locate"
  end

  attribute :veteran_date_of_birth do
    object.veteran ? object.veteran.date_of_birth : "Cannot locate"
  end

  attribute :veteran_date_of_death do
    object.veteran ? object.veteran.date_of_death : "Cannot locate"
  end

  attribute :veteran_gender do
    object.veteran ? object.veteran.sex : "Cannot locate"
  end

  attribute :veteran_file_number do
    object.veteran_file_number
  end

  attribute :external_id do
    object.uuid
  end

  attribute :type do
    "BEAAM"
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
    nil
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
