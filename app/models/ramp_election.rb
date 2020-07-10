# frozen_string_literal: true

class RampElection < RampReview
  has_many :intakes, as: :detail, class_name: "RampElectionIntake"
  has_many :ramp_closed_appeals

  RESPOND_BY_TIME = 60.days.freeze

  validate :validate_receipt_date

  # RAMP letters request that Veterans respond within 60 days; elections will
  # be accepted after this point, however, so this "due date" is soft.
  def due_date
    notice_date + RESPOND_BY_TIME if notice_date
  end

  def response_time
    notice_date && receipt_date && (receipt_date.in_time_zone - notice_date.in_time_zone)
  end

  def control_time
    receipt_date && established_at && (established_at.beginning_of_day - receipt_date.in_time_zone)
  end

  def recreate_issues_from_contentions!(epe = nil)
    # If there is any ramp issues attached to saved ramp refilings connected to this election,
    # then the issues are locked and cannot be recreated
    return false if any_matching_refiling_ramp_issues?

    # Load contentions outside of the Postgres transaction so we don't keep a connection
    # open needlessly for the entirety of what could be a slow VBMS request.
    contentions = epe ? epe.contentions : end_product_establishment.contentions || matching_end_product&.contentions
    transaction do
      issues.destroy_all

      contentions&.each do |contention|
        issues.create!(contention: contention)
      end
    end
  end

  def successful_intake
    @successful_intake ||= intakes.where(completion_status: "success").order(:completed_at).last
  end

  def rollback!
    transaction do
      update!(
        established_at: nil,
        receipt_date: nil,
        option_selected: nil
      )

      # End product should already be cancelled, so we don't need to pay attention to the establishment that we already
      # had created. We will create a new one if the ramp election is recreated.
      end_product_establishment.destroy!
      remove_issues!
      ramp_closed_appeals.destroy_all
    end
  end

  def on_sync(end_product_establishment)
    recreate_issues_from_contentions!(end_product_establishment)

    if FeatureToggle.enabled?(:automatic_ramp_rollback) && end_product_establishment.status_cancelled?
      rollback_ramp_review
    end
  end

  private

  def any_matching_refiling_ramp_issues?
    RampIssue.where(source_issue_id: issues.map(&:id)).any?
  end

  def rollback_ramp_review
    RampElectionRollback.create!(
      ramp_election: self,
      user: User.system_user,
      reason: "Automatic roll back due to EP #{end_product_establishment.modifier} cancelation"
    )
  end

  def validate_receipt_date
    return unless receipt_date

    validate_receipt_date_not_before_ramp
    validate_receipt_date_not_in_future
  end
end
