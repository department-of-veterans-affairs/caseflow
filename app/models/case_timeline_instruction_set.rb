# frozen_string_literal: true

# :reek:TooManyInstanceVariables
class CaseTimelineInstructionSet
  attr_reader :change_type,
              :issue_category,
              :benefit_type,
              :original_mst,
              :original_pact,
              :edit_mst,
              :edit_pact,
              :mst_edit_reason,
              :pact_edit_reason

  # rubocop:disable Metrics/ParameterLists
  # :reek:LongParameterList and :reek:TooManyInstanceVariables
  def initialize(
    change_type:,
    issue_category:,
    benefit_type:,
    original_mst:,
    original_pact:,
    edit_mst: nil,
    edit_pact: nil,
    mst_edit_reason: nil,
    pact_edit_reason: nil
  )
    @change_type = change_type
    @issue_category = issue_category
    @benefit_type = benefit_type
    @original_mst = original_mst
    @original_pact = original_pact
    @edit_mst = edit_mst
    @edit_pact = edit_pact
    @mst_edit_reason = mst_edit_reason
    @pact_edit_reason = pact_edit_reason
  end
  # rubocop:enable Metrics/ParameterLists
end
