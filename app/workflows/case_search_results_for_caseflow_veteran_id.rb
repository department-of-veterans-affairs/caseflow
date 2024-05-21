# frozen_string_literal: true

class CaseSearchResultsForCaseflowVeteranId < ::CaseSearchResultsBase
  validate :veterans_exist

  def initialize(caseflow_veteran_ids:, user:)
    super(user: user)
    @caseflow_veteran_ids = caseflow_veteran_ids
  end

  protected

  def veterans
    @veterans ||= Veteran.where(id: caseflow_veteran_ids)
  end

  private

  attr_reader :caseflow_veteran_ids

  def appeal_finder_appeals
    AppealFinder.new(user: user).find_appeals_for_veterans(veterans_user_can_access)
  end

  def case_search_results
    api_case_search_results
  end

  def search_results
    api_search_result
  end

  def not_found_error
    {
      "title": "Veteran not found",
      "detail": "Could not find a Veteran matching one of the Caseflow Veteran ids #{caseflow_veteran_ids}"
    }
  end
end
