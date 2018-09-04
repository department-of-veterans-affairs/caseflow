class Idt::V1::AppealDetailsSerializer < ActiveModel::Serializer
  def id
    object.is_a?(LegacyAppeal) ? object.vacols_id : object.uuid
  end

  attribute :veteran_first_name
  attribute :veteran_middle_name do
    object.veteran_middle_initial
  end
  attribute :veteran_last_name
  attribute :veteran_gender
  attribute :veteran_is_deceased

  attribute :appellant_is_not_veteran
  attribute :appellant_first_name
  attribute :appellant_middle_name do
    object.appellant_middle_initial
  end
  attribute :appellant_last_name
  attribute :appellant_name_suffix

  attribute :file_number do
    object.is_a?(LegacyAppeal) ? object.sanitized_vbms_id : object.veteran_file_number
  end
  attribute :citation_number
  attribute :docket_number
  attribute :number_of_issues

  attribute :issues do
    if object.is_a?(LegacyAppeal)
      object.issues.map do |issue|
        ActiveModelSerializers::SerializableResource.new(
          issue,
          serializer: ::WorkQueue::IssueSerializer
        ).as_json[:data][:attributes]
      end
    else
      object.request_issues
    end
  end

  # TODO: - expand rep name into separate fields
  attribute :representative_name do
    object.is_a?(LegacyAppeal) ? object.power_of_attorney.vacols_representative_name : object.representative_name
  end
  attribute :representative_type do
    object.is_a?(LegacyAppeal) ? object.power_of_attorney.vacols_representative_type : object.representative_type
  end

  attribute :advanced_on_docket
  attribute :cavc
  attribute :status
  attribute :previously_selected_for_quality_review

  attribute :outstanding_mail do
    object.is_a?(LegacyAppeal) ? object.outstanding_vacols_mail? : "not implemented"
  end
end
