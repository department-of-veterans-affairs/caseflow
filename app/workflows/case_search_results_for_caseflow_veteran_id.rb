# frozen_string_literal: true

class CaseSearchResultsForCaseflowVeteranId < ::CaseSearchResultsBase
  validate :valid_caseflow_veteran_id

  def initialize(caseflow_veteran_id:, user:)
    super(user: user)
    @caseflow_veteran_id = caseflow_veteran_id
  end

  protected

  def appeals
    AppealFinder.new(user: user).find_appeals_for_veterans([veteran])
  end

  def claim_reviews
    ClaimReview.find_all_visible_by_file_number(file_number_or_ssn).map(&:search_table_ui_hash)
  end

  private

  attr_reader :caseflow_veteran_id

  def valid_caseflow_veteran_id
    return if file_number_or_ssn

    errors.add(:workflow, not_found_error)
    @status = :not_found
  end

  def not_found_error
    {
      "title": "Veteran not found",
      "detail": "Could not find a Veteran matching the Caseflow Veteran id #{file_number_or_ssn}"
    }
  end

  def file_number_or_ssn
    @file_number_or_ssn ||= veteran&.file_number
  end

  def veteran
    @veteran ||= Veteran.find_by(id: caseflow_veteran_id)
  end
end
