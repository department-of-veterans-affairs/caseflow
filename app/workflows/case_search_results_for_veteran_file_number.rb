# frozen_string_literal: true

class CaseSearchResultsForVeteranFileNumber
  include ActiveModel::Validations
  include ValidateVsoEmployeeCanAccessFileNumber

  validate :file_number_presence
  validate :veteran_exists, if: :current_user_is_vso_employee?

  def initialize(file_number:, user:)
    @file_number = file_number
    @user = user
  end

  def call
    @success = valid?

    search_results if success

    FormResponse.new(
      success: success,
      errors: errors.messages[:workflow],
      extra: error_status_or_search_results
    )
  end

  private

  attr_reader :file_number, :success, :user, :status, :workflow

  def search_results
    @search_results ||= { search_results: { appeals: appeals, claim_reviews: claim_reviews } }
  end

  def appeals
    ::AppealsForFileNumber.new(file_number: file_number, user: user, veteran: veteran).call
  end

  def claim_reviews
    ClaimReview.find_all_visible_by_file_number(file_number).map(&:search_table_ui_hash)
  end

  def error_status_or_search_results
    return { status: status } unless success

    search_results
  end

  def file_number_presence
    return if file_number

    errors.add(:workflow, missing_veteran_file_number_error)
    @status = :bad_request
  end

  def missing_veteran_file_number_error
    {
      "title": "Veteran file number missing",
      "detail": "HTTP_VETERAN_ID request header must include Veteran file number"
    }
  end

  def veteran_exists
    return if veteran

    errors.add(:workflow, not_found_error)
    @status = :not_found
  end

  def not_found_error
    {
      "title": "Veteran not found",
      "detail": "Could not find a Veteran matching the file number"
    }
  end

  def veteran
    @veteran ||= Veteran.find_by(file_number: file_number)
  end

  def current_user_is_vso_employee?
    user.vso_employee?
  end
end
