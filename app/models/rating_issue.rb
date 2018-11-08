# ephemeral class used for caching Rating Issues for client,
# and for creating DecisionIssues when a Rating Issue has a contention_reference_id

class RatingIssue
  include ActiveModel::Model

  attr_accessor :reference_id, :decision_text, :profile_date,
                :promulgation_date, :participant_id, :contention_reference_id

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
        profile_date: ui_hash[:profile_date],
        contention_reference_id: ui_hash[:contention_reference_id]
      )
    end
  end

  def save_decision_issue
    return unless source_request_issue

    # if a DecisionIssue already exists, update rather than attempt to insert a duplicate
    if decision_issue
      decision_issue.update!(source_request_issue: source_request_issue)
    else
      DecisionIssue.create!(
        source_request_issue: source_request_issue,
        rating_issue_reference_id: reference_id,
        participant_id: participant_id,
        promulgation_date: promulgation_date,
        decision_text: decision_text,
        profile_date: profile_date
      )
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
      profile_date: profile_date,
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
    return unless source_request_issue
    source_request_issue.review_request.is_a?(HigherLevelReview) ? source_request_issue.id : nil
  end

  def decision_issue
    @decision_issue ||= DecisionIssue.find_by(participant_id: participant_id, rating_issue_reference_id: reference_id)
  end

  def source_request_issue
    return if contention_reference_id.nil?
    @source_request_issue ||= RequestIssue.unscoped.find_by(contention_reference_id: contention_reference_id)
  end
end
