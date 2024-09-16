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
  def attributes
    SearchQueryService::Attributes.new(
      aod: aod,
      appellant_full_name: appellant_full_name,
      assigned_to_location: queried_appeal.assigned_to_location,
      assigned_attorney: assigned_attorney,
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
      status: queried_appeal.status,
      type: stream_type,
      veteran_appellant_deceased: veteran_appellant_deceased,
      veteran_file_number: veteran_file_number,
      veteran_full_name: veteran_full_name,
      withdrawn: withdrawn
    )
  end
  # rubocop:enable Metrics/MethodLength

  def aod
    query_row["aod_granted_for_person"].present?
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

  def issue(attributes)
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
        issue(attrs)
      end
    end
  end

  def hearings
    json_array("hearings")
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

  def json_array(key)
    JSON.parse(query_row[key] || "[]")
  end
end
