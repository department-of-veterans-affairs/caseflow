class Idt::V1::AppealDetailsSerializer < ActiveModel::Serializer
  def id
    object.vacols_id
  end

  attribute :veteran_first_name 
  attribute :veteran_middle_name do
    object.veteran_middle_initial
  end
  attribute :veteran_last_name
  attribute :appellant_not_veteran do
    !!object.appellant_first_name
  end
  attribute :appellant_first_name
  attribute :appellant_middle_name do
    object.appellant_middle_initial
  end
  attribute :appellant_last_name
  attribute :file_number do
    object.sanitized_vbms_id
  end
  attribute :docket_number
  attribute :number_of_issues do
    object.issues.length
  end

  attribute :representative_name do
    object.power_of_attorney.vacols_representative_name
  end  
  attribute :representative_type do
    object.power_of_attorney.vacols_representative_type
  end

  attribute :issues do
    object.issues.map do |issue|
      ActiveModelSerializers::SerializableResource.new(
        issue,
        serializer: ::WorkQueue::IssueSerializer
      ).as_json[:data][:attributes]
    end
  end

  attribute :aod
  attribute :cavc
  attribute :status
end
