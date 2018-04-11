class RampElection < RampReview
  has_many :intakes, as: :detail, class_name: "RampElectionIntake"
  has_many :ramp_refilings
  has_many :ramp_closed_appeals

  RESPOND_BY_TIME = 60.days.freeze

  validate :validate_receipt_date

  def self.active
    # We only know the set of inactive EP statuses
    # We also only know the EP status after fetching it from BGS
    # Therefore, our definition of active is when the EP is either
    #   not known or not known to be inactive
    established.where("end_product_status NOT IN (?) OR end_product_status IS NULL", EndProduct::INACTIVE_STATUSES)
  end

  def active?
    sync_ep_status! && cached_status_active?
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

  def established_end_product
    @established_end_product ||= fetch_established_end_product
  end

  def recreate_issues_from_contentions!
    # If there is a saved refiling for this election, then the issues
    # are locked and cannot be recreated
    return false if ramp_refilings.count > 0

    # Load contentions outside of the Postgres transaction so we don't keep a connection
    # open needlessly for the entirety of what could be a slow VBMS request.
    end_product.contentions

    transaction do
      issues.destroy_all

      end_product.contentions.each do |contention|
        issues.create!(contention: contention)
      end
    end
  end

  def sync_ep_status!
    # There is no need to sync end_product_status if the status
    # is already inactive since an EP can never leave that state
    return true unless cached_status_active?

    update!(
      end_product_status: established_end_product.status_type_code,
      end_product_status_last_synced_at: Time.zone.now
    )
  end

  def successful_intake
    @successful_intake ||= intakes.where(completion_status: "success")
      .order(:completed_at)
      .last
  end

  private

  def cached_status_active?
    !EndProduct::INACTIVE_STATUSES.include?(end_product_status)
  end

  def fetch_established_end_product
    return nil unless end_product_reference_id

    result = veteran.end_products.find do |end_product|
      end_product.claim_id == end_product_reference_id
    end

    fail EstablishedEndProductNotFound unless result
    result
  end

  def validate_receipt_date
    return unless receipt_date
    validate_receipt_date_not_before_ramp
    validate_receipt_date_not_in_future
  end
end
