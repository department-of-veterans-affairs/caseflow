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

  def not_found_error
    {
      "title": "Veteran not found",
      "detail": "Could not find a Veteran matching one of the Caseflow Veteran ids #{caseflow_veteran_ids}"
    }
  end
end
