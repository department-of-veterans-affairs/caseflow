class Idt::V1::AppealDetailsSerializer < ActiveModel::Serializer
  def id
    object.is_a?(LegacyAppeal) ? object.vacols_id : object.uuid
  end

  attribute :case_details_url do
    "#{@instance_options[:base_url]}/queue/appeals/#{object.external_id}"
  end

  attribute :veteran_first_name
  attribute :veteran_middle_name do
    object.veteran_middle_initial
  end
  attribute :veteran_last_name
  attribute :veteran_name_suffix
  attribute :veteran_gender
  attribute :veteran_ssn

  attribute :veteran_is_deceased
  attribute :veteran_death_date

  attribute :appellant_is_not_veteran do
    object.is_a?(LegacyAppeal) ? object.appellant_is_not_veteran : object.claimant_not_veteran
  end

  attribute :appellants do
    if object.is_a?(LegacyAppeal)
      [object.claimant]
    else
      object.claimants.map do |claimant|
        address = if @instance_options[:include_addresses]
                    {
                      address_line_1: claimant.address_line_1,
                      address_line_2: claimant.address_line_2,
                      city: claimant.city,
                      state: claimant.state,
                      zip: claimant.zip,
                      country: claimant.country
                    }
                  end
        representative = {
          name: claimant.representative_name,
          type: claimant.representative_type,
          participant_id: claimant.representative_participant_id,
          address: @instance_options[:include_addresses] ? claimant.representative_address : nil
        }

        {
          first_name: claimant.first_name,
          middle_name: claimant.middle_name,
          last_name: claimant.last_name,
          name_suffix: "",
          address: address,
          representative: claimant.representative_name ? representative : nil
        }
      end
    end
  end

  attribute :contested_claimants do
    object.is_a?(LegacyAppeal) ? object.contested_claimants : nil
  end

  attribute :contested_claimant_agents do
    object.is_a?(LegacyAppeal) ? object.contested_claimant_agents : nil
  end

  attribute :congressional_interest_addresses do
    object.is_a?(LegacyAppeal) ? object.congressional_interest_addresses : "Not implemented for AMA"
  end

  attribute :file_number do
    object.is_a?(LegacyAppeal) ? object.sanitized_vbms_id : object.veteran_file_number
  end
  attribute :docket_number
  attribute :docket_name
  attribute :number_of_issues

  attribute :issues do
    if object.is_a?(LegacyAppeal)
      object.issues.map do |issue|
        ActiveModelSerializers::SerializableResource.new(
          issue,
          serializer: ::WorkQueue::LegacyIssueSerializer
        ).as_json[:data][:attributes]
      end
    else
      object.request_issues.map do |issue|
        { 
          id: issue.id, 
          disposition: issue.disposition, 
          program: Constants::BENEFIT_TYPES[issue.benefit_type], 
          description: issue.description 
        }
      end
    end
  end

  attribute :aod do
    object.advanced_on_docket
  end
  attribute :cavc
  attribute :status
  attribute :previously_selected_for_quality_review

  attribute :assigned_by do
    object.reviewing_judge_name
  end

  attribute :documents do
    object.attorney_case_reviews.map do |document|
      { written_by: document.written_by_name, document_id: document.document_id }
    end
  end

  attribute :outstanding_mail do
    object.is_a?(LegacyAppeal) ? object.outstanding_vacols_mail : "not implemented for AMA"
  end
end
