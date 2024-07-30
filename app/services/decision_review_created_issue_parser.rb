# frozen_string_literal: true

class DecisionReviewCreatedIssueParser
  include ParserHelper
  attr_reader :issue

  def initialize(issue)
    @issue = issue
  end

  def ri_benefit_type
    @issue.dig(:benefit_type)
  end

  def ri_contested_issue_description
    @issue.dig(:contested_issue_description)
  end

  def ri_contention_reference_id
    @issue.dig(:contention_reference_id)
  end

  def ri_contested_rating_decision_reference_id
    @issue.dig(:contested_rating_decision_reference_id)
  end

  def ri_contested_rating_issue_profile_date
    @issue.dig(:contested_rating_issue_profile_date)
  end

  def ri_contested_rating_issue_reference_id
    @issue.dig(:contested_rating_issue_reference_id)
  end

  def ri_contested_decision_issue_id
    @issue.dig(:contested_decision_issue_id)
  end

  def ri_decision_date
    decision_date_int = @issue.dig(:decision_date)
    logical_date_converter(decision_date_int)
  end

  def ri_ineligible_due_to_id
    @issue.dig(:ineligible_due_to_id)
  end

  def ri_ineligible_reason
    @issue.dig(:ineligible_reason)
  end

  def ri_is_unidentified
    @issue.dig(:is_unidentified)
  end

  def ri_unidentified_issue_text
    @issue.dig(:unidentified_issue_text)
  end

  def ri_nonrating_issue_category
    @issue.dig(:nonrating_issue_category)
  end

  def ri_nonrating_issue_description
    @issue.dig(:nonrating_issue_description)
  end

  def ri_untimely_exemption
    @issue.dig(:untimely_exemption)
  end

  def ri_untimely_exemption_notes
    @issue.dig(:untimely_exemption_notes)
  end

  def ri_vacols_id
    @issue.dig(:vacols_id)
  end

  def ri_vacols_sequence_id
    @issue.dig(:vacols_sequence_id)
  end

  def ri_closed_at
    @issue.dig(:closed_at)
  end

  def ri_closed_status
    @issue.dig(:closed_status)
  end

  def ri_contested_rating_issue_diagnostic_code
    @issue.dig(:contested_rating_issue_diagnostic_code)
  end

  def ri_ramp_claim_id
    @issue.dig(:ramp_claim_id)
  end

  def ri_rating_issue_associated_at
    ri_rating_issue_associated_at_in_ms = @issue.dig(:rating_issue_associated_at)
    convert_milliseconds_to_datetime(ri_rating_issue_associated_at_in_ms)
  end

  def ri_nonrating_issue_bgs_id
    @issue.dig(:nonrating_issue_bgs_id)
  end

  def ri_nonrating_issue_bgs_source
    @issue.dig(:nonrating_issue_bgs_source)
  end
end
