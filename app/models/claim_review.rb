# A claim review is a short hand term to refer to either a supplemental claim or
# higher level review as defined in the Appeals Modernization Act of 2017

class ClaimReview < AmaReview
  include Asyncable

  has_many :end_product_establishments, as: :source

  self.abstract_class = true

  # establishment_submitted_at - when our db is ready to push to exernal services
  # establishment_attempted_at - when our db attempted to push to external services
  # establishment_processed_at - when our db successfully pushed to external services

  REQUIRES_PROCESSING_WINDOW_DAYS = 4
  REQUIRES_PROCESSING_RETRY_WINDOW_HOURS = 3

  class << self
    def unexpired
      where("establishment_submitted_at > ?", REQUIRES_PROCESSING_WINDOW_DAYS.days.ago)
    end

    def processable
      where.not(establishment_submitted_at: nil).where(establishment_processed_at: nil)
    end

    def never_attempted
      where(establishment_attempted_at: nil)
    end

    def previously_attempted_ready_for_retry
      where("establishment_attempted_at < ?", REQUIRES_PROCESSING_RETRY_WINDOW_HOURS.hours.ago)
    end

    def attemptable
      previously_attempted_ready_for_retry.or(never_attempted)
    end

    def order_by_oldest_submitted
      order("establishment_submitted_at ASC")
    end

    def requires_processing
      processable.attemptable.unexpired.order_by_oldest_submitted
    end

    def expired_without_processing
      where(establishment_processed_at: nil)
        .where("establishment_submitted_at <= ?", REQUIRES_PROCESSING_WINDOW_DAYS.days.ago)
        .order("establishment_submitted_at ASC")
    end
  end

  def submit_for_processing!
    update!(establishment_submitted_at: Time.zone.now, establishment_processed_at: nil)
  end

  def processed!
    update!(establishment_processed_at: Time.zone.now) unless processed?
  end

  def attempted!
    update!(establishment_attempted_at: Time.zone.now)
  end

  def processed?
    !!establishment_processed_at
  end

  def issue_code(_rated)
    fail Caseflow::Error::MustImplementInSubclass
  end

  # Save issues and assign it the appropriate end product establishment.
  # Create that end product establishment if it doesn't exist.
  def create_issues!(new_issues)
    new_issues.each do |issue|
      issue.update!(end_product_establishment: end_product_establishment_for_issue(issue))
    end
  end

  # Idempotent method to create all the artifacts for this claim.
  # If any external calls fail, it is safe to call this multiple times until
  # establishment_processed_at is successfully set.
  def process_end_product_establishments!
    attempted!

    end_product_establishments.each do |end_product_establishment|
      end_product_establishment.perform!
      end_product_establishment.create_contentions!
      end_product_establishment.create_associated_rated_issues!
      end_product_establishment.commit!
    end

    processed!
  end

  def invalid_modifiers
    end_product_establishments.map(&:modifier).reject(&:nil?)
  end

  def on_sync(end_product_establishment)
    if end_product_establishment.status_cleared?
      sync_dispositions(end_product_establishment.reference_id)
      # allow higher level reviews to do additional logic on dta errors
      yield if block_given?
    end
  end

  private

  def end_product_establishment_for_issue(issue)
    ep_code = issue_code(issue.rated?)
    end_product_establishments.find_by(code: ep_code) || new_end_product_establishment(ep_code)
  end

  def sync_dispositions(reference_id)
    fetch_dispositions_from_vbms(reference_id).each do |disposition|
      request_issue = matching_request_issue(disposition[:contention_id])
      request_issue.update!(disposition: disposition[:disposition])
      # allow higher level reviews to do additional logic on dta errors
      yield(disposition, request_issue) if block_given?
    end
  end

  def fetch_dispositions_from_vbms(reference_id)
    VBMSService.get_dispositions!(claim_id: reference_id)
  end

  def matching_request_issue(contention_id)
    RequestIssue.find_by!(contention_reference_id: contention_id)
  end
end
