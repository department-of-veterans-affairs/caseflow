# frozen_string_literal: true

class CaseSearchResultsForVeteranFileNumber < ::CaseSearchResultsBase
  validate :file_number_or_ssn_presence
  validate :veterans_exist, if: :current_user_is_vso_employee?

  def initialize(file_number_or_ssn:, user:)
    super(user: user)
    # Ensure we have a string made of solely numeric characters
    @file_number_or_ssn = file_number_or_ssn.to_s.gsub(/\D/, "") if file_number_or_ssn
  end

  protected

  def appeals
    AppealFinder.new(user: user).find_appeals_for_veterans(veterans_user_can_access)
  end

  def claim_reviews
    veteran_file_numbers = veterans_user_can_access.map(&:file_number)

    ClaimReview.find_all_visible_by_file_number(*veteran_file_numbers)
  end

  private

  attr_reader :file_number_or_ssn

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

  def veterans_exist
    return unless veterans_user_can_access.empty?

    errors.add(:workflow, not_found_error)
    @status = :not_found
  end

  def not_found_error
    {
      "title": "Veteran not found",
      "detail": "Could not find a Veteran matching the file number"
    }
  end

  def veterans
    @veterans ||= VeteranFinder.find_or_create_all(file_number_or_ssn)
  end
end
