# frozen_string_literal: true

#:reek:TooManyInstanceVariables
class Api::V3::VbmsIntake::Ama::VbmsAmaDtoBuilder
  attr_reader :json_response

  # TODO: add method for legacy
  def initialize(veteran_participant_id, page)
    @page = page
    @veteran_participant_id = veteran_participant_id.to_s
    @request_issue_count = total_request_issue_count
    @request_issues = serialized_request_issues
    @offset = RequestIssue.default_per_page
    @json_response = build_json_response
  end

  private

  def total_request_issue_count
    RequestIssue.where(veteran_participant_id: @veteran_participant_id).count
  end

  def serialized_request_issues
    Api::V3::VbmsIntake::Ama::RequestIssueSerializer.new(
      RequestIssue.includes(:decision_issues).where(veteran_participant_id: @veteran_participant_id).page(@page)
    ).serializable_hash[:data]
  end

  def build_json_response
    {
      "page": @page,
      "total_nubmer_of_pages": (@request_issue_count / @offset.to_f).ceil,
      "total_request_issues_for_vet": @request_issue_count,
      "max_request_issues_per_page": @offset,
      "veteran_participant_id": @veteran_participant_id,
      "legacy_appeals_present": false,
      "request_issues": @request_issues.to_json
    }.to_json
  end
end
