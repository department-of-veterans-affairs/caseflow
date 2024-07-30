# frozen_string_literal: true

class CaseSearchResultsForDocketNumber < ::CaseSearchResultsBase
  validate :veterans_exist, if: :current_user_is_vso_employee?

  def initialize(docket_number:, user:)
    super(user: user)
    @docket_number = docket_number.to_s if docket_number
  end

  protected

  def claim_reviews
    []
  end

  def appeals
    AppealFinder.find_appeals_by_docket_number(docket_number)
  end

  private

  attr_reader :docket_number

  def not_found_error
    {
      "title": "Docket ID not found",
      "detail": "Could not find a case matching the docket number"
    }
  end

  def veterans
    # Determine vet that corresponds to docket number so we can validate user can access
    @file_numbers_for_appeals ||= appeals.map(&:veteran_file_number)
    @veterans ||= VeteranFinder.find_or_create_all(@file_numbers_for_appeals)
  end
end
