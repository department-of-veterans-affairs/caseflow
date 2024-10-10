# frozen_string_literal: true

class SearchQueryService::AppealRow
  def initialize(query_row)
    @query_row = query_row
  end

  def search_response
    SearchQueryService::SearchResponse.new(
      queried_appeal,
      :appeal,
      SearchQueryService::ApiResponse.new(
        id: query_row["id"],
        type: "appeal",
        attributes: attributes
      )
    )
  end

  private

  attr_reader :query_row

  # rubocop:disable Metrics/MethodLength
  # rubocop:disable Metrics/AbcSize
  def attributes
    SearchQueryService::Attributes.new(
      aod: aod,
      appellant_full_name: appellant_full_name,
      appellant_date_of_birth: appellant_date_of_birth,
      appellant_email_address: appellant_person["email_address"],
      appellant_first_name: appellant_person["first_name"],
      appellant_hearing_email_recipient: json_array("hearing_email_recipient").first,
      appellant_is_not_veteran: !!queried_appeal.veteran_is_not_claimant,
      appellant_last_name: appellant_person["last_name"],
      appellant_middle_name: appellant_person["middle_name"],
      appellant_party_type: appellant_party_type,
      appellant_phone_number: appellant_phone_number,
      appellant_relationship: nil,
      appellant_substitution: nil,
      appellant_suffix: appellant_person["name_suffix"],
      appellant_type: appellant&.type,
      appellant_tz: nil,
      assigned_to_location: queried_appeal.assigned_to_location,
      assigned_attorney: assigned_attorney,
      assigned_judge: assigned_judge,
      caseflow_veteran_id: query_row["veteran_id"],
      contested_claim: contested_claim,
      decision_date: decision_date,
      decision_issues: decision_issues,
      docket_name: query_row["docket_type"],
      docket_number: docket_number,
      external_id: query_row["external_id"],
      hearings: hearings,
      issues: issues,
      mst: mst_status,
      overtime: query_row["overtime"],
      pact: pact_status,
      paper_case: false,
      readable_hearing_request_type: readable_hearing_request_type,
      readable_original_hearing_request_type: readable_original_hearing_request_type,
      status: queried_appeal.status,
      type: stream_type,
      veteran_appellant_deceased: veteran_appellant_deceased,
      veteran_file_number: veteran_file_number,
      veteran_full_name: veteran_full_name,
      withdrawn: withdrawn
    )
  end
  # rubocop:enable Metrics/AbcSize
  # rubocop:enable Metrics/MethodLength

  def appellant_date_of_birth
    if appellant.person.present?
      Date.parse appellant.person.try(:[], "date_of_birth")
    end
  rescue TypeError
    nil
  end

  def appellant_party_type
    appellant&.unrecognized_party_details.try(:[], "party_type")
  end

  def appellant_phone_number
    appellant&.unrecognized_party_details.try(:[], "phone_number")
  end

  def aod
    queried_appeal.advanced_on_docket_based_on_age? || query_row["aod_granted_for_person"]
  end

  def appellant_person
    appellant.person || {}
  end

  def appellant
    queried_appeal.claimant
  end

  def decision_issues
    json_array("decision_issues")
  end

  def docket_number
    attrs, = JSON.parse query_row["appeal"]
    attrs["stream_docket_number"]
  end

  def decision_date
    Date.parse(query_row["decision_date"])
  rescue TypeError, Date::Error
    nil
  end

  def appellant_full_name
    FullName.new(query_row["person_first_name"], "", query_row["person_last_name"]).to_s
  end

  def veteran_full_name
    FullName.new(query_row["veteran_first_name"], "", query_row["veteran_last_name"]).to_s
  end

  def veteran_file_number
    attrs, = JSON.parse(query_row["appeal"])
    attrs["veteran_file_number"]
  end

  def clean_issue_attributes!(attributes)
    unless FeatureToggle.enabled?(:pact_identification)
      attributes.delete("pact_status")
    end
    unless FeatureToggle.enabled?(:mst_identification)
      attributes.delete("mst_status")
    end
  end

  def issues
    json_array("request_issues").map do |attributes|
      attributes.tap do |attrs|
        clean_issue_attributes!(attrs)
      end
    end
  end

  def hearings
    json_array("hearings").map do |attrs|
      AppealHearingSerializer.new(
        SearchQueryService::QueriedHearing.new(attrs),
        { user: RequestStore[:current_user] }
      ).serializable_hash[:data][:attributes]
    end
  end

  def withdrawn
    WithdrawnDecisionReviewPolicy.new(
      Struct.new(
        :active_request_issues,
        :withdrawn_request_issues
      ).new(
        json_array("active_request_issues"),
        json_array("active_request_issues")
      )
    ).satisfied?
  end

  def stream_type
    (query_row["stream_type"] || "Original").titleize
  end

  def contested_claim
    json_array("active_request_issues").any? do |issue|
      %w(Contested Apportionment).any? do |code|
        category = issue["nonrating_issue_category"] || ""
        category.include?(code)
      end
    end
  end

  def veteran_appellant_deceased
    !!query_row["date_of_death"] && !json_array("appeal").first["veteran_is_not_claimant"]
  end

  def pact_status
    json_array("decision_issues").any? do |issue|
      issue["pact_status"]
    end
  end

  def mst_status
    json_array("decision_issues").any? do |issue|
      issue["mst_status"]
    end
  end

  def readable_original_hearing_request_type
    queried_appeal.readable_original_hearing_request_type
  end

  def readable_hearing_request_type
    queried_appeal.readable_current_hearing_request_type
  end

  def queried_appeal
    @queried_appeal ||= begin
      appeal_attrs, = JSON.parse query_row["appeal"]

      SearchQueryService::QueriedAppeal.new(
        attributes: appeal_attrs,
        tasks_attributes: json_array("tasks"),
        hearings_attributes: json_array("hearings")
      )
    end
  end

  def assigned_attorney
    json_array("assigned_attorney").first
  end

  def assigned_judge
    json_array("assigned_judge").first
  end

  def json_array(key)
    JSON.parse(query_row[key] || "[]")
  end
end
