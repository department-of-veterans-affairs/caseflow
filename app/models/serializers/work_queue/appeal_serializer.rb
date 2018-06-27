class WorkQueue::AppealSerializer < ActiveModel::Serializer
  attribute :issues do
    object.request_issues
  end

  attribute :hearings do
    []
  end

  attribute :appellant_full_name do
    "not implemented"
  end

  attribute :appellant_address do
    {
      address_line_1: "not implemented",
      address_line_2: "not implemented",
      city: "not implemented",
      state: "not implemented",
      zip: "not implemented",
      country: "not implemented"
    }
  end

  attribute :appellant_relationship do
    "not implemented"
  end

  attribute :location_code do
    "not implemented"
  end

  attribute :veteran_full_name do
    object.veteran ? object.veteran.name.formatted(:readable_full) : "Cannot locate"
  end

  attribute :veteran_date_of_birth do
    object.veteran ? object.veteran.date_of_birth : "Cannot locate"
  end

  attribute :veteran_gender do
    object.veteran ? object.veteran.sex : "Cannot locate"
  end

  attribute :vbms_id do
    object.veteran_file_number
  end

  attribute :vacols_id do
    object.uuid
  end

  attribute :type do
    nil
  end

  attribute :aod do
    "not implemented"
  end

  attribute :docket_number do
    object.docket_number
  end

  attribute :status do
    nil
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

  attribute :power_of_attorney do
    "not implemented"
  end

  attribute :regional_office do
    {
      key: "not implemented",
      city: "not implemented",
      state: "not implemented"
    }
  end

  attribute :caseflow_veteran_id do
    object.veteran ? object.veteran.id : nil
  end
end
