# frozen_string_literal: true

class CaseSearchResultsForVeteranFileNumber < ::CaseSearchResultsBase
  def initialize(file_number_or_ssn:, user:)
    super(user: user)
    # Ensure we have a string made of solely numeric characters
    @file_number_or_ssn = file_number_or_ssn.to_s.gsub(/\D/, "") if file_number_or_ssn
  end

  private

  attr_reader :file_number_or_ssn

  def validation_hook
    validate_file_number_or_ssn_presence
    validate_veterans_exist if current_user_is_vso_employee?
  end

  def validate_file_number_or_ssn_presence
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
