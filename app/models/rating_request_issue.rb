# frozen_string_literal: true

class RatingRequestIssue < RequestIssue
  # :nocov:
  def rating?
    true
  end
  # :nocov:
end

# (This section is updated by the annotate gem)
# == Schema Information
#
# Table name: request_issues
#
#  id                                     :bigint           not null, primary key
#  benefit_type                           :string           not null
#  closed_at                              :datetime         indexed
#  closed_status                          :string
#  contention_removed_at                  :datetime
#  contention_updated_at                  :datetime
#  contested_issue_description            :string
#  contested_rating_issue_diagnostic_code :string
#  contested_rating_issue_profile_date    :string
#  correction_type                        :string
#  covid_timeliness_exempt                :boolean
#  decision_date                          :date
#  decision_review_type                   :string           indexed => [decision_review_id]
#  decision_sync_attempted_at             :datetime
#  decision_sync_canceled_at              :datetime
#  decision_sync_error                    :string
#  decision_sync_last_submitted_at        :datetime
#  decision_sync_processed_at             :datetime
#  decision_sync_submitted_at             :datetime
#  edited_description                     :string
#  ineligible_reason                      :string           indexed
#  is_unidentified                        :boolean
#  nonrating_issue_category               :string
#  nonrating_issue_description            :string
#  notes                                  :text
#  rating_issue_associated_at             :datetime
#  type                                   :string           default("RequestIssue")
#  unidentified_issue_text                :string
#  untimely_exemption                     :boolean
#  untimely_exemption_notes               :text
#  verified_unidentified_issue            :boolean
#  created_at                             :datetime
#  updated_at                             :datetime         indexed
#  contention_reference_id                :integer          indexed
#  contested_decision_issue_id            :integer          indexed
#  contested_rating_decision_reference_id :string           indexed
#  contested_rating_issue_reference_id    :string           indexed
#  corrected_by_request_issue_id          :integer
#  decision_review_id                     :bigint           indexed => [decision_review_type]
#  end_product_establishment_id           :integer          indexed
#  ineligible_due_to_id                   :bigint           indexed
#  ramp_claim_id                          :string
#  vacols_id                              :string
#  vacols_sequence_id                     :integer
#  veteran_participant_id                 :string           indexed
#
# Foreign Keys
#
#  fk_rails_448b2a12cd  (end_product_establishment_id => end_product_establishments.id)
#  fk_rails_a913152262  (corrected_by_request_issue_id => request_issues.id)
#  fk_rails_c76e92bd77  (contested_decision_issue_id => decision_issues.id)
#  fk_rails_fcac7534d1  (ineligible_due_to_id => request_issues.id)
#
