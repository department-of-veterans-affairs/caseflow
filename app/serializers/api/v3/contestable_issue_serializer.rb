# frozen_string_literal: true

class Api::V3::ContestableIssueSerializer
  include FastJsonapi::ObjectSerializer
  set_key_transform :camel_lower

  def initialize(contestable_issue, options = {})
    unless contestable_issue.respond_to? :id
      contestable_issue.define_singleton_method(:id) { nil }
    end
    super(contestable_issue, options)
  end

  to_date = proc { |object| object.try(:strftime, "%F") || object }

  attribute :rating_issue_reference_id
  attribute(:rating_issue_profile_date) { |object| to_date.call(object.rating_issue_profile_date) }
  attribute :rating_issue_diagnostic_code
  attribute :rating_issue_subject_text
  attribute :rating_issue_percent_number
  attribute :description
  attribute :is_rating
  attribute :latest_issues_in_chain do |object|
    object.latest_contestable_issues.collect do |latest|
      { id: latest.decision_issue&.id, approxDecisionDate: to_date.call(latest.approx_decision_date) }
    end
  end
  attribute(:decision_issue_id) { |object| object.decision_issue&.id }
  attribute :rating_decision_reference_id
  attribute(:approx_decision_date) { |object| to_date.call(object.approx_decision_date) }
  attribute :ramp_claim_id
  attribute :title_of_active_review
  attribute :source_review_type
  attribute :timely, &:timely?
end
