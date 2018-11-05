class RatingIssue < ApplicationRecord
  belongs_to :source_request_issue, class_name: "RequestIssue"

  # this local attribute is used to resolve the source RequestIssue
  attr_accessor :contention_reference_id

  class << self
    def from_bgs_hash(data)
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

    def from_ui_hash(ui_hash)
      new(
        participant_id: ui_hash[:participant_id],
        reference_id: ui_hash[:reference_id],
        decision_text: ui_hash[:decision_text],
        promulgation_date: ui_hash[:promulgation_date],
        contention_reference_id: ui_hash[:contention_reference_id]
      )
    end
  end

  def save_with_source_request_issue!
    fetch_source_request_issue
    return unless source_request_issue

    # if a RatingIssue already exists, update rather than attempt to insert a duplicate
    if existing_rating_issue
      existing_rating_issue.update!(source_request_issue: source_request_issue)
      self.attributes = existing_rating_issue.attributes
    else
      save!
    end
  end

  # If you change this method, you will need to clear cache in prod for your changes to
  # take effect immediately. See DecisionReview#cached_serialized_ratings
  def ui_hash
    {
      participant_id: participant_id,
      reference_id: reference_id,
      decision_text: decision_text,
      promulgation_date: promulgation_date,
      contention_reference_id: contention_reference_id,
      title_of_active_review: title_of_active_review,
      source_higher_level_review: source_higher_level_review
    }
  end

  def title_of_active_review
    return unless reference_id
    request_issue = RequestIssue.find_active_by_reference_id(reference_id)
    request_issue.review_title if request_issue
  end

  def source_higher_level_review
    return unless reference_id
    fetch_source_request_issue unless source_request_issue
    return unless source_request_issue
    source_request_issue.review_request.is_a?(HigherLevelReview) ? source_request_issue.id : nil
  end

  private

  def existing_rating_issue
    @existing_rating_issue ||= RatingIssue.find_by(participant_id: participant_id, reference_id: reference_id)
  end

  def fetch_source_request_issue
    return if contention_reference_id.nil?
    self.source_request_issue ||= RequestIssue.unscoped.find_by(contention_reference_id: contention_reference_id)
  end
end
