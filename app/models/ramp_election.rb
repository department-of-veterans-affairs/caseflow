class RampElection < RampReview
  has_many :intakes, as: :detail, class_name: "RampElectionIntake"
  has_many :ramp_refilings
  has_many :ramp_closed_appeals

  RESPOND_BY_TIME = 60.days.freeze

  validate :validate_receipt_date

  # TODO move to EstablishesEndProduct
  def self.active
    # We only know the set of inactive EP statuses
    # We also only know the EP status after fetching it from BGS
    # Therefore, our definition of active is when the EP is either
    #   not known or not known to be inactive
    established.where("end_product_status NOT IN (?) OR end_product_status IS NULL", EndProduct::INACTIVE_STATUSES)
  end

  def self.sync_all!
    RampElection.active.each do |ramp_election|
      begin
        ramp_election.recreate_issues_from_contentions!
        ramp_election.sync_ep_status!
      rescue ActiveRecord::RecordInvalid => e
        Rails.logger.error "RampElection.sync_all! failed: #{e.message}"
        Raven.capture_exception(e)
      end
    end
  end

  # TODO move to EstablishesEndProduct, rename to end_product_active ?
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

  # TODO move to EstablishesEndProduct
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

  # TODO move to EstablishesEndProduct
  def end_product_canceled?
    sync_ep_status! && end_product_status == "CAN"
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

  private
  
  # TODO move to EstablishesEndProduct
  def cached_status_active?
    !EndProduct::INACTIVE_STATUSES.include?(end_product_status)
  end

  def validate_receipt_date
    return unless receipt_date
    validate_receipt_date_not_before_ramp
    validate_receipt_date_not_in_future
  end
end
