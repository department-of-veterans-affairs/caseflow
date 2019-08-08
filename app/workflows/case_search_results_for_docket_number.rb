# frozen_string_literal: true

class CaseSearchResultsForDocketNumber < ::CaseSearchResultsBase
  validate :docket_number_presence
  validate :veterans_exist, if: :current_user_is_vso_employee?

  def initialize(docket_number:, user:)
    super(user: user)
    @docket_number = docket_number.to_s if docket_number
  end

  protected

  def appeals
    @appeals = AppealFinder.new(user: user).find_appeals_by_docket_number(docket_number)
    return @appeals
  end

  def claim_reviews
    veteran_file_numbers = veterans_user_can_access.map(&:file_number)

    ClaimReview.find_all_visible_by_file_number(*veteran_file_numbers)
  end

  private

  attr_reader :docket_number

  def docket_number_presence
    return if docket_number

    errors.add(:workflow, missing_docket_number_error)
    @status = :bad_request
  end

  def missing_docket_number_error
    {
      "title": "Docket number missing",
      "detail": "HTTP_CASE_SEARCH request header must include docket number"
    }
  end

  def veterans_exist
    return unless veterans_user_can_access.empty?

    errors.add(:workflow, not_found_error)
    @status = :not_found
  end

  def not_found_error
    {
      "title": "Docket ID not found",
      "detail": "Could not find a case matching the docket number"
    }
  end

  def veterans
    # Determine vet that corresponds to docket number so we can validate user can access
    @file_numbers_for_appeals ||= appeals.map(&:veteran_file_number).uniq
    @veterans ||= VeteranFinder.find_or_create_all(@file_numbers_for_appeals)
  end
end
