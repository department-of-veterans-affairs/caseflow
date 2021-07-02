# frozen_string_literal: true

# A claim review is a short hand term to refer to either a supplemental claim or
# higher level review as defined in the Appeals Modernization Act of 2017

class ClaimReview < DecisionReview
  include HasBusinessLine

  has_many :end_product_establishments, as: :source
  has_many :messages, as: :detail

  with_options if: :saving_review do
    validate :validate_receipt_date
    validate :validate_veteran
    validates :receipt_date, :benefit_type, presence: { message: "blank" }
    validates :veteran_is_not_claimant, inclusion: { in: [true, false], message: "blank" }
    validates_associated :claimants
  end

  validates :legacy_opt_in_approved, inclusion: {
    in: [true, false], message: "blank"
  }, if: [:saving_review]

  self.abstract_class = true

  class NoEndProductsRequired < StandardError; end

  class << self
    def find_by_uuid_or_reference_id!(claim_id)
      claim_review = find_by(uuid: claim_id) ||
                     EndProductEstablishment.find_by(reference_id: claim_id, source_type: to_s).try(:source)
      fail ActiveRecord::RecordNotFound unless claim_review

      claim_review
    end

    def find_all_visible_by_file_number(*file_numbers)
      HigherLevelReview.where(veteran_file_number: file_numbers).reject(&:removed?) +
        SupplementalClaim.where(veteran_file_number: file_numbers).reject(&:removed?)
    end
  end

  def serialize
    Intake::ClaimReviewSerializer.new(self).serializable_hash[:data][:attributes]
  end

  def find_or_create_stream!(benefit_type)
    attributes = stream_attributes.merge(benefit_type: benefit_type)
    self.class.find_by(attributes) || create_stream!(attributes)
  end

  def validate_prior_to_edit
    if processed?
      # force sync on initial edit call so that we have latest EP status.
      # This helps prevent us editing something that recently closed upstream.
      sync_end_product_establishments!

      verify_contentions
    end

    # this will raise any errors for missing data
    serialize
  end

  def async_job_url
    "/asyncable_jobs/#{self.class}/jobs/#{id}"
  end

  def label
    "#{self.class} #{id} (Veteran #{veteran_file_number})"
  end

  def finalized_decision_issues_before_receipt_date
    return [] unless receipt_date

    @finalized_decision_issues_before_receipt_date ||= begin
      DecisionIssue.where(participant_id: veteran.participant_id, benefit_type: benefit_type)
        .select(&:finalized?)
        .select do |issue|
          issue.approx_decision_date && issue.approx_decision_date < receipt_date
        end
    end
  end

  # Save issues and assign them to the appropriate end product establishment, creating if necessary.
  # Do creation and assignment in two phases, because EP code may depend on all issues being created.
  def create_issues!(new_issues, request_issues_update = nil)
    new_issues.each(&:create_for_claim_review!)
    request_issues.reload.each do |issue|
      issue.assign_to_end_product_establishment_for_claim_review!(request_issues_update)
    end
  end

  def add_user_to_business_line!
    return unless processed_in_caseflow?

    business_line.add_user(RequestStore.store[:current_user])
  end

  def create_business_line_tasks!
    create_decision_review_task! if processed_in_caseflow?
  end

  # Idempotent method to create all the artifacts for this claim.
  # If any external calls fail, it is safe to call this multiple times until
  # establishment_processed_at is successfully set.
  def establish!
    attempted!

    if processed_in_caseflow? && end_product_establishments.any?
      fail NoEndProductsRequired, message: "Decision reviews processed in Caseflow should not have End Products"
    end

    end_product_establishments.each(&:establish!)
    process_legacy_issues!
    clear_error!
    processed!
  end

  def processed!
    super
    AsyncableJobMessaging.new(job: self).handle_job_success
  end

  def update_error!(err)
    super
    AsyncableJobMessaging.new(job: self).handle_job_failure
  end

  # Cancel an unprocessed job, add a job note, and send a message to the job user's inbox.
  # Currently this only happens manually by an engineer, and requires a message explaining
  # why the job was cancelled and describing any additional action necessary.
  def cancel_with_note!(user: RequestStore[:current_user], note:)
    fail Caseflow::Error::ActionForbiddenError, message: "Acting user must be specified" unless user
    fail Caseflow::Error::ActionForbiddenError, message: "Processed job cannot be cancelled" if processed?

    cancel_establishment!
    AsyncableJobMessaging.new(job: self, user: user).add_job_cancellation_note(text: note)
  end

  def invalid_modifiers
    end_product_establishments.map(&:modifier).reject(&:nil?)
  end

  def end_product_base_modifier
    valid_modifiers.first
  end

  def valid_modifiers
    self.class::END_PRODUCT_MODIFIERS
  end

  def on_sync(end_product_establishment)
    if end_product_establishment.status_cleared?
      end_product_establishment.sync_decision_issues!
      # allow higher level reviews to do additional logic on dta errors
      yield if block_given?
    end
  end

  def sync_end_product_establishments!
    # re-use the same veteran object so we only cache End Products once.
    end_product_establishments.each do |epe|
      epe.veteran = veteran
      epe.sync!
    end
  end

  def active?
    processed_in_vbms? ? end_product_establishments.any? { |ep| ep.status_active?(sync: false) } : incomplete_tasks?
  end

  def active_status?
    active?
  end

  def search_table_ui_hash
    {
      caseflow_veteran_id: claim_veteran&.id,
      claimant_names: claimants.map(&:name).uniq, # We're not sure why we see duplicate claimants, but this helps
      claim_id: id,
      end_product_status: search_table_statuses,
      establishment_error: establishment_error,
      review_type: self.class.to_s.underscore,
      receipt_date: receipt_date,
      veteran_file_number: veteran_file_number,
      veteran_full_name: claim_veteran&.name&.formatted(:readable_full),
      caseflow_only_edit_issues_url: caseflow_only_edit_issues_url
    }
  end

  def claim_veteran
    Veteran.find_by(file_number: veteran_file_number)
  end

  def search_table_statuses
    if processed_in_caseflow?
      [{
        ep_code: "Processed in Caseflow",
        ep_status: ""
      }] # eventually this is a link
    else
      end_product_establishments.map(&:status)
    end
  end

  # needed for appeal status api
  def program
    case benefit_type
    when "voc_rehab"
      "vre"
    when "vha"
      "medical"
    when "nca"
      "burial"
    else
      benefit_type
    end
  end

  def aoj
    return if request_issues.empty?

    request_issues.first.api_aoj_from_benefit_type
  end

  def active_request_issues_or_decision_issues
    active_status? ? request_issues.active.all : fetch_all_decision_issues
  end

  def contention_records(epe)
    epe.request_issues.active
  end

  def all_contention_records(epe)
    epe.request_issues
  end

  def cancel_active_tasks
    ClaimReviewActiveTaskCancellation.new(self).call
  end

  def end_product_establishment_for_issue(issue, request_issues_update = nil)
    return unless issue.eligible? && processed_in_vbms?

    end_product_establishments.find_by(
      "(code = ?) AND (synced_status IS NULL OR synced_status NOT IN (?))",
      issue.end_product_code,
      EndProduct::INACTIVE_STATUSES
    ) || new_end_product_establishment(issue, request_issues_update)
  end

  def cancel_establishment!
    transaction do
      canceled!
      request_issues.each { |reqi| reqi.close!(status: :end_product_canceled) }
    end
  end

  def can_contest_rating_issues?
    processed_in_vbms? && benefit_type != "fiduciary" && !try(:decision_review_remanded?)
  end

  def cleared_rating_ep?
    processed? && cleared_end_products.any?(&:rating?)
  end

  def cleared_nonrating_ep?
    processed? && cleared_end_products.any?(&:nonrating?)
  end

  private

  def cleared_end_products
    @cleared_end_products ||= end_product_establishments.select { |ep| ep.status_cleared?(sync: true) }
  end

  def verify_contentions
    # any open request_issues that have contention_reference_id pointers that no longer resolve should be removed.
    request_issues.select(&:open?).select(&:contention_missing?).each(&:remove!)
  end

  def incomplete_tasks?
    tasks.reject(&:completed?).any?
  end

  def create_decision_review_task!
    return if tasks.any? { |task| task.is_a?(DecisionReviewTask) } # TODO: more specific check?
    return if request_issues.active.blank?

    DecisionReviewTask.create!(appeal: self, assigned_at: Time.zone.now, assigned_to: business_line)
  end

  def intake_processed_by
    intake ? intake.user : nil
  end

  def matching_request_issue(contention_id)
    RequestIssue.find_by!(contention_reference_id: contention_id)
  end

  def issue_active_status(_issue)
    active?
  end

  def validate_veteran
    return unless intake
    return if processed_in_caseflow? || intake.veteran.valid?(:bgs)

    errors.add(:veteran, "veteran_not_valid")
  end

  # Currently a new claim review stream is only created for claims processed in VBMS for EP Claim Label updates
  # This only happens after the EP is established, and represents one AMA form that may need to be split, such as if
  # The issues represent more than one benefit type.
  def stream_attributes
    slice(
      :legacy_opt_in_approved,
      :receipt_date,
      :veteran_file_number,
      :veteran_is_not_claimant,
      :establishment_submitted_at,
      :establishment_processed_at,
      :establishment_attempted_at,
      :establishment_last_submitted_at
    )
  end

  # Note: this does not do a deep copy for unrecognized claimants
  # Currently this is only in use for claims processed in VBMS which are not impacted
  def create_stream!(attributes)
    self.class.create(attributes).tap { |new_stream| new_stream.copy_claimants!(claimants) }
  end
end
