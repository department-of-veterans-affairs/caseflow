# frozen_string_literal: true

# rubocop:disable Metrics/ClassLength
class RequestIssue < ApplicationRecord
  include Asyncable
  include HasBusinessLine

  # how many days before we give up trying to sync decisions
  REQUIRES_PROCESSING_WINDOW_DAYS = 14

  # don't need to try as frequently as default 3 hours
  DEFAULT_REQUIRES_PROCESSING_RETRY_WINDOW_HOURS = 12

  belongs_to :decision_review, polymorphic: true
  belongs_to :end_product_establishment
  has_many :request_decision_issues
  has_many :decision_issues, through: :request_decision_issues
  has_many :remand_reasons, through: :decision_issues
  has_many :duplicate_but_ineligible, class_name: "RequestIssue", foreign_key: "ineligible_due_to_id"
  has_many :hearing_issue_notes
  has_one :legacy_issue_optin
  belongs_to :ineligible_due_to, class_name: "RequestIssue", foreign_key: "ineligible_due_to_id"
  belongs_to :contested_decision_issue, class_name: "DecisionIssue"

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

  enum closed_status: {
    decided: "decided",
    removed: "removed",
    end_product_canceled: "end_product_canceled",
    withdrawn: "withdrawn",
    dismissed_death: "dismissed_death",
    dismissed_matter_of_law: "dismissed_matter_of_law",
    stayed: "stayed",
    ineligible: "ineligible"
  }

  before_save :set_contested_rating_issue_profile_date
  before_save :close_if_ineligible!

  class ErrorCreatingDecisionIssue < StandardError
    def initialize(request_issue_id)
      super("Request Issue #{request_issue_id} cannot create decision issue " \
        "due to not having any matching rating issues or contentions")
    end
  end

  class NotYetSubmitted < StandardError; end
  class MissingDecisionDate < StandardError
    def initialize(request_issue_id)
      super("Request Issue #{request_issue_id} lacks a decision_date")
    end
  end

  UNIDENTIFIED_ISSUE_MSG = "UNIDENTIFIED ISSUE - Please click \"Edit in Caseflow\" button to fix"

  END_PRODUCT_CODES = {
    original: {
      compensation: {
        supplemental_claim: {
          rating: "040SCR",
          nonrating: "040SCNR"
        },
        higher_level_review: {
          rating: "030HLRR",
          nonrating: "030HLRNR"
        }
      },
      pension: {
        supplemental_claim: {
          rating: "040SCRPMC",
          nonrating: "040SCNRPMC"
        },
        higher_level_review: {
          rating: "030HLRRPMC",
          nonrating: "030HLRNRPMC"
        }
      }
    },
    dta: {
      compensation: {
        appeal: {
          rating: "040BDER",
          nonrating: "040BDENR"
        },
        claim_review: {
          rating: "040HDER",
          nonrating: "040HDENR"
        }
      },
      pension: {
        appeal: {
          rating: "040BDERPMC",
          nonrating: "040BDENRPMC"
        },
        claim_review: {
          rating: "040HDERPMC",
          nonrating: "040HDENRPMC"
        }
      }
    }
  }.freeze

  class << self
    def last_submitted_at_column
      :decision_sync_last_submitted_at
    end

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

    def eligible
      where(ineligible_reason: nil)
    end

    # "Active" issues are issues that need decisions.
    # They show up as contentions in VBMS and issues in Caseflow Queue.
    def active
      eligible.where(closed_at: nil)
    end

    def active_or_ineligible
      active.or(ineligible)
    end

    def active_or_decided
      active.or(decided).order(id: :asc)
    end

    def unidentified
      where(
        contested_rating_issue_reference_id: nil,
        is_unidentified: true
      )
    end

    # ramp_claim_id is set to the claim id of the RAMP EP when the contested rating issue is part of a ramp decision
    def from_intake_data(data, decision_review: nil)
      attrs = attributes_from_intake_data(data)
      attrs = attrs.merge(decision_review: decision_review) if decision_review

      new(attrs).tap(&:validate_eligibility!)
    end

    private

    # rubocop:disable Metrics/MethodLength
    def attributes_from_intake_data(data)
      contested_issue_present = data[:rating_issue_reference_id] || data[:contested_decision_issue_id]

      {
        contested_rating_issue_reference_id: data[:rating_issue_reference_id],
        contested_rating_issue_diagnostic_code: data[:rating_issue_diagnostic_code],
        contested_issue_description: contested_issue_present ? data[:decision_text] : nil,
        nonrating_issue_description: data[:issue_category] ? data[:decision_text] : nil,
        unidentified_issue_text: data[:is_unidentified] ? data[:decision_text] : nil,
        decision_date: data[:decision_date],
        issue_category: data[:issue_category],
        benefit_type: data[:benefit_type],
        notes: data[:notes],
        is_unidentified: data[:is_unidentified],
        untimely_exemption: data[:untimely_exemption],
        untimely_exemption_notes: data[:untimely_exemption_notes],
        ramp_claim_id: data[:ramp_claim_id],
        vacols_id: data[:vacols_id],
        vacols_sequence_id: data[:vacols_sequence_id],
        contested_decision_issue_id: data[:contested_decision_issue_id],
        ineligible_reason: data[:ineligible_reason],
        ineligible_due_to_id: data[:ineligible_due_to_id]
      }
    end
    # rubocop:enable Metrics/MethodLength
  end

  delegate :veteran, to: :decision_review

  def end_product_code
    remanded? ? dta_end_product_code : original_end_product_code
  end

  def status_active?
    return appeal_active? if decision_review.is_a?(Appeal)
    return false unless end_product_establishment

    end_product_establishment.status_active?
  end

  def rating?
    !!associated_rating_issue? || previous_rating_issue?
  end

  def nonrating?
    !rating? && !is_unidentified?
  end

  def associated_rating_issue?
    contested_rating_issue_reference_id
  end

  def open?
    !closed?
  end

  def closed?
    !!closed_at
  end

  def description
    return contested_issue_description if contested_issue_description
    return "#{issue_category} - #{nonrating_issue_description}" if nonrating?
    return unidentified_issue_text if is_unidentified?
  end

  # If the request issue is unidentified, we want to prompt the VBMS/SHARE user to correct the issue.
  # For that reason we use a special prompt message instead of the issue text.
  def contention_text
    return UNIDENTIFIED_ISSUE_MSG if is_unidentified?

    Contention.new(description).text
  end

  def review_title
    decision_review_type.try(:constantize).try(:review_title)
  end

  def eligible?
    ineligible_reason.nil?
  end

  def special_issues
    specials = []
    specials << { code: "ASSOI", narrative: Constants.VACOLS_DISPOSITIONS_BY_ID.O } if legacy_issue_opted_in?
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
      approx_decision_date: approx_decision_date_of_issue_being_contested,
      category: issue_category,
      notes: notes,
      is_unidentified: is_unidentified,
      ramp_claim_id: ramp_claim_id,
      vacols_id: vacols_id,
      vacols_sequence_id: vacols_sequence_id,
      vacols_issue: vacols_issue.try(:intake_attributes),
      ineligible_reason: ineligible_reason,
      ineligible_due_to_id: ineligible_due_to_id,
      decision_review_title: review_title,
      title_of_active_review: title_of_active_review,
      contested_decision_issue_id: contested_decision_issue_id
    }
  end

  def approx_decision_date_of_issue_being_contested
    return if is_unidentified

    if contested_issue
      contested_issue.approx_decision_date
    elsif decision_date
      decision_date
    else
      # in theory we should never get here
      fail MissingDecisionDate, id
    end
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
    return unless decision_review
    return unless contested_rating_issue_reference_id

    @contested_rating_issue ||= begin
      contested_rating_issue_ui_hash = fetch_contested_rating_issue_ui_hash
      contested_rating_issue_ui_hash ? RatingIssue.deserialize(contested_rating_issue_ui_hash) : nil
    end
  end

  def contested_benefit_type
    contested_rating_issue&.benefit_type
  end

  def guess_benefit_type
    return "unidentified" if is_unidentified

    "unknown"
  end

  def previous_request_issue
    contested_decision_issue&.request_issues&.first
  end

  def sync_decision_issues!
    return if processed?

    fail NotYetSubmitted unless submitted_and_ready?

    attempted!

    transaction do
      return unless create_decision_issues

      end_product_establishment.on_decision_issue_sync_processed(self)
      clear_error!
      close_decided_issue!
      processed!
    end
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

  def close!(status:, closed_at_value: Time.zone.now)
    return unless closed_at.nil?

    transaction do
      update!(closed_at: closed_at_value, closed_status: status)
      yield if block_given?
    end
  end

  def close_if_ineligible!
    close!(status: :ineligible) if ineligible_reason?
  end

  def close_decided_issue!
    return unless decision_issues.any?

    close!(status: :decided)
  end

  def close_after_end_product_canceled!
    return unless end_product_establishment&.reload&.status_canceled?

    close!(status: :end_product_canceled) do
      legacy_issue_optin&.flag_for_rollback!
    end
  end

  def withdraw!(withdrawal_date)
    close!(status: :withdrawn, closed_at_value: withdrawal_date.to_datetime)
  end

  def remove!
    close!(status: :removed) do
      legacy_issue_optin&.flag_for_rollback!

      # If the decision issue is not associated with any other request issue, also delete
      decision_issues.each(&:soft_delete_on_removed_request_issue)
      # Removing a request issue also deletes the associated request_decision_issue
      request_decision_issues.update_all(deleted_at: Time.zone.now)
    end
  end

  def create_decision_issue_from_params(decision_issue_param)
    decision_issues.create!(
      participant_id: decision_review.veteran.participant_id,
      disposition: decision_issue_param[:disposition],
      description: decision_issue_param[:description],
      decision_review: decision_review,
      benefit_type: benefit_type,
      caseflow_decision_date: decision_issue_param[:decision_date]
    )
  end

  def requires_record_request_task?
    !benefit_type_requires_payee_code?
  end

  def decision_or_promulgation_date
    return decision_date if nonrating?
    return contested_rating_issue.try(:promulgation_date) if rating?
  end

  def diagnostic_code
    contested_rating_issue_diagnostic_code
  end

  def api_status_active?
    return decision_review.active_status? if decision_review.is_a?(ClaimReview)
    return true if decision_review.is_a?(Appeal)
  end

  def api_status_last_action
    # this will be nil
    # may need to be updated if an issue is withdrawn
  end

  def api_status_last_action_date
    # this will be nil
    # may need to be updated if an issue is withdrawn
  end

  def api_status_description
    description = fetch_diagnostic_code_status_description(diagnostic_code)
    return description if description

    "#{benefit_type.capitalize} issue"
  end

  def api_aoj_from_benefit_type
    case benefit_type
    when "compensation", "pension", "fiduciary", "insurance", "education", "voc_rehab", "loan_guaranty"
      "vba"
    else
      benefit_type
    end
  end

  def limited_poa_code
    return unless limited_poa

    limited_poa[:limited_poa_code]
  end

  def limited_poa_access
    return unless limited_poa

    limited_poa[:limited_poa_access] == "Y"
  end

  private

  def limited_poa
    previous_request_issue&.end_product_establishment&.limited_poa_on_established_claim
  end

  # If a request issue gets a DTA error, the follow up request issue may not have a rating_issue_reference_id
  # But the request issue should still be added to a rating End Product
  def previous_rating_issue?
    previous_request_issue&.rating?
  end

  def fetch_diagnostic_code_status_description(diagnostic_code)
    if diagnostic_code && Constants::DIAGNOSTIC_CODE_DESCRIPTIONS[diagnostic_code]
      description = Constants::DIAGNOSTIC_CODE_DESCRIPTIONS[diagnostic_code]["status_description"]
      description[0] = description[0].upcase
      description
    end
  end

  # The contested_rating_issue_profile_date is used as an identifier to retrieve the
  # appropriate rating. It needs to be saved in the same format and time zone that it
  # was fetched from BGS in order for it to work as an identifier.
  #
  # In order to prevent browser/API automatic time zone changes from altering it, we
  # re-retrieve the value from the cache and save it to the DB as a string. Yikes.
  def set_contested_rating_issue_profile_date
    self.contested_rating_issue_profile_date ||= contested_rating_issue&.profile_date
  end

  # TODO: extend this to cover nonrating request issues
  def build_contested_issue
    return unless decision_review

    if contested_decision_issue
      ContestableIssue.from_decision_issue(contested_decision_issue, decision_review)
    elsif contested_rating_issue
      ContestableIssue.from_rating_issue(contested_rating_issue, decision_review)
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
      return false unless end_product_establishment.associated_rating

      create_decision_issues_from_rating
    end

    create_decision_issue_from_disposition if decision_issues.empty?

    fail ErrorCreatingDecisionIssue, id if decision_issues.empty?

    true
  end

  def matching_rating_issues
    @matching_rating_issues ||= end_product_establishment.associated_rating.issues.select do |rating_issue|
      rating_issue.decides_contention?(contention_reference_id: contention_reference_id)
    end
  end

  def create_decision_issue_from_disposition
    if contention_disposition
      decision_issues.create!(
        participant_id: decision_review.veteran.participant_id,
        disposition: contention_disposition.disposition,
        description: "#{contention_disposition.disposition}: #{description}",
        profile_date: end_product_establishment_associated_rating_profile_date,
        promulgation_date: end_product_establishment_associated_rating_promulgation_date,
        decision_review: decision_review,
        benefit_type: benefit_type,
        end_product_last_action_date: end_product_establishment.result.last_action_date
      )
    end
  end

  def end_product_establishment_associated_rating_profile_date
    return unless rating?

    end_product_establishment.associated_rating&.profile_date
  end

  def end_product_establishment_associated_rating_promulgation_date
    return unless rating?

    end_product_establishment.associated_rating&.promulgation_date
  end

  def contention_disposition
    @contention_disposition ||= end_product_establishment.fetch_dispositions_from_vbms.find do |disposition|
      disposition.contention_id.to_i == contention_reference_id
    end
  end

  def create_decision_issues_from_rating
    matching_rating_issues.each do |rating_issue|
      transaction { decision_issues << find_or_create_decision_issue_from_rating_issue(rating_issue) }
    end
  end

  # One rating issue can be made as a decision for many request issues. However, we trust the disposition of the
  # request issue contention OVER the decision issue disposition (since it's a "supplementary decision").
  #
  # This creates a scenario where multiple request issues can have different dispositions but be decided by the
  # same rating issue. In this scenario, we will create 2 decision issues with the same rating_issue_reference_id
  # but different dispositions.
  #
  # However, if the dispositions for any of these request issues match, there is no need to create multiple decision
  # issues. They can instead be mapped to the same decision issue.
  def find_or_create_decision_issue_from_rating_issue(rating_issue)
    preexisting_decision_issue = DecisionIssue.find_by(
      participant_id: rating_issue.participant_id,
      rating_issue_reference_id: rating_issue.reference_id,
      disposition: contention_disposition.disposition
    )

    return preexisting_decision_issue if preexisting_decision_issue

    DecisionIssue.create!(
      rating_issue_reference_id: rating_issue.reference_id,
      disposition: contention_disposition.disposition,
      participant_id: rating_issue.participant_id,
      promulgation_date: rating_issue.promulgation_date,
      decision_text: rating_issue.decision_text,
      profile_date: rating_issue.profile_date,
      decision_review: decision_review,
      benefit_type: rating_issue.benefit_type,
      end_product_last_action_date: end_product_establishment.result.last_action_date
    )
  end

  # RatingIssue is not in db so we pull hash from the serialized_ratings.
  # TODO: performance could be improved by using the profile date by loading the specific rating
  def fetch_contested_rating_issue_ui_hash
    return unless decision_review.serialized_ratings

    rating_with_issue = decision_review.serialized_ratings.find do |rating|
      rating[:issues].find { |issue| issue[:reference_id] == contested_rating_issue_reference_id }
    end

    rating_with_issue ||= { issues: [] }

    rating_with_issue[:issues].find { |issue| issue[:reference_id] == contested_rating_issue_reference_id }
  end

  # rubocop:disable Metrics/CyclomaticComplexity
  # rubocop:disable Metrics/PerceivedComplexity
  def check_for_eligible_previous_review!
    return unless eligible?
    return unless contested_issue

    if decision_review.is_a?(HigherLevelReview)
      if contested_issue.source_review_type == "HigherLevelReview"
        self.ineligible_reason = :higher_level_review_to_higher_level_review
      end

      if contested_issue.source_review_type == "Appeal"
        self.ineligible_reason = :appeal_to_higher_level_review
      end
    end

    if decision_review.is_a?(Appeal) && contested_issue.source_review_type == "Appeal"
      self.ineligible_reason = :appeal_to_appeal
    end

    self.ineligible_due_to_id = contested_issue.source_request_issues.first&.id if ineligible_reason
  end
  # rubocop:enable Metrics/CyclomaticComplexity
  # rubocop:enable Metrics/PerceivedComplexity

  def check_for_before_ama!
    return unless eligible? && should_check_for_before_ama?

    if decision_or_promulgation_date && decision_or_promulgation_date < DecisionReview.ama_activation_date
      self.ineligible_reason = :before_ama
    end
  end

  def should_check_for_before_ama?
    !is_unidentified && !ramp_claim_id && !vacols_id && !decision_review&.is_a?(SupplementalClaim)
  end

  def check_for_legacy_issue_not_withdrawn!
    return unless eligible?
    return unless vacols_id

    if !decision_review.legacy_opt_in_approved
      self.ineligible_reason = :legacy_issue_not_withdrawn
    end
  end

  def check_for_legacy_appeal_not_eligible!
    return unless eligible?
    return unless vacols_id
    return unless decision_review.serialized_legacy_appeals.any?

    unless vacols_issue.eligible_for_opt_in? && legacy_appeal_eligible_for_opt_in?
      self.ineligible_reason = :legacy_appeal_not_eligible
    end
  end

  def legacy_appeal_eligible_for_opt_in?
    vacols_issue.legacy_appeal.eligible_for_soc_opt_in?(decision_review.receipt_date)
  end

  def check_for_active_request_issue_by_rating!
    return unless rating?

    add_duplicate_issue_error(
      RequestIssue.active.find_by(contested_rating_issue_reference_id: contested_rating_issue_reference_id)
    )
  end

  def check_for_active_request_issue_by_decision_issue!
    return unless contested_decision_issue_id

    add_duplicate_issue_error(
      RequestIssue.active.find_by(contested_decision_issue_id: contested_decision_issue_id)
    )
  end

  def original_end_product_code
    choose_original_end_product_code(END_PRODUCT_CODES[:original][temp_find_benefit_type.to_sym])
  end

  # TODO: use request issue benefit type once it's populated for request issues on build
  def temp_find_benefit_type
    benefit_type || decision_review.benefit_type || contested_benefit_type
  end

  def choose_original_end_product_code(end_product_codes)
    end_product_codes[decision_review_type.underscore.to_sym][(rating? || is_unidentified?) ? :rating : :nonrating]
  end

  def dta_end_product_code
    choose_dta_end_product_code(END_PRODUCT_CODES[:dta][temp_find_benefit_type.to_sym])
  end

  def choose_dta_end_product_code(end_product_codes)
    if decision_review.decision_review_remanded.is_a?(Appeal)
      end_product_codes[:appeal][rating? ? :rating : :nonrating]
    else
      end_product_codes[:claim_review][rating? ? :rating : :nonrating]
    end
  end

  def remanded?
    decision_review.try(:decision_review_remanded?)
  end

  def add_duplicate_issue_error(existing_request_issue)
    if existing_request_issue && existing_request_issue.decision_review != decision_review
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
    return if vacols_id
    return if decision_review&.is_a?(SupplementalClaim)

    if !decision_review.timely_issue?(decision_or_promulgation_date)
      self.ineligible_reason = :untimely
    end
  end

  def appeal_active?
    decision_review.tasks.active.any?
  end
end
# rubocop:enable Metrics/ClassLength
