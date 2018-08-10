class Idt::V1::AppealDetailsSerializer < ActiveModel::Serializer
  def id
    object.vacols_id
  end

  attribute :veteran_first_name
  attribute :veteran_middle_name do
    object.veteran_middle_initial
  end
  attribute :veteran_last_name
  attribute :veteran_gender
  attribute :veteran_is_deceased do
    !!object.notice_of_death_date
  end

  attribute :appellant_is_not_veteran do
    !!object.appellant_first_name
  end
  attribute :appellant_first_name
  attribute :appellant_middle_name do
    object.appellant_middle_initial
  end
  attribute :appellant_last_name
  attribute :appellant_name_suffix
  attribute :file_number do
    object.sanitized_vbms_id
  end
  attribute :citation_number
  attribute :docket_number
  attribute :number_of_issues do
    object.issues.length
  end
  attribute :issues do
    object.issues.map do |issue|
      ActiveModelSerializers::SerializableResource.new(
        issue,
        serializer: ::WorkQueue::IssueSerializer
      ).as_json[:data][:attributes]
    end
  end

  attribute :representative do
    {
      type: object.power_of_attorney.vacols_representative_type,
      org_name: object.power_of_attorney.vacols_org_name,
      first_name: object.power_of_attorney.vacols_first_name,
      middle_initial: object.power_of_attorney.vacols_middle_initial,
      last_name: object.power_of_attorney.vacols_last_name,
      suffix: object.power_of_attorney.vacols_suffix
    }
  end

  attribute :aod
  attribute :cavc
  attribute :status

  # TODO: add outstanding mail
  # TODO: add document numbers
end
