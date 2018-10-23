class RequestIssue < ApplicationRecord
  belongs_to :review_request, polymorphic: true
  belongs_to :end_product_establishment
  has_many :decision_issues
  has_many :remand_reasons
  has_many :rating_issues

  enum ineligible_reason: { duplicate_of_issue_in_active_review: 0, untimely: 1 }

  UNIDENTIFIED_ISSUE_MSG = "UNIDENTIFIED ISSUE - Please click \"Edit in Caseflow\" button to fix".freeze

  class << self
    def rated
      where.not(rating_issue_reference_id: nil, rating_issue_profile_date: nil)
        .or(where(is_unidentified: true))
    end

    def nonrated
      where(rating_issue_reference_id: nil, rating_issue_profile_date: nil, is_unidentified: [nil, false])
        .where.not(issue_category: nil)
    end

    def unidentified
      where(rating_issue_reference_id: nil, rating_issue_profile_date: nil, is_unidentified: true)
    end

    def no_follow_up_issues
      where.not(id: select(:parent_request_issue_id).uniq)
    end

    def from_intake_data(data)
      new(
        rating_issue_reference_id: data[:reference_id],
        rating_issue_profile_date: data[:profile_date],
        description: data[:decision_text],
        decision_date: data[:decision_date],
        issue_category: data[:issue_category],
        notes: data[:notes],
        is_unidentified: data[:is_unidentified]
      ).validate_eligibility!
    end

    def find_active_by_reference_id(reference_id)
      request_issue = unscoped.find_by(rating_issue_reference_id: reference_id, removed_at: nil, ineligible_reason: nil)
      return unless request_issue && request_issue.status_active?
      request_issue
    end
  end

  def status_active?
    return false unless end_product_establishment
    end_product_establishment.status_active?
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

  def review_title
    review_request_type.try(:constantize).try(:review_title)
  end

  def eligible?
    ineligible_reason.nil?
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

  def validate_eligibility!
    check_for_active_request_issue!
    check_for_untimely!
    self
  end

  private

  def check_for_active_request_issue!
    return unless rating_issue_reference_id
    existing_request_issue = self.class.find_active_by_reference_id(rating_issue_reference_id)
    if existing_request_issue
      self.ineligible_reason = :duplicate_of_issue_in_active_review
    end
  end

  def check_for_untimely!
    rating_issue = original_rating_issue
    if rating_issue && review_request && !review_request.timely_rating?(rating_issue[:promulgation_date])
      self.ineligible_reason = :untimely
    end
  end

  def original_rating_issue
    return unless review_request
    rating_issue = nil
    review_request.serialized_ratings.each do |rating|
      rating[:issues].each do |issue|
        rating_issue = issue if issue[:reference_id] == rating_issue_reference_id
      end
    end
    rating_issue
  end
end
