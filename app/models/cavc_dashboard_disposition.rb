# frozen_string_literal: true

class CavcDashboardDisposition < CaseflowRecord
  include CreatedAndUpdatedByUserConcern

  belongs_to :cavc_dashboard
  belongs_to :cavc_dashboard_issue
  belongs_to :request_issue

  has_many :cavc_dispositions_to_reasons, dependent: :destroy

  validates :cavc_dashboard, presence: true
  # disposition can be nil on create, so only validate on update
  validates :disposition, presence: true, on: :update
  validate :single_linked_issue

  # invert the hash so the database entries have underscores and the return value is the formatted string
  enum disposition: Constants::CAVC_DASHBOARD_DISPOSITIONS.invert

  def single_linked_issue
    if request_issue_id.present? && cavc_dashboard_issue_id.present?
      errors.add(:linked_issues, "cannot have multiple linked issues")
    end

    true
  end
end
