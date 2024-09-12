# frozen_string_literal: true

class CaseSearchResultsForVeteranFileNumber < ::CaseSearchResultsBase
  def initialize(file_number_or_ssn:, user:)
    super(user: user)
    # Ensure we have a string made of solely numeric characters
    @file_number_or_ssn = file_number_or_ssn.to_s.gsub(/\D/, "") if file_number_or_ssn
  end

  private

  attr_reader :file_number_or_ssn

  def appeals
    if user.vso_employee?
      vso_user_search_results
    else
      search_results
    end
  end

  def vso_user_search_results
    SearchQueryService::VsoUserSearchResults.new(user: user, search_results: search_results).call
  end

  def search_results
    @search_results ||= SearchQueryService.new(file_number: file_number_or_ssn).search_by_veteran_file_number
  end

  def appeal_finder_appeals
    AppealFinder.new(user: user).find_appeals_for_veterans(veterans_user_can_access)
  end

  def file_number_or_ssn_presence
    return if file_number_or_ssn

    errors.add(:workflow, missing_veteran_file_number_or_ssn_error)
    @status = :bad_request
  end

  def missing_veteran_file_number_or_ssn_error
    {
      "title": "Veteran file number missing",
      "detail": "HTTP_CASE_SEARCH request header must include Veteran file number"
    }
  end

  def not_found_error
    {
      "title": "Veteran not found",
      "detail": "Could not find a Veteran matching the file number"
    }
  end

  def veterans
    return [] if file_number_or_ssn.blank?

    @veterans ||= VeteranFinder.find_or_create_all(file_number_or_ssn)
  end
end
