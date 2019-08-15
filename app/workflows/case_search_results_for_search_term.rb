# frozen_string_literal: true

class CaseSearchResultsForSearchTerm < ::CaseSearchResultsBase
  validate :search_term_presence
  validate :veterans_exist, if: :current_user_is_vso_employee?

  def initialize(search_term:, user:)
    super(user: user)
    @search_term = search_term.to_s if search_term
  end

  protected

  def claim_reviews
    if docket_number?
      []
    else
      veteran_file_numbers = veterans_user_can_access.map(&:file_number)

      ClaimReview.find_all_visible_by_file_number(*veteran_file_numbers)
    end
  end

  def appeals
    if docket_number?
      Array.wrap(AppealFinder.new(user: user).find_appeal_by_docket_number(search_term))
    else
      AppealFinder.new(user: user).find_appeals_for_veterans(veterans_user_can_access)
    end
  end

  private

  attr_reader :search_term

  def search_term_presence
    return if search_term

    errors.add(:workflow, missing_search_term)
    @status = :bad_request
  end

  def missing_search_term
    {
      "title": "Search term missing",
      "detail": "HTTP_CASE_SEARCH request header must include search term"
    }
  end

  def veterans_exist
    return unless veterans_user_can_access.empty?

    errors.add(:workflow, not_found_error)
    @status = :not_found
  end

  def not_found_error
    if docket_number?
      {
        "title": "Docket ID not found",
        "detail": "Could not find a case matching the docket number"
      }
    else
      {
        "title": "Veteran not found",
        "detail": "Could not find a Veteran matching the file number"
      }
    end
  end

  def veterans
    if docket_number?
      # Determine vet that corresponds to docket number so we can validate user can access
      @file_numbers_for_appeals ||= appeals.map(&:veteran_file_number)
      @veterans ||= VeteranFinder.find_or_create_all(@file_numbers_for_appeals)
    else
      file_number_or_ssn = search_term.gsub(/\D/, "")
      @veterans ||= VeteranFinder.find_or_create_all(file_number_or_ssn)
    end
  end

  def prohibited_error
    if docket_number?
      {
        "title": "Access to Veteran file prohibited",
        "detail": "You do not have access to this docket number"
      }
    else
      {
        "title": "Access to Veteran file prohibited",
        "detail": "You do not have access to this claims file number"
      }
    end
  end

  def docket_number?
    !@search_term.nil? && @search_term.match?(/\d{6}-{1}\d+$/)
  end
end
