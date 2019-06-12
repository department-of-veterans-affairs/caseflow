# frozen_string_literal: true

class CaseSearchResultsForVeteranFileNumber < ::CaseSearchResultsBase
  validate :file_number_or_ssn_presence
  validate :veteran_exists, if: :current_user_is_vso_employee?

  def initialize(file_number_or_ssn:, user:)
    super(user: user)
    @file_number_or_ssn = file_number_or_ssn.to_s
  end

  protected

  def appeals
    VeteranFinderQuery.new(user: user).find_appeals_for_veterans(veterans: veterans)
  end

  def claim_reviews
    veteran_file_numbers = veterans.map(&:file_number)

    ClaimReview.find_all_visible_by_file_number(*veteran_file_numbers).map(&:search_table_ui_hash)
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
      "detail": "HTTP_VETERAN_ID request header must include Veteran file number"
    }
  end

  def veteran_exists
    return unless veterans.empty?

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
    @veterans ||= VeteranFinderQuery.find_by_ssn_or_file_number(file_number_or_ssn: file_number_or_ssn)
  end

  def current_user_is_vso_employee?
    user.vso_employee?
  end
end
