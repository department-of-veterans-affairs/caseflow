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
  # See AmaReview#cached_serialized_timely_ratings.
  def ui_hash
    {
      reference_id: reference_id,
      decision_text: decision_text
    }
  end

  def self.from_bgs_hash(data)
    new(
      reference_id: data[:rba_issue_id],
      profile_date: data.dig(:rba_issue_contentions, :prfil_dt),
      contention_reference_id: data.dig(:rba_issue_contentions, :cntntn_id),
      decision_text: data[:decn_txt]
    )
  end

  private

  def related_request_issue
    return if contention_reference_id.nil?
    @related_request_issue ||= RequestIssue.find_by(contention_reference_id: contention_reference_id)
  end
end
