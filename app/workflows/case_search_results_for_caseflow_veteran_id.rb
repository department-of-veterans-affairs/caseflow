# frozen_string_literal: true

class CaseSearchResultsForCaseflowVeteranId < ::CaseSearchResultsBase
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

  def validation_hook
    validate_veterans_exist
  end

  def appeal_finder_appeals
    AppealFinder.new(user: user).find_appeals_for_veterans(veterans_user_can_access)
  end

  def search_results
    @search_results ||= SearchQueryService.new(
      veteran_ids: veterans_user_can_access.map(&:id)
    ).search_by_veteran_ids
  end

  def vso_user_search_results
    SearchQueryService::VsoUserSearchResults.new(user: user, search_results: search_results).call
  end

  def appeals
    if user.vso_employee?
      vso_user_search_results
    else
      search_results
    end
  end

  def not_found_error
    {
      "title": "Veteran not found",
      "detail": "Could not find a Veteran matching one of the Caseflow Veteran ids #{caseflow_veteran_ids}"
    }
  end
end
