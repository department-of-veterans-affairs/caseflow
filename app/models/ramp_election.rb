class RampElection < RampReview
  has_many :intakes, as: :detail, class_name: "RampElectionIntake"
  has_many :ramp_refilings

  RESPOND_BY_TIME = 60.days.freeze

  validate :validate_receipt_date

  def successfully_received?
    intakes.where(completion_status: "success").any?
  end

  # RAMP letters request that Veterans respond within 60 days; elections will
  # be accepted after this point, however, so this "due date" is soft.
  def due_date
    notice_date + RESPOND_BY_TIME if notice_date
  end

  def response_time
    notice_date && receipt_date &&
      (receipt_date.to_time_in_current_zone - notice_date.to_time_in_current_zone)
  end

  def self.completed
    where.not(end_product_reference_id: nil)
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

  private

  def fetch_established_end_product
    return nil unless end_product_reference_id

    result = Veteran.new(file_number: veteran_file_number).end_products.find do |end_product|
      end_product.claim_id == end_product_reference_id
    end

    fail EstablishedEndProductNotFound unless result
    result
  end

  def validate_receipt_date
    return unless notice_date && receipt_date

    if notice_date > receipt_date
      errors.add(:receipt_date, "before_notice_date")
    else
      validate_receipt_date_not_in_future
    end
  end
end
