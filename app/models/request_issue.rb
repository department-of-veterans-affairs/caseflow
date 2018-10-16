class RequestIssue < ApplicationRecord
  belongs_to :review_request, polymorphic: true
  belongs_to :end_product_establishment
  has_many :decision_issues
  has_many :remand_reasons
  has_many :rating_issues
  belongs_to :ineligible_request_issue, class_name: "RequestIssue"

  enum ineligible_reason: { in_active_review: 0, untimely: 1 }

  UNIDENTIFIED_ISSUE_MSG = "UNIDENTIFIED ISSUE - Please click \"Edit in Caseflow\" button to fix".freeze
  INELIGIBLE_IN_ACTIVE_REVIEW_MSG = Constants.REQUEST_ISSUES.ineligible_in_active_review_msg.freeze
  INELIGIBLE_UNTIMELY_MSG = Constants.REQUEST_ISSUES.ineligible_untimely_msg.freeze

  def self.rated
    where.not(rating_issue_reference_id: nil, rating_issue_profile_date: nil)
      .or(where(is_unidentified: true))
  end

  def self.nonrated
    where(rating_issue_reference_id: nil, rating_issue_profile_date: nil, is_unidentified: [nil, false])
      .where.not(issue_category: nil)
  end

  def self.unidentified
    where(rating_issue_reference_id: nil, rating_issue_profile_date: nil, is_unidentified: true)
  end

  def self.no_follow_up_issues
    where.not(id: select(:parent_request_issue_id).uniq)
  end

  def rated?
    rating_issue_reference_id && rating_issue_profile_date
  end

  def nonrated?
    issue_category && decision_date
  end

  def contention_text
    return "#{issue_category} - #{description}" if nonrated?
    return UNIDENTIFIED_ISSUE_MSG if is_unidentified
    description
  end

  def update_as_ineligible!(other_request_issue:, reason:)
    update!(ineligible_request_issue_id: other_request_issue.id, ineligible_reason: reason)
  end

  def review_title
    review_request_type.underscore.titleize
  end

  def ineligible_msg
    msg = "#{self.class}::INELIGIBLE_#{ineligible_reason.to_s.upcase}_MSG".constantize.dup
    msg.sub!("{review_title}", ineligible_request_issue.review_title) if ineligible_request_issue
    msg
  end

  def self.from_intake_data(data)
    new(
      rating_issue_reference_id: data[:reference_id],
      rating_issue_profile_date: data[:profile_date],
      description: data[:decision_text],
      decision_date: data[:decision_date],
      issue_category: data[:issue_category],
      notes: data[:notes],
      is_unidentified: data[:is_unidentified]
    )
  end

  def ui_hash
    {
      reference_id: rating_issue_reference_id,
      profile_date: rating_issue_profile_date,
      description: description,
      decision_date: decision_date,
      category: issue_category,
      notes: notes,
      is_unidentified: is_unidentified
    }
  end
end
