# frozen_string_literal: true

SearchQueryService::LegacyAttributes = Struct.new(
  :aod,
  :appellant_full_name,
  :assigned_attorney,
  :assigned_judge,
  :assigned_to_location,
  :caseflow_veteran_id,
  :decision_date,
  :docket_name,
  :docket_number,
  :external_id,
  :hearings,
  :issues,
  :mst,
  :overtime,
  :pact,
  :paper_case,
  :readable_hearing_request_type,
  :readable_original_hearing_request_type,
  :status,
  :type,
  :veteran_appellant_deceased,
  :veteran_file_number,
  :veteran_full_name,
  :withdrawn,
  keyword_init: true
)
