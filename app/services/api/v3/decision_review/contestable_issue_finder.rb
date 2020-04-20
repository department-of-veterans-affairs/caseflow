# frozen_string_literal: true

# given:
#   decision_review_class  (HigherLevelReview, for instance)
#   veteran
#   receipt_date
#   benefit_type
#
# answers whether or not the provided ids:
#   rating_issue_id
#   decision_issue_id
#   rating_decision_issue_id
#
# reference a contestable issue (`valid?` method)
# and returns that contestable issue (`contestable_issue` method)

class Api::V3::DecisionReview::ContestableIssueFinder
  # rubocop:disable Metrics/ParameterLists
  def initialize(
    decision_review_class:,
    veteran:,
    receipt_date:,
    benefit_type:,
    rating_issue_id: nil,
    decision_issue_id: nil,
    rating_decision_issue_id: nil
  )
    @decision_review_class = decision_review_class
    @veteran = veteran
    @receipt_date = receipt_date
    @benefit_type = benefit_type
    @rating_issue_id = rating_issue_id.to_s.strip
    @decision_issue_id = decision_issue_id.to_s.strip
    @rating_decision_issue_id = rating_decision_issue_id.to_s.strip
  end
  # rubocop:enable Metrics/ParameterLists

  def found?
    !!contestable_issue
  end

  def contestable_issue
    @contestable_issue ||= contestable_issues_for_veteran_and_form_type.find do |ci|
      matches_rating_issue_id?(ci) &&
        matches_decision_issue_id?(ci) &&
        matches_rating_decision_issue_id?(ci)
    end
  end

  private

  attr_reader(
    :decision_review_class,
    :veteran,
    :receipt_date,
    :benefit_type,
    :rating_issue_id,
    :decision_issue_id,
    :rating_decision_issue_id
  )

  def matches_rating_issue_id?(contestable_issue)
    contestable_issue&.rating_issue_reference_id.to_s.strip == rating_issue_id
  end

  def matches_decision_issue_id?(contestable_issue)
    contestable_issue&.decision_issue&.id.to_s.strip == decision_issue_id
  end

  def matches_rating_decision_issue_id?(contestable_issue)
    contestable_issue&.rating_decision_reference_id.to_s.strip == rating_decision_issue_id
  end

  def contestable_issues_for_veteran_and_form_type
    @contestable_issues_for_veteran_and_form_type ||= contestable_issue_generator.contestable_issues
  end

  def contestable_issue_generator
    @contestable_issue_generator ||= ContestableIssueGenerator.new(
      decision_review_class.new(
        veteran_file_number: veteran.file_number,
        receipt_date: receipt_date,
        benefit_type: benefit_type
      )
    )
  end
end
