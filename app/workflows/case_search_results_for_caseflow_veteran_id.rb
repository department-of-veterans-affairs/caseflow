# frozen_string_literal: true

class CaseSearchResultsForCaseflowVeteranId
  include ActiveModel::Validations
  include ValidateVsoEmployeeCanAccessFileNumber

  validate :valid_caseflow_veteran_id

  def initialize(caseflow_veteran_id:, user:)
    @caseflow_veteran_id = caseflow_veteran_id
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

  attr_reader :success, :user, :status, :caseflow_veteran_id, :workflow

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

  def valid_caseflow_veteran_id
    return if file_number

    errors.add(:workflow, not_found_error)
    @status = :not_found
  end

  def not_found_error
    {
      "title": "Veteran not found",
      "detail": "Could not find a Veteran matching the Caseflow Veteran id #{file_number}"
    }
  end

  def file_number
    @file_number ||= veteran&.file_number
  end

  def veteran
    @veteran ||= Veteran.find_by(id: caseflow_veteran_id)
  end
end
