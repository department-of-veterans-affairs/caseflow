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

  attribute :appellant_is_not_veteran do
    object.is_a?(LegacyAppeal) ? object.appellant_is_not_veteran : object.claimant_not_veteran
  end

  attribute :appellants do
    if object.is_a?(LegacyAppeal)
      {
        first_name: object.appellant_first_name,
        middle_name: object.appellant_middle_initial,
        last_name: object.appellant_last_name,
        name_suffix: object.appellant_name_suffix
      }
    else
      object.claimants.map do |claimant|
        address = if @instance_options[:include_addresses] && !object.is_a?(LegacyAppeal)
          {
            address_line_1: claimant.address_line_1,
            address_line_2: claimant.address_line_2,
            city: claimant.city,
            state: claimant.state,
            zip: claimant.zip,
            country: claimant.country
          }
        else
          nil
        end

        {
          first_name: claimant.first_name,
          middle_name: claimant.middle_name,
          last_name: claimant.last_name,
          name_suffix: "",
          address: address
        }
      end
    end
  end

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
      object.request_issues.map do |issue|
        # Hard code program for October 1st Pilot, we don't have all the info for how we'll
        # break down request issues yet but all RAMP appeals will be 'compensation'
        { id: issue.id, disposition: issue.disposition, program: "Compensation", description: issue.description }
      end
    end
  end

  # TODO: - expand rep name into separate fields
  attribute :representative_name do
    object.is_a?(LegacyAppeal) ? object.power_of_attorney.vacols_representative_name : object.representative_name
  end
  attribute :representative_type do
    object.is_a?(LegacyAppeal) ? object.power_of_attorney.vacols_representative_type : object.representative_type
  end
  attribute :representative_address do
    if @instance_options[:include_addresses] && !object.is_a?(LegacyAppeal)
      object.representative_address
    else
      nil
    end
  end

  attribute :aod do
    object.advanced_on_docket
  end
  attribute :cavc
  attribute :status
  attribute :previously_selected_for_quality_review

  attribute :outstanding_mail do
    object.is_a?(LegacyAppeal) ? object.outstanding_vacols_mail? : false
  end
end
