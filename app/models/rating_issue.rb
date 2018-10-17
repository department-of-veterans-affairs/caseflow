class RatingIssue < ApplicationRecord
  belongs_to :request_issue

  # this local attribute is used to resolve the related RequestIssue
  attr_accessor :contention_reference_id

  def save_with_request_issue!
    return unless related_request_issue
    self.request_issue = related_request_issue
    save!
  end

  # If you change this method, you will need
  # to clear cache in prod for your changes to
  # take effect immediately.
  # See AmaReview#cached_serialized_timely_ratings and AmaReview#cached_serialized_ratings
  def ui_hash
    {
      reference_id: reference_id,
      decision_text: decision_text,
      in_active_review: in_active_review
    }
  end

  def self.from_bgs_hash(data)
    rba_contentions = [data.dig(:rba_issue_contentions) || {}].flatten
    new(
      reference_id: data[:rba_issue_id],
      profile_date: rba_contentions.first.dig(:prfil_dt),
      contention_reference_id: rba_contentions.first.dig(:cntntn_id),
      decision_text: data[:decn_txt]
    )
  end

  def in_active_review
    return unless reference_id
    request_issue = request_issue_in_review
    request_issue.review_title if request_issue && request_issue.status_active?
  end

  private

  def request_issue_in_review
    RequestIssue.find_by(rating_issue_reference_id: reference_id, removed_at: nil)
  end

  def related_request_issue
    return if contention_reference_id.nil?
    @related_request_issue ||= RequestIssue.find_by(contention_reference_id: contention_reference_id)
  end
end
