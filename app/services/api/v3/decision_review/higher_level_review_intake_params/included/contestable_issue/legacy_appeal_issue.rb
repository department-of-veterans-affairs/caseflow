# frozen_string_literal: true

class Api::V3::DecisionReview::HigherLevelReviewIntakeParams::Included::ContestableIssue::LegacyAppealIssue < Api::V3::DecisionReview::Params
  def initialize(params, index)
    @hash = params
    @index = index
    @errors = Array.wrap(
      type_error_for_key(["legacyAppealId", String], ["legacyAppealIssueId", String])
    )
  end

  def hash_path
    "#{super[0...-1]}[@index]"
  end
end

=begin
  def invalid_legacy_fields_or_no_opt_in
    if legacy_fields_blank? || legacy_fields_present_and_opted_in?
      nil
    elsif @attributes[:legacyAppealIssueId].blank?
      :request_issue_legacyAppealIssueId_is_blank_when_legacyAppealId_is_present # error_code
    elsif @attributes[:legacyAppealId].blank?
      :request_issue_legacyAppealId_is_blank_when_legacyAppealIssueId_is_present # error_code
    else
      :request_issue_legacy_not_opted_in # error_code
    end
  end
=end
