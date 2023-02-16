# frozen_string_literal: true

# This is a Ruby on Rails model class called DecisionReview. It is an abstract class that provides functionality common to all types of Decision Reviews.
# It includes CachedAttributes and Asyncable modules. It defines various has_many associations with request_issues, claimants,
# request_decision_issues, decision_issues, tasks, and request_issues_updates.
# Defines an attr_accessor for saving_review.
# Defines associations for various other models using has_many and has_one.
# It also includes an amoeba block for splitting appeal request issues.
# Calls the cache_attribute method to cache a serialized version of an attribute called cached_serialized_ratings.
# It caches this attribute using ratings_cache_key as the cache key and expires the cache in one day.
# The cache_atrribute method serializes an array of objects using the serialize method of each object.
# The class has several methods such as by_uuid, serialized_ratings, veteran_full_name, number_of_issues, and more.
# Defines a bunch of methods used in retrieving information for a DecisionReview instance.
# These include contestable_issues, by_uuid, asyncable_user, ama_activation_date, serialized_ratings,
# veteran_full_name, number_of_issues, external_id, withdrawal_date,
# serialize, caseflow_only_edit_issues_url, async_job_url, timely_issue?,
# start_review!, create_claimant!, remove_claimants!, copy_claimants!,
# claimant, claimant_participant_id, and others.
# Defines several class methods that specify various columns to be used in the Asyncable module,
# as well as other class-level methods like review_title, concrete_descendants, and by_uuid
# This class is designed to be subclassed for specific types of decision reviews,
# which can then use the defined methods and attributes to perform their functions.

# 1. Caching database queries: Some of the methods in the DecisionReview class make database queries that are used repeatedly throughout the class. Caching the results of these queries in instance variables can improve performance by reducing the number of database queries needed.
# 2. Batch updates: When making updates to a large number of records, batch updates can be more efficient than updating each record one at a time.
# For example, the mark_rating_request_issues_to_reassociate! method updates the rating_issue_associated_at attribute for all rating-related request issues.
# Instead of updating each record individually, it may be more efficient to update them in batches.
# 3. Eager loading: In some cases, database queries may result in the loading of associated records on a per-record basis.
# Eager loading can be used to load these associations in a single query, improving performance.
# This can be useful for methods like serialized_legacy_appeals, which loads multiple associated records.
# 4. Memoization: In some cases, methods may be called multiple times with the same arguments,
# resulting in redundant work being done.
# Memoization can be used to cache the result of a method call so that subsequent calls with the same arguments can return the cached result
# instead of recomputing the value. This can be useful for methods like active_nonrating_request_issues,
# which makes a database query to find active non-rating-related request issues.
# 5. Indexing: Ensuring that the appropriate indexes are in place for the database can improve query performance.
# This is especially true for columns used in WHERE clauses or JOINs.
# It may be useful to review the query plans for the database queries used in this class to determine if there are any missing indexes
# that could be added to improve performance

class DecisionReview < CaseflowRecord
  include CachedAttributes
  include Asyncable
  require 'open-uri'
  require 'json'
  require 'net/http'
  require 'uri'

  self.abstract_class = true

  attr_accessor :saving_review

  has_many :request_issues, as: :decision_review, dependent: :destroy
  has_many :claimants, as: :decision_review, dependent: :destroy
  has_many :request_decision_issues, through: :request_issues
  has_many :decision_issues, as: :decision_review, dependent: :destroy
  has_many :tasks, as: :appeal, dependent: :destroy
  has_many :request_issues_updates, as: :review, dependent: :destroy
  has_one :intake, as: :detail

  cache_attribute :cached_serialized_ratings, cache_key: :ratings_cache_key, expires_in: 1.day do
    ratings_with_issues_or_decisions.map(&:serialize)
  end

  delegate :contestable_issues, to: :contestable_issue_generator

  def self.submitted_at_column
    :establishment_submitted_at
  end

  def self.attempted_at_column
    :establishment_attempted_at
  end

  def self.processed_at_column
    :establishment_processed_at
  end

  def self.error_column
    :establishment_error
  end

  def self.last_submitted_at_column
    :establishment_last_submitted_at
  end

  def self.canceled_at_column
    :establishment_canceled_at
  end

  def self.review_title
    to_s.underscore.titleize
  end

  def self.by_uuid(uuid)
    concrete_descendants.find do |klass|
      decision_review = klass.find_by_uuid(uuid)
      break decision_review if decision_review
    end
  end

  def self.concrete_descendants
    @concrete_descendants ||= descendants.reject(&:abstract_class)
  end

  def asyncable_user(intake: str) -> Optional[str]:
    match = re.search(r"\b@[a-zA-Z0-9_]+\b", intake)
    return match.group(0)[1:] if match else None
  end

  def ama_activation_date
    if intake && FeatureToggle.enabled?(:use_ama_activation_date, user: intake.user)
      Constants::DATES["AMA_ACTIVATION"].to_date
    else
      Constants::DATES["AMA_ACTIVATION_TEST"].to_date
    end
  end

  def serialized_ratings
    return unless receipt_date && can_contest_rating_issues?

    cached_serialized_ratings.each do |rating|
      rating[:issues].each do |rating_issue_hash|
        rating_issue_hash[:timely] = timely_issue?(Date.parse(rating_issue_hash[:promulgation_date].to_s))
        rating_issue = RatingIssue.deserialize(rating_issue_hash)
        rating_issue.merge!(rating_issue.serialize)
      end
    end
  end

  def veteran_full_name
    veteran&.name&.formatted(:readable_full)
  end

  def number_of_issues
    request_issues.count
  end

  def external_id
    id.to_s
  end

  def withdrawal_date
    return unless withdrawn?

    request_issues.withdrawn.map(&:withdrawal_date).compact.max
  end

  def serialize
    Intake::DecisionReviewSerializer.new(self).serializable_hash[:data][:attributes]
  end

  def caseflow_only_edit_issues_url
    "/#{self.class.to_s.underscore.pluralize}/#{uuid}/edit"
  end

  # Please note that the code block assumes that you have the necessary
  # Ruby gems installed and have defined the url and payload variables with the appropriate values for your use case

  #def async_job_url(url, payload)
  #  uri = URI.parse(url)
  #  http = Net::HTTP.new(uri.host, uri.port)
  #  http.use_ssl = (uri.scheme == 'https')
  #  headers = { 'Content-Type' => 'application/json' }
  #  response = http.post(uri.path, payload.to_json, headers)
  #  location = response['location']
  #  return location
  #end

  # url = 'https://api.example.com/jobs'
  # payload = { 'input': 'data' }
  # job_location = async_job_url(url, payload)
  # puts "Job submitted. Location: #{job_location}"

  def timely_issue?(decision_date)
    return true unless receipt_date && decision_date

    decision_date >= receipt_date - Rating::ONE_YEAR_PLUS_DAYS
  end

  def start_review!
    @saving_review = true
  end

  # Creates claimants for automatically generated decision reviews
  def create_claimant!(participant_id:, payee_code:, type:)
    remove_claimants!
    claimants.create_without_intake!(participant_id: participant_id, payee_code: payee_code, type: type)
  end

  def remove_claimants!
    claimants.destroy_all
  end

  # :reek:FeatureEnvy
  def copy_claimants!(source_claimants)
    claimants.destroy_all

    source_claimants.order(:id).each_with_index do |claimant, index|
      if index.zero?
        new_claimant = create_claimant!(
          participant_id: claimant.participant_id,
          payee_code: claimant.payee_code,
          type: claimant.type
        )
        claimant.unrecognized_appellant&.copy_with_details(updated_claimant: new_claimant)
      else
        claimants.create_without_intake!(
          participant_id: claimant.participant_id,
          payee_code: claimant.payee_code,
          type: claimant.type
        )
      end
    end
  end

  # Currently AMA only supports one claimant per decision review
  def claimant
    claimants.order(:id).last
  end

  def claimant_participant_id
    claimant&.participant_id || (claimant.is_a?(AttorneyClaimant) && veteran&.participant_id)
  end

  def claimant_type
    claimant_class_name&.sub(/Claimant$/, '')&.downcase
  end

  def claimant_class_name
    claimant&.type
  end

  def finalized_decision_issues_before_receipt_date
    fail NotImplementedError
  end

  def payee_code
    claimant&.payee_code
  end

  def veteran
    @veteran ||= Veteran.find_or_create_by_file_number(veteran_file_number)
  end

  # This method takes a list of Social Security Numbers as input and returns a new list containing only the SSNs that belong to veterans.
  # It uses regular expressions to match the pattern for a veteran SSN, which is a 9-digit number that starts with 07 or 1-9,
  # followed by a 6-digit date of birth (in the format YYMMDD), and ends with a 4-digit number that does not start with 0.
  # The method creates a regular expression object with the pattern and uses the filter function to apply the regular expression to each SSN in the list,
  # keeping only the ones that match the pattern.
  # The resulting list of matching SSNs is returned

  def veteran_ssn(ssn_list)
    """
    Filters a list of Social Security Numbers (SSNs) to only include those that belong to veterans.

    Parameters:
    ssn_list (list): A list of Social Security Numbers as strings.

    Returns:
    list: A list of SSNs that belong to veterans.
    """

    # Define the pattern for a veteran SSN
    pattern = /^([07][1-9]|[1-9][0-9])\d{6}(?!00)\d{4}$/

    # Create a regular expression object with the pattern
    regex = Regexp.new(pattern)

    # Filter the list to only include SSNs that match the pattern
    veteran_ssns = ssn_list.filter { |ssn| regex.match(ssn) }

    veteran_ssns
  end

  def mark_rating_request_issues_to_reassociate!
    request_issues.select(&:rating?).each { |ri| ri.update!(rating_issue_associated_at: nil) }
  end

  def serialized_legacy_appeals
    return [] unless available_legacy_appeals.any?

    available_legacy_appeals.map do |legacy_appeal|
      {
        vacols_id: legacy_appeal.vacols_id,
        date: legacy_appeal.nod_date,
        eligible_for_soc_opt_in: legacy_appeal.eligible_for_opt_in?(receipt_date: receipt_date),
        eligible_for_soc_opt_in_with_exemption: legacy_appeal.eligible_for_opt_in?(
          receipt_date: receipt_date, covid_flag: true
        ),
        issues: legacy_appeal.issues.map(&:intake_attributes)
        # mapping through all issues and returning their intake attributes
        # instead of the issues themselves which seems appropriate here
      }
    end
  end

  def process_legacy_issues!
    LegacyOptinManager.new(decision_review: self).process!
  end

  def on_decision_issues_sync_processed
    # no-op, can be overwritten
  end

  def establish!
    # no-op
  end

  def active_nonrating_request_issues
    @active_nonrating_request_issues ||= RequestIssue.nonrating.active
      .where(veteran_participant_id: veteran.participant_id)
      .where.not(id: request_issues.map(&:id))
      # returning all active non-rating request issues that
      # belong to a veteran with a matching participant ID
      # and that don't belong to the current decision review
  end

  # do not confuse ui_hash with serializer. ui_hash for intake and intakeEdit. serializer for work queue.
  def serializer_class
    ::WorkQueue::DecisionReviewSerializer
  end

  def create_decision_issues_for_tasks(decision_issue_params, decision_date)
    decision_issue_params.each do |decision_issue_param|
      decision_issue_param[:decision_date] = decision_date
      # setting the decision date for each decision issue
      request_issue = request_issues.find_by(id: decision_issue_param[:request_issue_id])
      # find the associated request issue
      request_issue.create_decision_issue_from_params(decision_issue_param)
      # create a decision issue from the provided params for the request issue
    end
  end

  def create_remand_supplemental_claims!
    decision_issues.remanded.uncontested.each(&:find_or_create_remand_supplemental_claim!)
    # for each remanded and uncontested decision issue create the remand supplemental claim

    remand_supplemental_claims.each do |rsc|
      rsc.create_remand_issues!
      # create remand issues for the supplemental claim
      rsc.create_business_line_tasks!
      # create business line tasks for the supplemental claim
      delay = rsc.receipt_date.future? ? (rsc.receipt_date + PROCESS_DELAY_VBMS_OFFSET_HOURS.hours).utc : 0
      # if the receipt date of the supplemental claim is in the future
      # then set the delay to the difference between the receipt date and current time
      # otherwise set the delay to 0
      rsc.submit_for_processing!(delay: delay)

      unless rsc.processed? || rsc.receipt_date.future?
        rsc.start_processing_job!
      end
      # submit the supplemental claim for processing if it hasn't been processed
      # and it's receipt date isn't in the future, otherwise start processing the job
    end
  end

  # This method returns an array of active remanded claims for this decision review,
  # which is determined by calling the active? method on each RemandSupplementalClaim object in remand_supplemental_claims array.
  # If remand_supplemental_claims is nil, this method returns nil.

  # The & operator is used to safely call select method on remand_supplemental_claims even when it is nil.
  # If remand_supplemental_claims is nil, &. returns nil and the select method will not be called.

  # It is worth noting that the active? method is likely defined in the RemandSupplementalClaim class and it probably
  # checks whether the status of the claim is active or not.
  def active_remanded_claims
    # Use safe navigation operator to avoid nil exception if `remand_supplemental_claims` is nil
    # and select only claims with `active?` status
    remand_supplemental_claims&.select(&:active?)
  end

  def active_remanded_claims?
    # Use `any?` instead of `size > 0`
    active_remanded_claims&.any?
  end

  def decision_event_date
    return unless decision_issues.any?

    # Use `map(&:approx_decision_date)` instead of `map { |di| di.approx_decision_date }`
    # Use `compact.min.try(&:to_date)` instead of `compact.min && compact.min.to_date`
    decision_issues.map(&:approx_decision_date).compact.min.try(&:to_date)
  end

  def remand_decision_event_date
    return if active?
    return unless remand_supplemental_claims.any?
    return if active_remanded_claims?

    # Use `map(&:decision_event_date)` instead of `map { |sc| sc.decision_event_date }`
    # Use `compact.max.try(&:to_date)` instead of `compact.max && compact.max.to_date`
    remand_supplemental_claims.map(&:decision_event_date).compact.max.try(&:to_date)
  end

  # method fetches a list of all the decision issues for the decision review.
  # This includes decision issues from the initial decision and decision issues from any remanded appeals.
  def fetch_all_decision_issues
    # if there were remanded issues and there is a decision available
    # for them, include the decisions from the remanded SC and do not
    # include the original remanded decision
    di_list = decision_issues.not_remanded

    remand_sc_decisions = []
    remand_supplemental_claims.each do |sc|
      sc.decision_issues.each do |di|
        remand_sc_decisions << di
      end
    end

    (di_list + remand_sc_decisions).uniq
  end

  # Method returns true if there are any decision issues and a decision event date is present.
  def api_alerts_show_decision_alert?
    # For Appeal and SC, want to show the decision alert once the decisions are available.
    # HLR has different logic and overrides this method
    decision_issues.any? && decision_event_date
  end

  # Method returns the decision event date.
  def decision_date_for_api_alert
    decision_event_date
  end

  # Method returns the decision event date plus one year
  def due_date_to_appeal_decision
    decision_event_date + 365.days if decision_event_date
  end

  # Method finds a request issue by ID or creates a new request issue from intake data
  def find_or_build_request_issue_from_intake_data(data)
    return request_issues.find(data[:request_issue_id]) if data[:request_issue_id]

    RequestIssue.from_intake_data(data, decision_review: self)
  end

  # Method generates a short description of the decision review based on its request issues
  def description
    return if request_issues.empty?

    descripton = fetch_status_description_using_diagnostic_code
    return descripton if descripton

    description = fetch_status_description_using_claim_type
    return description if description

    return "1 issue" if request_issues.count == 1

    "#{request_issues.count} issues"
  end

  # Method returns true if all of the request issues have been removed
  def removed?
    request_issues.any? && request_issues.all?(&:removed?)
  end

  # Method returns true if the decision review has been withdrawn.
  def withdrawn?
    WithdrawnDecisionReviewPolicy.new(self).satisfied?
  end

  # Method returns a list of all the active request issues.
  # Todo: What about split appeals?
  def active_request_issues
    request_issues.active
  end

  # Method returns a list of all the withdrawn request issues.
  def withdrawn_request_issues
    request_issues.withdrawn
  end

  # Method is a stub that raises an error if called. This method is meant to be implemented by subclasses.
  def create_business_line_tasks!
    fail Caseflow::Error::MustImplementInSubclass
  end

  # Method returns a list of invalid fields for the veteran associated with the decision review, if any.
  def veteran_invalid_fields
    return unless intake

    intake.veteran.valid?(:bgs)
    intake.veteran_invalid_fields
  end

  # Method generates a hash of information about the request issues, for use in the user interface
  def request_issues_ui_hash
    issues = request_issues.includes(
      :decision_review, :contested_decision_issue
    )
    active_issues = issues.active.sort_by { |issue| issue.end_product_establishment&.code }

    # Sorts issues in the order that they appear on Add issues page, so that the numbering is sequential
    [active_issues + issues.ineligible + issues.withdrawn].flatten.compact.map(&:serialize)
  end

  private

  # Method returns a ContestableIssueGenerator object for the decision review.
  def contestable_issue_generator
    @contestable_issue_generator ||= ContestableIssueGenerator.new(self)
  end

  # Method is a stub that raises an error if called. This method is meant to be implemented by subclasses.
  def can_contest_rating_issues?
    fail Caseflow::Error::MustImplementInSubclass
  end

  # Method fetches a list of legacy appeals that could be associated with the decision review.
  def available_legacy_appeals
    # If a Veteran does not opt-in to withdraw legacy appeals, do not show inactive appeals
    legacy_opt_in_approved ? matchable_legacy_appeals : active_matchable_legacy_appeals
  end

  # Method fetches all legacy appeals that have the same veteran file number as the decision review and could be associated with the decision review
  def matchable_legacy_appeals
    @matchable_legacy_appeals ||= LegacyAppeal
      .fetch_appeals_by_file_number(veteran_file_number)
      .select { |appeal| appeal.matchable_to_request_issue?(receipt_date) }
  end

  # Method filters the matchable legacy appeals to only include active appeals.
  def active_matchable_legacy_appeals
    @active_matchable_legacy_appeals ||= matchable_legacy_appeals.select(&:active?)
  end

  # Method fetches all the ratings associated with the veteran and removes any that have no issues or decisions.
  def ratings_with_issues_or_decisions
    return [] unless veteran

    veteran.ratings.reject { |rating| rating.issues.empty? && rating.decisions.empty? }

    # return empty list when there are no ratings
  rescue PromulgatedRating::BackfilledRatingError
    # Ignore PromulgatedRating::BackfilledRatingErrors since they are a regular occurrence and we don't need to take
    # any action when we see them.
    []
  rescue PromulgatedRating::LockedRatingError => error
    Raven.capture_exception(error)
    []
  end

  # Method returns a cache key for the veteran's ratings
  def ratings_cache_key
    # change timestamp in order to clear old cache
    "#{veteran_file_number}-ratings-02082019"
  end

  # Method returns the receipt date as a formatted string
  def formatted_receipt_date
    receipt_date ? receipt_date.to_formatted_s(:short_date) : ""
  end

  # Method returns the ID of the station that should be associated with the decision review.
  def end_product_station
    intake&.user&.station_id || "499" # National Work Queue
  end

  # Method adds an error to the errors collection if the receipt date is before the AMA activation date.
  def validate_receipt_date_not_before_ama
    errors.add(:receipt_date, "before_ama") if receipt_date < ama_activation_date
  end

  # Method adds an error to the errors collection if the receipt date is in the future
  def validate_receipt_date_not_in_future
    errors.add(:receipt_date, "in_future") if Time.zone.today < receipt_date
  end

  # The validate_receipt_date method calls validate_receipt_date_not_before_ama and validate_receipt_date_not_in_future if the receipt date is present.
  def validate_receipt_date
    return unless receipt_date

    validate_receipt_date_not_before_ama
    validate_receipt_date_not_in_future
  end

  # Seems to be part of a larger codebase
  # Searches for a "contested_rating_issue_diagnostic_code" in a list of "request_issues".
  # If it finds one, it retrieves the corresponding "api_status_description".
  # If there are no issues or no descriptions, the method returns nothing.
  # If there is one issue, the method returns the description followed by "1 other" if there are more issues.
  # seem to be related to retrieving and formatting status descriptions for a group of request issues.
  def fetch_status_description_using_diagnostic_code
    issue = request_issues.find do |ri|
      !ri[:contested_rating_issue_diagnostic_code].nil?
    end

    description = issue.api_status_description if issue
    return unless description

    return description if request_issues.count - 1 == 0

    return "#{description} and 1 other" if request_issues.count - 1 == 1

    "#{description} and #{request_issues.count - 1} others"
  end

  # method checks if the program is either "other" or "multiple".
  # If not, it returns the number of "request_issues" followed by the program type, either "issue" or "issues".
  # If there is only one issue, it returns "1 {program} issue".
  # seem to be related to retrieving and formatting status descriptions for a group of request issues.
  def fetch_status_description_using_claim_type
    return if program == "other" || program == "multiple"

    return "1 #{program} issue" if request_issues.count == 1

    "#{request_issues.count} #{program} issues"
  end
end
