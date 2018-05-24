class WorkQueue::AppealSerializer < ActiveModel::Serializer
  attribute :issues do
    []
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
    "not implemented"
  end

  attribute :type do
    "not implemented"
  end

  attribute :aod do
    "not implemented"
  end

  attribute :docket_number do
    "not implemented"
  end

  attribute :status do
    "not implemented"
  end

  attribute :decision_date do
    "not implemented"
  end

  attribute :certification_date do
    "not implemented"
  end

  attribute :paper_case do
    "not implemented"
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
