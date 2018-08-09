class WorkQueue::AppealSerializer < ActiveModel::Serializer
  attribute :is_legacy_appeal do
    false
  end

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
      primary_appellant = object.claimants[0]
      {
        address_line_1: primary_appellant.address_line_1,
        address_line_2: primary_appellant.address_line_2,
        city: primary_appellant.city,
        state: primary_appellant.state,
        zip: primary_appellant.zip,
        country: primary_appellant.country
      }
    end
  end

  attribute :appellant_relationship do
    object.claimants[0].relationship if object.claimants && object.claimants.any?
  end

  attribute :location_code do
    "Not supported for BEAAM appeals"
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

  attribute :external_id do
    object.uuid
  end

  attribute :type do
    "BEAAM"
  end

  attribute :aod do
    object.advanced_on_docket
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
    {
      representative_type: object.representative_type,
      representative_name: object.representative_name
    }
  end

  attribute :regional_office do
  end

  attribute :caseflow_veteran_id do
    object.veteran ? object.veteran.id : nil
  end
end
