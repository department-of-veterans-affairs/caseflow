# frozen_string_literal: true

class DecisionReview < CaseflowRecord
  include CachedAttributes
  include Asyncable

  self.abstract_class = true

  attr_reader :saving_review

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

  # The Asyncable module requires we define these.
  # establishment_submitted_at - when our db is ready to push to exernal services
  # establishment_attempted_at - when our db attempted to push to external services
  # establishment_processed_at - when our db successfully pushed to external services
  # establishment_error        - capture exception messages on failures

  class << self
    def submitted_at_column
      :establishment_submitted_at
    end

    def attempted_at_column
      :establishment_attempted_at
    end

    def processed_at_column
      :establishment_processed_at
    end

    def error_column
      :establishment_error
    end

    def last_submitted_at_column
      :establishment_last_submitted_at
    end

    def canceled_at_column
      :establishment_canceled_at
    end

    def review_title
      to_s.underscore.titleize
    end

    # Find the DecisionReview that has the given uuid, whether it's an Appeal, HigherLevelReview,
    # etc. --any non-abstract descendant of DecisionReview.
    # Purposely trying to not clobber find_by_uuid
    def by_uuid(uuid)
      concrete_descendants.find do |klass|
        decision_review = klass.find_by_uuid(uuid)
        break decision_review if decision_review
      end
    end

    def concrete_descendants
      @concrete_descendants ||= descendants.reject(&:abstract_class)
    end
  end

  def asyncable_user
    intake&.user
  end

  def ama_activation_date
    if intake && FeatureToggle.enabled?(:use_ama_activation_date, user: intake.user)
      Constants::DATES["AMA_ACTIVATION"].to_date
    else
      Constants::DATES["AMA_ACTIVATION_TEST"].to_date
    end
  end

  def serialized_ratings
    return unless receipt_date
    return unless can_contest_rating_issues?

    cached_serialized_ratings.each do |rating|
      rating[:issues].each do |rating_issue_hash|
        rating_issue_hash[:timely] = timely_issue?(Date.parse(rating_issue_hash[:promulgation_date].to_s))
        # always re-compute flags that depend on data in our db
        rating_issue_hash.merge!(RatingIssue.deserialize(rating_issue_hash).serialize)
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

  def async_job_url
    nil # must override in subclass
  end

  def timely_issue?(decision_date)
    return true unless receipt_date && decision_date

    decision_date >= (receipt_date - Rating::ONE_YEAR_PLUS_DAYS)
  end

  def start_review!
    @saving_review = true
  end

  # Creates claimants for automatically generated decision reviews
  def create_claimant!(participant_id:, payee_code:, type:, unrecognized_appellant:)
    remove_claimants!
    claimants.create_without_intake!(participant_id: participant_id, payee_code: payee_code,
      type: type, unrecognized_appellant: unrecognized_appellant)
  end

  def remove_claimants!
    claimants.each(&:destroy!)
  end

  # :reek:FeatureEnvy
  def copy_claimants!(source_claimants)
    # maintain the same ordering as used in the claimant method below so that claimant returns the correct one
    source_claimants.order(:id).each_with_index do |claimant, index|
      if index == 0
        create_claimant!(
          participant_id: claimant.participant_id,
          payee_code: claimant.payee_code,
          type: claimant.type,
          unrecognized_appellant: claimant.unrecognized_appellant
        )
      else
        # Since create_claimant! removes all claimants, don't call it again
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
    # EPs with an AttorneyClaimant need to be established with the veteran's participant ID, per BVA
    claimant.is_a?(AttorneyClaimant) ? veteran&.participant_id : claimant&.participant_id
  end

  def claimant_type
    claimant_class_name&.sub(/Claimant$/, "")&.downcase
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

  def veteran_ssn
    veteran&.ssn
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
  end

  # do not confuse ui_hash with serializer. ui_hash for intake and intakeEdit. serializer for work queue.
  def serializer_class
    ::WorkQueue::DecisionReviewSerializer
  end

  def create_decision_issues_for_tasks(decision_issue_params, decision_date)
    decision_issue_params.each do |decision_issue_param|
      decision_issue_param[:decision_date] = decision_date
      request_issues.find_by(id: decision_issue_param[:request_issue_id])
        .create_decision_issue_from_params(decision_issue_param)
    end
  end

  def create_remand_supplemental_claims!
    decision_issues.remanded.uncontested.each(&:find_or_create_remand_supplemental_claim!)

    remand_supplemental_claims.each do |rsc|
      rsc.create_remand_issues!
      rsc.create_business_line_tasks!

      delay = rsc.receipt_date.future? ? (rsc.receipt_date + PROCESS_DELAY_VBMS_OFFSET_HOURS.hours).utc : 0
      rsc.submit_for_processing!(delay: delay)

      unless rsc.processed? || rsc.receipt_date.future?
        rsc.start_processing_job!
      end
    end
  end

  def active_remanded_claims
    remand_supplemental_claims&.select(&:active?)
  end

  def active_remanded_claims?
    active_remanded_claims&.any?
  end

  def decision_event_date
    return unless decision_issues.any?

    decision_issues.map(&:approx_decision_date).compact.min.try(&:to_date)
  end

  def remand_decision_event_date
    return if active?
    return unless remand_supplemental_claims.any?
    return if active_remanded_claims?

    remand_supplemental_claims.map(&:decision_event_date).compact.max.try(&:to_date)
  end

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

  def api_alerts_show_decision_alert?
    # For Appeal and SC, want to show the decision alert once the decisions are available.
    # HLR has different logic and overrides this method
    decision_issues.any? && decision_event_date
  end

  def decision_date_for_api_alert
    decision_event_date
  end

  def due_date_to_appeal_decision
    decision_event_date + 365.days if decision_event_date
  end

  def find_or_build_request_issue_from_intake_data(data)
    return request_issues.find(data[:request_issue_id]) if data[:request_issue_id]

    RequestIssue.from_intake_data(data, decision_review: self)
  end

  def description
    return if request_issues.empty?

    descripton = fetch_status_description_using_diagnostic_code
    return descripton if descripton

    description = fetch_status_description_using_claim_type
    return description if description

    return "1 issue" if request_issues.count == 1

    "#{request_issues.count} issues"
  end

  def removed?
    request_issues.any? && request_issues.all?(&:removed?)
  end

  def withdrawn?
    WithdrawnDecisionReviewPolicy.new(self).satisfied?
  end

  def active_request_issues
    request_issues.active
  end

  def withdrawn_request_issues
    request_issues.withdrawn
  end

  def create_business_line_tasks!
    fail Caseflow::Error::MustImplementInSubclass
  end

  def veteran_invalid_fields
    return unless intake

    intake.veteran.valid?(:bgs)
    intake.veteran_invalid_fields
  end

  def request_issues_ui_hash
    issues = request_issues.includes(
      :decision_review, :contested_decision_issue
    )
    active_issues = issues.active.sort_by { |issue| issue.end_product_establishment&.code }

    # Sorts issues in the order that they appear on Add issues page, so that the numbering is sequential
    [active_issues + issues.ineligible + issues.withdrawn].flatten.compact.map(&:serialize)
  end

  private

  def contestable_issue_generator
    @contestable_issue_generator ||= ContestableIssueGenerator.new(self)
  end

  def can_contest_rating_issues?
    fail Caseflow::Error::MustImplementInSubclass
  end

  def available_legacy_appeals
    # If a Veteran does not opt-in to withdraw legacy appeals, do not show inactive appeals
    legacy_opt_in_approved ? matchable_legacy_appeals : active_matchable_legacy_appeals
  end

  def matchable_legacy_appeals
    @matchable_legacy_appeals ||= LegacyAppeal
      .fetch_appeals_by_file_number(veteran_file_number)
      .select { |appeal| appeal.matchable_to_request_issue?(receipt_date) }
  end

  def active_matchable_legacy_appeals
    @active_matchable_legacy_appeals ||= matchable_legacy_appeals.select(&:active?)
  end

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

  def ratings_cache_key
    # change timestamp in order to clear old cache
    "#{veteran_file_number}-ratings-02082019"
  end

  def formatted_receipt_date
    receipt_date ? receipt_date.to_formatted_s(:short_date) : ""
  end

  def end_product_station
    intake&.user&.station_id || "499" # National Work Queue
  end

  def validate_receipt_date_not_before_ama
    errors.add(:receipt_date, "before_ama") if receipt_date < ama_activation_date
  end

  def validate_receipt_date_not_in_future
    errors.add(:receipt_date, "in_future") if Time.zone.today < receipt_date
  end

  def validate_receipt_date
    return unless receipt_date

    validate_receipt_date_not_before_ama
    validate_receipt_date_not_in_future
  end

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

  def fetch_status_description_using_claim_type
    return if program == "other" || program == "multiple"

    return "1 #{program} issue" if request_issues.count == 1

    "#{request_issues.count} #{program} issues"
  end
end
