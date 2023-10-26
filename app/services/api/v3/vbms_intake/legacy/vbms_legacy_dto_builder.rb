# frozen_string_literal: true

class Api::V3::VbmsIntake::Legacy::VbmsLegacyDtoBuilder
  attr_reader :json_response

  def initialize(veteran, page)
    @page = page
    @veteran_participant_id = veteran.participant_id.to_s
    @veteran_file_number = veteran.file_number.to_s
    @vacols_issue_count = total_vacols_issue_count
    @vacols_issues = serialized_vacols_issues
    @offset = RequestIssue.default_per_page
    @json_response = build_json_response
  end

  private

  def total_vacols_issue_count
    vacols_cases = VACOLS::Case.where(bfcorlid: @veteran_file_number)
    vacols_ids = vacols_cases.map(&:bfkey)
    VACOLS::CaseIssue.where(isskey: vacols_ids).size
  end

  def serialized_vacols_issues
    vacols_issues = []
    v_ids = LegacyAppeal.fetch_appeals_by_file_number(@veteran_file_number).map(&:vacols_id)
    las = LegacyAppeal.where(vacols_id: v_ids)
    las.each do |la|
      vacols_issues.concat(la.issues.map(&:vbms_attributes))
    end
    serialized_data = Api::V3::VbmsIntake::Legacy::VacolsIssueSerializer.new(
      vacols_issues
    ).page(@page).serializable_hash[:data]

    serialized_data.map { |issue| issue[:attributes] }
  end

  def build_json_response
    {
      "page": @page,
      "total_number_of_pages": (@vacols_issue_count / @offset.to_f).ceil,
      "total_vacols_issues_for_vet": @vacols_issue_count,
      "max_vacols_issues_per_page": @offset,
      "veteran_participant_id": @veteran_participant_id,
      "veteran_file_number": @veteran_file_number,
      "vacols_issues": @vacols_issues
    }.to_json
  end
end
