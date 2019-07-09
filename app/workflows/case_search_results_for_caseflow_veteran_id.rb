# frozen_string_literal: true

class CaseSearchResultsForCaseflowVeteranId < ::CaseSearchResultsBase
  validate :veterans_exist

  def initialize(caseflow_veteran_ids:, user:)
    super(user: user)
    @caseflow_veteran_ids = caseflow_veteran_ids
  end

  protected

  def appeals
    AppealFinder.new(user: user).find_appeals_for_veterans(veterans_user_can_access)
  end

  def claim_reviews
    ClaimReview.find_all_visible_by_file_number(veterans_user_can_access.map(&:file_number))
  end

  def veterans
    @veterans ||= Veteran.where(id: caseflow_veteran_ids)
  end

  private

  attr_reader :caseflow_veteran_ids

  def veterans_exist
    return unless veterans_user_can_access.empty?

    errors.add(:workflow, not_found_error)
    @status = :not_found
  end

  def not_found_error
    {
      "title": "Veteran not found",
      "detail": "Could not find a Veteran matching one of the Caseflow Veteran ids #{caseflow_veteran_ids}"
    }
  end
end
