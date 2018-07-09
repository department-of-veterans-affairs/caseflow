class RampElection < RampReview
  has_many :intakes, as: :detail, class_name: "RampElectionIntake"
  has_many :ramp_closed_appeals

  RESPOND_BY_TIME = 60.days.freeze

  validate :validate_receipt_date

  class BGSEndProductSyncError < RuntimeError
    def initialize(error, ramp_election)
      super(error.message + "\n\n ramp_election_id: #{ramp_election.id}").tap do |result|
        result.set_backtrace(error.backtrace)
      end
    end
  end

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

  def recreate_issues_from_contentions!
    # Load contentions outside of the Postgres transaction so we don't keep a connection
    # open needlessly for the entirety of what could be a slow VBMS request.
    end_product_establishment.contentions

    transaction do
      issues.destroy_all

      end_product_establishment.contentions.each do |contention|
        issues.create!(contention: contention)
      end
    end
  end

  def successful_intake
    @successful_intake ||= intakes.where(completion_status: "success")
      .order(:completed_at)
      .last
  end

  def rollback!
    transaction do
      update!(
        established_at: nil,
        receipt_date: nil,
        option_selected: nil,
        end_product_reference_id: nil,
        end_product_status: nil,
        end_product_status_last_synced_at: nil
      )

      ramp_closed_appeals.destroy_all
    end
  end

  def sync!
    recreate_issues_from_contentions!
    sync_ep_status!
  rescue StandardError => e
    Raven.capture_exception(BGSEndProductSyncError.new(e, self))
  end

  def self.order_by_sync_priority
    active.order("end_product_status_last_synced_at IS NOT NULL, end_product_status_last_synced_at ASC")
  end

  private

  def validate_receipt_date
    return unless receipt_date
    validate_receipt_date_not_before_ramp
    validate_receipt_date_not_in_future
  end
end
