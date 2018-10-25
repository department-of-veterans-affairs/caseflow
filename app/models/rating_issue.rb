class RatingIssue < ApplicationRecord
  belongs_to :request_issue

  # this local attribute is used to resolve the source RequestIssue
  attr_accessor :contention_reference_id

  def save_with_request_issue!
    return unless source_request_issue
    self.request_issue = source_request_issue
    # if it already exists, update rather than attempt to insert a duplicate
    if existing_rating_issue
      existing_rating_issue.update!(request_issue: request_issue)
      self.attributes = existing_rating_issue.attributes
    else
      save!
    end
  end

  # If you change this method, you will need
  # to clear cache in prod for your changes to
  # take effect immediately.
  # See AmaReview#cached_serialized_ratings
  def ui_hash
    {
      reference_id: reference_id,
      decision_text: decision_text,
      promulgation_date: promulgation_date.to_date,
      in_active_review: in_active_review,
      prior_higher_level_review: prior_higher_level_review
    }
  end

  def self.from_bgs_hash(data)
    rba_contentions = [data.dig(:rba_issue_contentions) || {}].flatten
    new(
      reference_id: data[:rba_issue_id],
      profile_date: rba_contentions.first.dig(:prfil_dt) || data[:profile_date],
      contention_reference_id: rba_contentions.first.dig(:cntntn_id),
      decision_text: data[:decn_txt],
      promulgation_date: data[:promulgation_date],
      participant_id: data[:participant_id]
    )
  end

  def in_active_review
    return unless reference_id
    request_issue = RequestIssue.find_active_by_reference_id(reference_id)
    request_issue.review_title if request_issue
  end

  def prior_higher_level_review
    return unless reference_id
    return unless source_request_issue
    source_request_issue.review_request.is_a?(HigherLevelReview) ? source_request_issue.id : nil
  end

  def source_request_issue
    request_issue || find_source_request_issue
  end

  private

  def existing_rating_issue
    @existing_rating_issue ||= RatingIssue.find_by(participant_id: participant_id, reference_id: reference_id)
  end

  def find_source_request_issue
    return if contention_reference_id.nil?
    @source_request_issue ||= RequestIssue.find_by(contention_reference_id: contention_reference_id)
  end
end
