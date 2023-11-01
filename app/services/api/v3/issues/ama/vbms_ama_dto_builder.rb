# frozen_string_literal: true

#:reek:TooManyInstanceVariables
class Api::V3::VbmsIntake::Ama::VbmsAmaDtoBuilder
  attr_reader :json_response

  def initialize(veteran, page)
    @page = page
    @veteran_participant_id = veteran.participant_id.to_s
    @request_issue_count = total_request_issue_count
    @request_issues = serialized_request_issues
    @offset = RequestIssue.default_per_page
    @legacy_appeals_present_boolean = legacy_appeals_present?(veteran)
    @json_response = build_json_response
  end

  private

  def total_request_issue_count
    RequestIssue.where(veteran_participant_id: @veteran_participant_id).count
  end

  def serialized_request_issues
    serialized_data = Api::V3::VbmsIntake::Ama::RequestIssueSerializer.new(
      RequestIssue.includes(:decision_issues).where(veteran_participant_id: @veteran_participant_id).page(@page)
    ).serializable_hash[:data]

    serialized_data.map { |issue| issue[:attributes] }
  end

  def legacy_appeals_present?(veteran)
    LegacyAppeal.veteran_has_appeals_in_vacols?(veteran.file_number)
  end

  def build_json_response
    {
      "page": @page,
      "total_number_of_pages": (@request_issue_count / @offset.to_f).ceil,
      "total_request_issues_for_vet": @request_issue_count,
      "max_request_issues_per_page": @offset,
      "veteran_participant_id": @veteran_participant_id,
      "legacy_appeals_present": @legacy_appeals_present_boolean,
      "request_issues": @request_issues
    }.to_json
  end
end
