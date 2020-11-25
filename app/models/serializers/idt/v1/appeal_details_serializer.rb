# frozen_string_literal: true

class Idt::V1::AppealDetailsSerializer
  include FastJsonapi::ObjectSerializer
  set_id do |object|
    object.is_a?(LegacyAppeal) ? object.vacols_id : object.uuid
  end

  attribute :case_details_url do |object, params|
    "#{params[:base_url]}/queue/appeals/#{object.external_id}"
  end

  attribute :veteran_first_name
  attribute :veteran_middle_name, &:veteran_middle_initial
  attribute :veteran_last_name
  attribute :veteran_name_suffix
  attribute :veteran_gender
  attribute :veteran_ssn
  attribute :veteran_is_deceased
  attribute :veteran_death_date

  attribute :appellant_is_not_veteran

  attribute :appellants do |object, params|
    if object.is_a?(LegacyAppeal)
      [object.claimant]
    else
      object.claimants.map do |claimant|
        address = if params[:include_addresses]
                    {
                      address_line_1: claimant.address_line_1,
                      address_line_2: claimant.address_line_2,
                      address_line_3: claimant.address_line_3,
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
          address: params[:include_addresses] ? claimant.representative_address : nil
        }

        {
          first_name: claimant.first_name,
          middle_name: claimant.middle_name,
          last_name: claimant.last_name,
          full_name: claimant.last_name.present? ? nil : claimant.name&.upcase,
          name_suffix: "",
          address: address,
          representative: claimant.representative_name ? representative : nil
        }
      end
    end
  end

  attribute :contested_claimants do |object|
    object.is_a?(LegacyAppeal) ? object.contested_claimants : nil
  end

  attribute :contested_claimant_agents do |object|
    object.is_a?(LegacyAppeal) ? object.contested_claimant_agents : nil
  end

  attribute :congressional_interest_addresses do |object|
    object.is_a?(LegacyAppeal) ? object.congressional_interest_addresses : "Not implemented for AMA"
  end

  attribute :file_number do |object|
    object.is_a?(LegacyAppeal) ? object.sanitized_vbms_id : object.veteran_file_number
  end
  attribute :docket_number
  attribute :docket_name
  attribute :number_of_issues

  attribute :issues do |object|
    if object.is_a?(LegacyAppeal)
      object.issues.map do |issue|
        ::WorkQueue::LegacyIssueSerializer.new(issue).serializable_hash[:data][:attributes]
      end
    else
      object.request_issues.active_or_decided_or_withdrawn.map do |issue|
        {
          id: issue.id,
          program: Constants::BENEFIT_TYPES[issue.benefit_type],
          description: issue.description
        }
      end
    end
  end

  attribute :aod, &:advanced_on_docket?
  attribute :cavc
  attribute :status
  attribute :previously_selected_for_quality_review
  attribute :assigned_by, &:reviewing_judge_name

  attribute :documents do |object|
    object.attorney_case_reviews.sort_by(&:updated_at).reverse.map do |document|
      { written_by: document.written_by_name, document_id: document.document_id }
    end
  end

  attribute :outstanding_mail do |object|
    object.is_a?(LegacyAppeal) ? object.outstanding_vacols_mail : "not implemented for AMA"
  end
end
