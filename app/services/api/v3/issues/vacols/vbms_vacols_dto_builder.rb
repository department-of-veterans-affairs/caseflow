# frozen_string_literal: true

#:reek:TooManyInstanceVariables
class Api::V3::Issues::Vacols::VbmsVacolsDtoBuilder
  attr_reader :hash_response, :vacols_issue_count

  def initialize(veteran, page, per_page)
    @page = page
    @veteran_participant_id = veteran.participant_id&.to_s
    @veteran_file_number = veteran.file_number&.to_s
    @vacols_issue_count = total_vacols_issue_count
    # LegacyIssues will be consistent with AMA RequestIssues
    @offset = per_page.presence || RequestIssue.default_per_page
    @total_number_of_pages = (@vacols_issue_count / @offset.to_f).ceil
    @vacols_issues = serialized_vacols_issues
    @hash_response = build_hash_response
  end

  private

  def total_vacols_issue_count
    vacols_veteran_file_number = LegacyAppeal.convert_file_number_to_vacols(@veteran_file_number)
    vacols_cases = VACOLS::Case.where(bfcorlid: vacols_veteran_file_number)
    vacols_ids = vacols_cases.map(&:bfkey)
    VACOLS::CaseIssue.where(isskey: vacols_ids).size
  end

  def serialized_vacols_issues(page = @page, offset = @offset)
    vacols_issues = []
    v_ids = LegacyAppeal.fetch_appeals_by_file_number(@veteran_file_number).map(&:vacols_id)
    v_ids.each do |id|
      vacols_issues.push(AppealRepository.issues(id))
    end

    serialized_data = Api::V3::Issues::Vacols::VacolsIssueSerializer.new(
      Kaminari.paginate_array(vacols_issues.flatten).page(page).per(offset)
    ).serializable_hash[:data]

    extract_vacols_issues(serialized_data)
  end

  def extract_vacols_issues(serialized_data)
    wanted_attributes = serialized_data.map { |issue| issue[:attributes] }

    wanted_attributes.map { |issue| issue[:vacols_issue] }
  end

  def build_hash_response
    if @page > @total_number_of_pages
      @page = @total_number_of_pages
      @vacols_issues = serialized_vacols_issues(@total_number_of_pages, @offset)
    end
    json_response
  end

  def json_response
    {
      "page": @page,
      "total_number_of_pages": @total_number_of_pages,
      "total_vacols_issues_for_vet": @vacols_issue_count,
      "max_vacols_issues_per_page": @offset,
      "veteran_participant_id": @veteran_participant_id,
      "veteran_file_number": @veteran_file_number,
      "vacols_issues": @vacols_issues
    }.to_json
  end
end
