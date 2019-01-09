class RequestIssue < ApplicationRecord
  include Asyncable

  belongs_to :review_request, polymorphic: true
  belongs_to :decision_review, polymorphic: true
  belongs_to :end_product_establishment
  has_many :request_decision_issues
  has_many :decision_issues, through: :request_decision_issues
  has_many :remand_reasons
  has_many :duplicate_but_ineligible, class_name: "RequestIssue", foreign_key: "ineligible_due_to_id"
  has_one :legacy_issue_optin
  belongs_to :ineligible_due_to, class_name: "RequestIssue", foreign_key: "ineligible_due_to_id"
  belongs_to :contested_decision_issue, class_name: "DecisionIssue", foreign_key: "contested_decision_issue_id"

  # enum is symbol, but validates requires a string
  validates :ineligible_reason, exclusion: { in: ["untimely"] }, if: proc { |reqi| reqi.untimely_exemption }

  enum ineligible_reason: {
    duplicate_of_nonrating_issue_in_active_review: "duplicate_of_nonrating_issue_in_active_review",
    duplicate_of_rating_issue_in_active_review: "duplicate_of_rating_issue_in_active_review",
    untimely: "untimely",
    higher_level_review_to_higher_level_review: "higher_level_review_to_higher_level_review",
    appeal_to_appeal: "appeal_to_appeal",
    appeal_to_higher_level_review: "appeal_to_higher_level_review",
    before_ama: "before_ama",
    legacy_issue_not_withdrawn: "legacy_issue_not_withdrawn",
    legacy_appeal_not_eligible: "legacy_appeal_not_eligible"
  }

  # TEMPORARY CODE: used to keep decision_review and review_request in sync
  before_save :copy_review_request_to_decision_review
  before_save :set_contested_rating_issue_profile_date

  class ErrorCreatingDecisionIssue < StandardError
    def initialize(request_issue_id)
      super("Request Issue #{request_issue_id} cannot create decision issue " \
        "due to not having any matching rating issues or contentions")
    end
  end

  UNIDENTIFIED_ISSUE_MSG = "UNIDENTIFIED ISSUE - Please click \"Edit in Caseflow\" button to fix".freeze

  class << self
    def submitted_at_column
      :decision_sync_submitted_at
    end

    def attempted_at_column
      :decision_sync_attempted_at
    end

    def processed_at_column
      :decision_sync_processed_at
    end

    def error_column
      :decision_sync_error
    end

    def rating
      where.not(
        contested_rating_issue_reference_id: nil
      ).or(where(is_unidentified: true))
    end

    def nonrating
      where(
        contested_rating_issue_reference_id: nil,
        is_unidentified: [nil, false]
      ).where.not(issue_category: nil)
    end

    def unidentified
      where(
        contested_rating_issue_reference_id: nil,
        is_unidentified: true
      )
    end

    # ramp_claim_id is set to the claim id of the RAMP EP when the contested rating issue is part of a ramp decision
    def from_intake_data(data)
      new(
        attributes_from_intake_data(data)
      ).tap(&:validate_eligibility!)
    end

    def find_or_build_from_intake_data(data)
      # request issues on edit have ids
      # but newly added issues do not
      data[:request_issue_id] ? find(data[:request_issue_id]) : from_intake_data(data)
    end

    def find_active_by_contested_rating_issue_reference_id(rating_issue_reference_id)
      request_issue = unscoped.find_by(
        contested_rating_issue_reference_id: rating_issue_reference_id,
        removed_at: nil,
        ineligible_reason: nil
      )

      return unless request_issue&.status_active?

      request_issue
    end

    def find_active_by_contested_decision_id(contested_decision_issue_id)
      request_issue = unscoped.find_by(contested_decision_issue_id: contested_decision_issue_id,
                                       removed_at: nil, ineligible_reason: nil)
      return unless request_issue&.status_active?

      request_issue
    end

    private

    # rubocop:disable Metrics/MethodLength
    def attributes_from_intake_data(data)
      contested_issue_present = data[:rating_issue_reference_id] || data[:contested_decision_issue_id]

      {
        # TODO: these are going away in favor of `contested_rating_issue_*`
        rating_issue_reference_id: data[:rating_issue_reference_id],
        rating_issue_profile_date: data[:rating_issue_profile_date],

        description: data[:decision_text],

        contested_rating_issue_reference_id: data[:rating_issue_reference_id],

        contested_issue_description: contested_issue_present ? data[:decision_text] : nil,
        nonrating_issue_description: data[:issue_category] ? data[:decision_text] : nil,
        unidentified_issue_text: data[:is_unidentified] ? data[:decision_text] : nil,

        decision_date: data[:decision_date],
        issue_category: data[:issue_category],
        notes: data[:notes],
        is_unidentified: data[:is_unidentified],
        untimely_exemption: data[:untimely_exemption],
        untimely_exemption_notes: data[:untimely_exemption_notes],
        ramp_claim_id: data[:ramp_claim_id],
        vacols_id: data[:vacols_id],
        vacols_sequence_id: data[:vacols_sequence_id],
        contested_decision_issue_id: data[:contested_decision_isssue_id],
        ineligible_reason: data[:ineligible_reason],
        ineligible_due_to_id: data[:ineligible_due_to_id]
      }
    end
  end
  # rubocop:enable Metrics/MethodLength

  def status_active?
    return appeal_active? if review_request.is_a?(Appeal)
    return false unless end_product_establishment

    end_product_establishment.status_active?
  end

  def rating?
    contested_rating_issue_reference_id
  end

  def nonrating?
    issue_category && decision_date
  end

  def contention_text
    return "#{issue_category} - #{description}" if nonrating?
    return UNIDENTIFIED_ISSUE_MSG if is_unidentified

    description
  end

  def review_title
    review_request_type.try(:constantize).try(:review_title)
  end

  def eligible?
    ineligible_reason.nil?
  end

  def special_issues
    specials = []
    specials << { code: "VO", narrative: Constants.VACOLS_DISPOSITIONS_BY_ID.O } if legacy_issue_opted_in?
    specials << { code: "SSR", narrative: "Same Station Review" } if decision_review.try(:same_office)
    return specials unless specials.empty?
  end

  def ui_hash
    {
      id: id,
      rating_issue_reference_id: contested_rating_issue_reference_id,
      rating_issue_profile_date: contested_rating_issue_profile_date,
      description: description,
      contention_text: contention_text,
      decision_date: contested_issue ? contested_issue.date : decision_date,
      category: issue_category,
      notes: notes,
      is_unidentified: is_unidentified,
      ramp_claim_id: ramp_claim_id,
      vacols_id: vacols_id,
      vacols_sequence_id: vacols_sequence_id,
      vacols_issue: vacols_issue.try(:intake_attributes),
      ineligible_reason: ineligible_reason,
      ineligible_due_to_id: ineligible_due_to_id,
      review_request_title: review_title,
      title_of_active_review: title_of_active_review,
      contested_decision_issue_id: contested_decision_issue_id
    }
  end

  def validate_eligibility!
    check_for_active_request_issue!
    check_for_untimely!
    check_for_eligible_previous_review!
    check_for_before_ama!
    check_for_legacy_issue_not_withdrawn!
    check_for_legacy_appeal_not_eligible!
    self
  end

  def contested_rating_issue
    return unless review_request
    return unless contested_rating_issue_reference_id

    @contested_rating_issue ||= begin
      contested_rating_issue_ui_hash = fetch_contested_rating_issue_ui_hash
      contested_rating_issue_ui_hash ? RatingIssue.deserialize(contested_rating_issue_ui_hash) : nil
    end
  end

  def previous_request_issue
    contested_decision_issue&.request_issues&.first
  end

  def sync_decision_issues!
    return if processed?

    attempted!
    decision_issues.delete_all
    create_decision_issues

    end_product_establishment.on_decision_issue_sync_processed
  end

  def create_legacy_issue_optin
    LegacyIssueOptin.create!(
      request_issue: self,
      vacols_id: vacols_id,
      vacols_sequence_id: vacols_sequence_id,
      original_disposition_code: vacols_issue.disposition_id,
      original_disposition_date: vacols_issue.disposition_date
    )
  end

  def vacols_issue
    return unless vacols_id && vacols_sequence_id

    @vacols_issue ||= AppealRepository.issues(vacols_id).find do |issue|
      issue.vacols_sequence_id == vacols_sequence_id
    end
  end

  def legacy_issue_opted_in?
    eligible? && vacols_id && vacols_sequence_id
  end

  # Instead of fully deleting removed issues, we instead strip them from the review so we can
  # maintain a record of the other data that was on them incase we need to revert the update.
  def remove_from_review
    update!(review_request: nil)
    legacy_issue_optin&.flag_for_rollback!

    # removing a request issue also deletes the associated request_decision_issue
    # if the decision issue is not associated with any other request issue, also delete
    decision_issues.each { |decision_issue| decision_issue.destroy_on_removed_request_issue(id) }
    decision_issues.delete_all
  end

  private

  # The contested_rating_issue_profile_date is used as an identifier to retrieve the
  # appropriate rating. It needs to be saved in the same format and time zone that it
  # was fetched from BGS in order for it to work as an identifier.
  #
  # In order to prevent browser/API automatic time zone changes from altering it, we
  # re-retrieve the value from the cache and save it to the DB as a string. Yikes.
  def set_contested_rating_issue_profile_date
    self.contested_rating_issue_profile_date ||= contested_rating_issue&.profile_date
  end

  def build_contested_issue
    return unless review_request

    if contested_decision_issue
      ContestableIssue.from_decision_issue(contested_decision_issue, review_request)
    elsif contested_rating_issue
      ContestableIssue.from_rating_issue(contested_rating_issue, review_request)
    end
  end

  def contested_issue
    @contested_issue ||= build_contested_issue
  end

  def title_of_active_review
    duplicate_of_issue_in_active_review? ? ineligible_due_to.review_title : nil
  end

  def duplicate_of_issue_in_active_review?
    duplicate_of_rating_issue_in_active_review? || duplicate_of_nonrating_issue_in_active_review?
  end

  def create_decision_issues
    if rating?
      return unless end_product_establishment.associated_rating

      create_decision_issues_from_rating
    end

    create_decision_issue_from_disposition if decision_issues.empty?

    fail ErrorCreatingDecisionIssue, id if decision_issues.empty?

    processed!
  end

  def matching_rating_issues
    @matching_rating_issues ||= end_product_establishment.associated_rating.issues.select do |rating_issue|
      rating_issue.contention_reference_id == contention_reference_id
    end
  end

  def create_decision_issue_from_disposition
    if contention_disposition
      decision_issues.create!(
        participant_id: review_request.veteran.participant_id,
        disposition: contention_disposition.disposition,
        decision_review: review_request,
        benefit_type: benefit_type,
        end_product_last_action_date: end_product_establishment.result.last_action_date
      )
    end
  end

  def contention_disposition
    @contention_disposition ||= end_product_establishment.fetch_dispositions_from_vbms.find do |disposition|
      disposition.contention_id.to_i == contention_reference_id
    end
  end

  def create_decision_issues_from_rating
    matching_rating_issues.each do |rating_issue|
      decision_issues.create!(
        rating_issue_reference_id: rating_issue.reference_id,
        participant_id: rating_issue.participant_id,
        promulgation_date: rating_issue.promulgation_date,
        decision_text: rating_issue.decision_text,
        profile_date: rating_issue.profile_date,
        decision_review: review_request,
        benefit_type: benefit_type,
        end_product_last_action_date: end_product_establishment.result.last_action_date
      )
    end
  end

  # RatingIssue is not in db so we pull hash from the serialized_ratings.
  # TODO: performance could be improved by using the profile date by loading the specific rating
  def fetch_contested_rating_issue_ui_hash
    return unless review_request.serialized_ratings

    rating_with_issue = review_request.serialized_ratings.find do |rating|
      rating[:issues].find { |issue| issue[:reference_id] == contested_rating_issue_reference_id }
    end

    rating_with_issue ||= { issues: [] }

    rating_with_issue[:issues].find { |issue| issue[:reference_id] == contested_rating_issue_reference_id }
  end

  def decision_or_promulgation_date
    return decision_date if nonrating?
    return contested_rating_issue.try(:promulgation_date) if rating?
  end

  # rubocop:disable Metrics/CyclomaticComplexity
  # rubocop:disable Metrics/PerceivedComplexity
  def check_for_eligible_previous_review!
    return unless eligible?
    return unless contested_issue

    if review_request.is_a?(HigherLevelReview)
      if contested_issue.source_review_type == "HigherLevelReview"
        self.ineligible_reason = :higher_level_review_to_higher_level_review
      end

      if contested_issue.source_review_type == "Appeal"
        self.ineligible_reason = :appeal_to_higher_level_review
      end
    end

    if review_request.is_a?(Appeal) && contested_issue.source_review_type == "Appeal"
      self.ineligible_reason = :appeal_to_appeal
    end

    self.ineligible_due_to_id = contested_issue.source_request_issue.id if ineligible_reason
  end
  # rubocop:enable Metrics/CyclomaticComplexity
  # rubocop:enable Metrics/PerceivedComplexity

  def check_for_before_ama!
    return unless eligible?
    return if is_unidentified
    return if ramp_claim_id

    if decision_or_promulgation_date && decision_or_promulgation_date < DecisionReview.ama_activation_date
      self.ineligible_reason = :before_ama
    end
  end

  def check_for_legacy_issue_not_withdrawn!
    return unless eligible?
    return unless vacols_id

    if !review_request.legacy_opt_in_approved
      self.ineligible_reason = :legacy_issue_not_withdrawn
    end
  end

  def check_for_legacy_appeal_not_eligible!
    return unless eligible?
    return unless vacols_id
    return unless review_request.serialized_legacy_appeals.any?

    unless vacols_issue.eligible_for_opt_in? && legacy_appeal_eligible_for_opt_in?
      self.ineligible_reason = :legacy_appeal_not_eligible
    end
  end

  def legacy_appeal_eligible_for_opt_in?
    vacols_issue.legacy_appeal.eligible_for_soc_opt_in?(review_request.receipt_date)
  end

  def check_for_active_request_issue_by_rating!
    return unless rating?

    add_duplicate_issue_error(
      self.class.find_active_by_contested_rating_issue_reference_id(contested_rating_issue_reference_id)
    )
  end

  def check_for_active_request_issue_by_decision_issue!
    return unless contested_decision_issue_id

    add_duplicate_issue_error(self.class.find_active_by_contested_decision_id(contested_decision_issue_id))
  end

  def add_duplicate_issue_error(existing_request_issue)
    if existing_request_issue && existing_request_issue.review_request != review_request
      self.ineligible_reason = :duplicate_of_rating_issue_in_active_review
      self.ineligible_due_to = existing_request_issue
    end
  end

  def check_for_active_request_issue!
    # skip checking if nonrating ineligiblity is already set
    return if ineligible_reason == :duplicate_of_nonrating_issue_in_active_review
    return unless eligible?

    check_for_active_request_issue_by_rating!
    check_for_active_request_issue_by_decision_issue!
  end

  def check_for_untimely!
    return unless eligible?
    return if untimely_exemption
    return if review_request&.is_a?(SupplementalClaim)

    if !review_request.timely_issue?(decision_or_promulgation_date)
      self.ineligible_reason = :untimely
    end
  end

  def appeal_active?
    review_request.tasks.where.not(status: Constants.TASK_STATUSES.completed).count > 0
  end

  def copy_review_request_to_decision_review
    self.decision_review = review_request
  end
end
