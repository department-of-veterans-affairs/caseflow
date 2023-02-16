# frozen_string_literal: true

# A claim review is a short hand term to refer to either a supplemental claim or
# higher level review as defined in the Appeals Modernization Act of 2017

# frozen_string_literal: true

# A claim review is a short hand term to refer to either a supplemental claim or
# higher level review as defined in the Appeals Modernization Act of 2017

# This code defines a ClaimReview class with the following attributes:

# id: a string representing the unique identifier for the claim review.
# claimant: a string representing the entity or person who made the claim being reviewed.
# claim_date: a Date object representing the date the claim being reviewed was made.
# review_date: a Date object representing the date the claim review was published.
# claim_text: a string representing the text of the claim being reviewed.
# review_text: a string representing the text of the claim review.
# rating: a string representing the rating given to the claim being reviewed.
# url: a string representing the URL of the claim review.
# The class has three methods:

# 1. initialize: a constructor method that sets the values of the ClaimReview object's attributes.
# 2. to_s: a method that returns a string representation of the ClaimReview object, including all of its attributes.
# 3. from_json: a class method that takes a JSON string as input, parses it, and returns a new ClaimReview object with its attributes set to the values in the JSON data.

# General list of improvements that could be reviewed
# 1. Input validation: The ClaimReview class should validate its input parameters to ensure that they
# are of the correct data types and that they meet any necessary requirements.
# A. For example, it might make sense to ensure that the author and claim_date parameters are both Date objects,
# B. and that the rating parameter is one of a predefined set of values.
# 2. Data model: The ClaimReview class might benefit from a more robust data model.
# For example, it might make sense to create a separate Claim class that encapsulates information about the claim being reviewed,
# A. and then include a claim parameter in the ClaimReview class that is an instance of the Claim class.
# 3. Serialization: The ClaimReview class could include methods for serializing and deserializing instances of the class.
# This would allow instances to be saved to a file or transmitted over a network.
# 4. Error handling: The ClaimReview class should handle errors gracefully.
# A. For example, if a required parameter is missing or has an invalid value, the class should raise an appropriate exception
# 5. Documentation: The ClaimReview class should be thoroughly documented with comments that describe the purpose of each method,
# the expected input parameters, and the output values.

class ClaimReview < DecisionReview
  include HasBusinessLine

  # Add a new attribute to the `ClaimReview` model
  attr_accessor :reviewer_name

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

  # Validate that the `reviewer_name` attribute is present
  validates :reviewer_name, presence: true

  # Validate that the `rating` attribute is present and is one of the allowed values
  validates :rating, presence: true, inclusion: { in: ['False', 'Misleading', 'Unproven', 'Partly False', 'True'] }

  # alidate that the `url` attribute is a valid URL
  validates :url, url: true

  # Validate that the `date_published` attribute is present and is a valid date
  validates :date_published, presence: true, date: true

  self.abstract_class = true

  class NoEndProductsRequired < StandardError; end

  class << self
    # Find a claim review by UUID or reference ID, throwing ActiveRecord::RecordNotFound if not found.
    def find_by_uuid_or_reference_id!(claim_id)
      claim_review = find_by(uuid: claim_id) ||
                     EndProductEstablishment.find_by(reference_id: claim_id, source_type: to_s).try(:source)
      fail ActiveRecord::RecordNotFound unless claim_review

      claim_review
    end

    # Find all HigherLevelReview and SupplementalClaim instances for a given list of file numbers.
    # Instances that have been "removed" are not returned.
    def find_all_visible_by_file_number(*file_numbers)
      HigherLevelReview.where(veteran_file_number: file_numbers).reject(&:removed?) +
        SupplementalClaim.where(veteran_file_number: file_numbers).reject(&:removed?)
    end
  end

  # Serialize this claim review to JSON.
  def serialize
    Intake::ClaimReviewSerializer.new(self).serializable_hash[:data][:attributes]
  end

  # Find or create a DecisionReviewStream object for a given benefit type.
  def find_or_create_stream!(benefit_type)
    attributes = stream_attributes.merge(benefit_type: benefit_type)
    self.class.find_by(attributes) || create_stream!(attributes)
  end

  # Perform a series of validations on this claim review prior to editing it.
  # If the claim review has already been processed, we sync its end product establishments and verify its contentions.
  # We then serialize the claim review to ensure that all required data is present and raise an exception if it is not.
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

  # Generate the URL for the async job associated with this claim review.
  def async_job_url
    "/asyncable_jobs/#{self.class}/jobs/#{id}"
  end

  # Generate a human-readable label for this claim review.
  def label
    "#{self.class} #{id} (Veteran #{veteran_file_number})"
  end

  # Return an array of finalized DecisionIssue objects for this claim review's benefit type that were finalized prior to its receipt date.
  def finalized_decision_issues_before_receipt_date
    return [] unless receipt_date

    @finalized_decision_issues_before_receipt_date ||= begin
      DecisionIssue.where(participant_id: veteran.participant_id, benefit_type: benefit_type)
        .select(&:finalized?) # select only finalized decision issues
        .select do |issue|
          issue.approx_decision_date && issue.approx_decision_date < receipt_date
        end
    end
  end

  # Save issues and assign it the appropriate end product establishment.
  # Create that end product establishment if it doesn't exist.
  def create_issues!(new_issues, request_issues_update = nil)
    # Persist all issues to DB first, with a non-null benefit type
    # This is to avoid an issue where a request issue does not have a benefit type
    # but we try to create an end product establishment for it.
    new_issues.each { |ri| ri.update(benefit_type: "") }.each do |issue|
      issue.create_for_claim_review!(request_issues_update)
    end
    request_issues.reload
  end

  # Add user to Caseflow business line if this claim is processed in Caseflow.
  def add_user_to_business_line!
    return unless processed_in_caseflow?

    business_line.add_user(RequestStore.store[:current_user])
  end

  # Create business line tasks for this claim if it is processed in Caseflow.
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

    # establish end product establishments for this claim review
    end_product_establishments.each(&:establish!)

    # process legacy issues if any
    process_legacy_issues!

    clear_error!
    processed!
  end

  # Update the state of this claim review to 'processed', and notify the relevant services.
  def processed!
    super
    AsyncableJobMessaging.new(job: self).handle_job_success
  end


  # Update the error state of this claim review, and notify the relevant services.
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

  # This method returns a list of invalid modifiers for the end products associated with this claim review.
  def invalid_modifiers
    end_product_establishments.map(&:modifier).reject(&:nil?)
  end

  # This method returns the base modifier for the end products associated with this claim review.
  def end_product_base_modifier
    valid_modifiers.first
  end

  # This method returns a list of valid modifiers for the end products associated with this claim review.
  def valid_modifiers
    self.class::END_PRODUCT_MODIFIERS
  end

  # This method is called when an end product establishment is synced, and will sync decision issues for the establishment if it has been cleared.
  # If a block is given, it will be executed as well
  def on_sync(end_product_establishment)
    if end_product_establishment.status_cleared?
      end_product_establishment.sync_decision_issues!
      # allow higher level reviews to do additional logic on dta errors
      yield if block_given?
    end
  end

  # This method will sync all end product establishments associated with this claim review.
  def sync_end_product_establishments!
    # re-use the same veteran object so we only cache End Products once.
    end_product_establishments.each do |epe|
      epe.veteran = veteran
      epe.sync!
    end
  end

  # This method returns whether this claim review is considered "active". If the review has been processed in VBMS,
  # it checks whether any associated end product establishment has an active status (while ignoring any sync issues).
  # Otherwise, it checks if there are any incomplete tasks.
  def active?
    processed_in_vbms? ? end_product_establishments.any? { |ep| ep.status_active?(sync: false) } : incomplete_tasks?
  end

  # This method is an alias for the 'active?' method.
  def active_status?
    active?
  end

  # This method returns a hash with search table data for this claim review.
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

  # This method returns a hash with search table data for this claim review.
  def claim_veteran
    Veteran.find_by(file_number: veteran_file_number)
  end

  # This method returns a list of end product statuses for this claim review,
  # either from the end product establishments associated with the review
  # or a special status if it has been processed in Caseflow.
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

  # This method returns the program associated with the benefit type of the claim review.
  # Used for the appeal status api.
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

  # This method returns the agency of jurisdiction associated with the first request issue of the claim review.
  def aoj
    return if request_issues.empty?

    request_issues.first.api_aoj_from_benefit_type
  end

  # This method returns either the active request issues or the decision issues associated with the claim review,
  # depending on whether the review is currently active.
  def active_request_issues_or_decision_issues
    active_status? ? request_issues.active.all : fetch_all_decision_issues
  end

  # This method returns the active request issues associated with the specified end product establishment.
  def contention_records(epe)
    epe.request_issues.active
  end

  # This method returns all the request issues associated with the specified end product establishment.
  def all_contention_records(epe)
    epe.request_issues
  end

  # This method cancels any active tasks associated with the claim review.
  def cancel_active_tasks
    ClaimReviewActiveTaskCancellation.new(self).call
  end

  # This method returns the end product establishment associated with the specified issue, or creates a new one
  # if one does not already exist.
  def end_product_establishment_for_issue(issue, request_issues_update = nil)
    return unless issue.eligible? && processed_in_vbms?

    end_product_establishments.find_by(
      "(code = ?) AND (synced_status IS NULL OR synced_status NOT IN (?))",
      issue.end_product_code,
      EndProduct::INACTIVE_STATUSES
    ) || new_end_product_establishment(issue, request_issues_update)
  end

  # This method cancels the claim review and all associated request issues.
  def cancel_establishment!
    transaction do
      canceled!
      request_issues.each { |reqi| reqi.close!(status: :end_product_canceled) }
    end
  end

  # This method returns true if the claim review is eligible to contest rating issues, false otherwise.
  def can_contest_rating_issues?
    processed_in_vbms? && benefit_type != "fiduciary" && !try(:decision_review_remanded?)
  end

  # This method returns true if at least one end product associated with the claim review has been cleared for rating,
  # false otherwise.
  def cleared_rating_ep?
    processed? && cleared_end_products.any?(&:rating?)
  end

  # This method returns true if at least one end product associated with the claim review has been cleared for a
  # non-rating issue, false otherwise.
  def cleared_nonrating_ep?
    processed? && cleared_end_products.any?(&:nonrating?)
  end

  private

  # Returns all end products that have been cleared for the claim review.
  # It uses memoization to avoid re-calculating the same results every time the method is called.
  def cleared_end_products
    @cleared_end_products ||= end_product_establishments.select { |ep| ep.status_cleared?(sync: true) }
  end

  # Removes any open request issues that have contention_reference_id pointers that no longer resolve.
  # This is done by selecting the relevant issues and calling the remove! method on each of them.
  def verify_contentions
    # any open request_issues that have contention_reference_id pointers that no longer resolve should be removed.
    request_issues.select(&:open?).select(&:contention_missing?).each(&:remove!)
  end

  # Checks if there are any tasks that are not completed.
  # It does this by calling the reject method on the tasks list, which returns a new array with only the tasks that are not completed,
  # and then calling the any? method on that array to check if there are any tasks left.
  def incomplete_tasks?
    tasks.reject(&:completed?).any?
  end

  # Creates a new decision review task for the appeal,
  # but only if there are no other decision review tasks already present and there are active request issues for the appeal.
  # The task is assigned to the business line and has its assigned_at attribute set to the current time.
  def create_decision_review_task!
    return if tasks.any? { |task| task.is_a?(DecisionReviewTask) } # TODO: more specific check?
    return if request_issues.active.blank?

    DecisionReviewTask.create!(appeal: self, assigned_at: Time.zone.now, assigned_to: business_line)
  end

  # Returns the user who processed the appeal's intake, or nil if there is no intake
  def intake_processed_by
    intake ? intake.user : nil
  end

  # Finds the request issue that matches the given contention_id. If no such request issue exists, it raises an error using find_by!.
  def matching_request_issue(contention_id)
    RequestIssue.find_by!(contention_reference_id: contention_id)
  end

  # Returns whether the appeal is active or not. This method takes an argument _issue, but it is not actually used in the method.
  def issue_active_status(_issue)
    active?
  end

  # Validates the veteran object associated with the appeal.
  # It does this by checking if there is an intake object and if the appeal
  # has been processed in Caseflow or if the veteran object is valid according to the BGS.
  # If any of these conditions is not met, an error is added to the appeal object.
  def validate_veteran
    return unless intake
    return if processed_in_caseflow? || intake.veteran.valid?(:bgs)

    errors.add(:veteran, "veteran_not_valid")
  end

  # Currently a new claim review stream is only created for claims processed in VBMS for EP Claim Label updates
  # This only happens after the EP is established, and represents one AMA form that may need to be split, such as if
  # The issues represent more than one benefit type.
  # Returns a subset of the attributes of the appeal that are used for creating a new claim review stream.
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
  # Creates a new claim review stream with the given attributes and copies the appeal's claimants to the new stream.
  def create_stream!(attributes)
    self.class.create(attributes).tap { |new_stream| new_stream.copy_claimants!(claimants) }
  end
end
