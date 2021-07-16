# frozen_string_literal: true

##
# When a veteran submits their form for an Appeal, Supplemental Claim, or Higher Level Review, they list the prior
# decisions that they want to contest. These are intaken into Caseflow as request issues.  Request issues can also
# be generated when a decision gets remanded or vacated.

# rubocop:disable Metrics/ClassLength
class RequestIssue < CaseflowRecord
  include Asyncable
  include HasBusinessLine
  include DecisionSyncable
  include HasDecisionReviewUpdatedSince

  # how many days before we give up trying to sync decisions
  REQUIRES_PROCESSING_WINDOW_DAYS = 30

  # don't need to try as frequently as default 3 hours
  DEFAULT_REQUIRES_PROCESSING_RETRY_WINDOW_HOURS = 12

  belongs_to :decision_review, polymorphic: true
  belongs_to :end_product_establishment, dependent: :destroy
  has_many :request_decision_issues, dependent: :destroy
  has_many :decision_issues, through: :request_decision_issues
  has_many :remand_reasons, through: :decision_issues
  has_many :duplicate_but_ineligible, class_name: "RequestIssue", foreign_key: "ineligible_due_to_id"
  has_many :hearing_issue_notes
  has_one :legacy_issue_optin
  has_many :legacy_issues
  belongs_to :correction_request_issue, class_name: "RequestIssue", foreign_key: "corrected_by_request_issue_id"
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
    ineligible: "ineligible",
    no_decision: "no_decision",
    docket_switch: "docket_switch"
  }

  enum correction_type: {
    control: "control",
    local_quality_error: "local_quality_error",
    national_quality_error: "national_quality_error"
  }

  before_save :set_contested_rating_issue_profile_date
  before_save :close_if_ineligible!

  class ErrorCreatingDecisionIssue < StandardError
    def initialize(request_issue_id)
      super("Request Issue #{request_issue_id} cannot create decision issue " \
        "due to not having any matching rating issues or contentions")
    end
  end

  class NoAssociatedRating < StandardError
    def initialize(request_issue_id)
      super("Rating request Issue #{request_issue_id} cannot create decision issue " \
        "due to not having an associated rating")
    end
  end

  class NotYetSubmitted < StandardError; end
  class MissingContentionDisposition < StandardError; end
  class MissingDecisionDate < StandardError
    def initialize(request_issue_id)
      super("Request Issue #{request_issue_id} lacks a decision_date")
    end
  end

  UNIDENTIFIED_ISSUE_MSG = "UNIDENTIFIED ISSUE - Please click *Edit in Caseflow* button to fix"

  class << self
    # the umbrella term "rating" here is generalized to the type of EP it refers to.
    def rating
      rating_issue.or(rating_decision).or(unidentified)
    end

    def rating_issue
      where.not(contested_rating_issue_reference_id: nil)
    end

    def rating_decision
      where.not(contested_rating_decision_reference_id: nil)
    end

    def nonrating
      where(
        contested_rating_issue_reference_id: nil,
        contested_rating_decision_reference_id: nil,
        is_unidentified: [nil, false],
        verified_unidentified_issue: [nil, false]
      ).where.not(nonrating_issue_category: nil)
    end

    def decision_issue
      where.not(contested_decision_issue_id: nil)
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

    def withdrawn
      eligible.where(closed_status: :withdrawn)
    end

    def active_or_ineligible_or_withdrawn
      active_or_ineligible.or(withdrawn)
    end

    def active_or_decided_or_withdrawn
      active.or(decided).or(withdrawn).order(id: :asc)
    end

    def active_or_withdrawn
      active.or(withdrawn)
    end

    def unidentified
      where(
        contested_rating_issue_reference_id: nil,
        contested_rating_decision_reference_id: nil,
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
      contested_issue_present = attributes_look_like_contested_issue?(data)
      issue_text = (data[:is_unidentified] || data[:verified_unidentified_issue]) ? data[:decision_text] : nil

      {
        contested_rating_issue_reference_id: data[:rating_issue_reference_id],
        contested_rating_issue_diagnostic_code: data[:rating_issue_diagnostic_code],
        contested_rating_decision_reference_id: data[:rating_decision_reference_id],
        contested_issue_description: contested_issue_present ? data[:decision_text] : nil,
        nonrating_issue_description: data[:nonrating_issue_category] ? data[:decision_text] : nil,
        unidentified_issue_text: issue_text,
        decision_date: data[:decision_date],
        nonrating_issue_category: data[:nonrating_issue_category],
        benefit_type: data[:benefit_type],
        notes: data[:notes],
        is_unidentified: data[:is_unidentified],
        untimely_exemption: data[:untimely_exemption],
        untimely_exemption_notes: data[:untimely_exemption_notes],
        covid_timeliness_exempt: data[:untimely_exemption_covid],
        ramp_claim_id: data[:ramp_claim_id],
        vacols_id: data[:vacols_id],
        vacols_sequence_id: data[:vacols_sequence_id],
        contested_decision_issue_id: data[:contested_decision_issue_id],
        ineligible_reason: data[:ineligible_reason],
        ineligible_due_to_id: data[:ineligible_due_to_id],
        edited_description: data[:edited_description],
        correction_type: data[:correction_type],
        verified_unidentified_issue: data[:verified_unidentified_issue]
      }
    end
    # rubocop:enable Metrics/MethodLength

    def attributes_look_like_contested_issue?(data)
      data[:rating_issue_reference_id] ||
        data[:contested_decision_issue_id] ||
        data[:rating_decision_reference_id]
    end
  end

  delegate :veteran, to: :decision_review

  def create_for_claim_review!(request_issues_update = nil)
    return unless decision_review.is_a?(ClaimReview)

    update!(benefit_type: decision_review.benefit_type, veteran_participant_id: veteran.participant_id)

    epe = decision_review.end_product_establishment_for_issue(self, request_issues_update)
    update!(end_product_establishment: epe) if epe

    RequestIssueCorrectionCleaner.new(self).remove_dta_request_issue! if correction?
    handle_legacy_issues!
  end

  def end_product_code
    return if ineligible?
    return if decision_review.processed_in_caseflow?

    EndProductCodeSelector.new(self).call
  end

  def status_active?
    return appeal_active? if decision_review.is_a?(Appeal)
    return false unless end_product_establishment

    end_product_establishment.status_active?
  end

  def rating?
    !!associated_rating_issue? ||
      !!previous_rating_issue? ||
      !!associated_rating_decision? ||
      !!contested_decision_issue&.rating? ||
      verified_unidentified_issue
  end

  def nonrating?
    !rating? && !is_unidentified?
  end

  # Checks if the issue was corrected by another request issue
  def corrected?
    corrected_by_request_issue_id.present?
  end

  # Checks if the issue acts as a corection to another request issue
  def correction?
    !!correction_type
  end

  def decision_correction?
    contested_decision_issue&.decision_review == decision_review
  end

  def associated_rating_issue?
    contested_rating_issue_reference_id
  end

  def associated_rating_decision?
    contested_rating_decision_reference_id
  end

  def open?
    !closed?
  end

  def closed?
    !!closed_at
  end

  def description
    return edited_description if edited_description.present?
    return contested_issue_description if contested_issue_description
    return "#{nonrating_issue_category} - #{nonrating_issue_description}" if nonrating?
    return unidentified_issue_text if is_unidentified? || verified_unidentified_issue
  end

  # If the request issue is unidentified, we want to prompt the VBMS/SHARE user to correct the issue.
  # For that reason we use a special prompt message instead of the issue text.
  def contention_text
    return UNIDENTIFIED_ISSUE_MSG if is_unidentified? && !verified_unidentified_issue

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

  def contention_type
    return Constants.CONTENTION_TYPES.higher_level_review if decision_review.is_a?(HigherLevelReview)
    return Constants.CONTENTION_TYPES.supplemental_claim if decision_review.is_a?(SupplementalClaim)

    Constants.CONTENTION_TYPES.default
  end

  # If contentions get a DTA disposition, send their IDs when creating the new DTA contentions
  def original_contention_ids
    return unless contested_decision_issue&.remanded?

    contested_decision_issue.request_issues.map(&:contention_reference_id)
  end

  def withdrawal_date
    closed_at if withdrawn?
  end

  def serialize
    Intake::RequestIssueSerializer.new(self).serializable_hash[:data][:attributes]
  end

  def approx_decision_date_of_issue_being_contested
    if contested_issue
      contested_issue.approx_decision_date
    elsif decision_date
      decision_date
    else
      return if is_unidentified

      fail Caseflow::Error::MissingDecisionDate, request_issue_id: id
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
    return unless contested_rating_issue_reference_id

    @contested_rating_issue ||= begin
      contested_rating_issue_ui_hash = fetch_contested_rating_issue_ui_hash
      contested_rating_issue_ui_hash ? RatingIssue.deserialize(contested_rating_issue_ui_hash) : nil
    end
  end

  def contested_rating_decision
    return unless contested_rating_decision_reference_id

    @contested_rating_decision ||= begin
      contested_rating_decision_ui_hash = fetch_contested_rating_decision_ui_hash
      contested_rating_decision_ui_hash ? RatingDecision.deserialize(contested_rating_decision_ui_hash) : nil
    end
  end

  def contested_benefit_type
    return contested_rating_issue&.benefit_type if associated_rating_issue?
    return :compensation if associated_rating_decision?

    guess_benefit_type
  end

  def guess_benefit_type
    return contested_decision_issue.benefit_type if contested_decision_issue
    return "unidentified" if is_unidentified
    return "ineligible" unless eligible?

    "unknown"
  end

  def previous_request_issue
    contested_decision_issue&.request_issues&.first
  end

  def sync_decision_issues!
    return if processed?

    fail NotYetSubmitted unless submitted_and_ready?

    clear_error!
    attempted!

    # pre-fetch the internal veteran record before we start the transaction
    # to avoid a slow BGS call causing the transaction to timeout
    end_product_establishment.veteran

    transaction do
      return unless create_decision_issues

      end_product_establishment.on_decision_issue_sync_processed(self)
      clear_error!
      close_decided_issue!
      processed!
    end
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
    # No need to update if already closed unless switching from ineligible to removed
    return unless closed_at.nil? || (status.to_sym == :removed && ineligible?)

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
    return unless end_product_establishment&.reload&.status_cancelled?

    close!(status: :end_product_canceled) do
      legacy_issue_optin&.flag_for_rollback!
    end
  end

  def withdraw!(withdrawal_date)
    close!(status: :withdrawn, closed_at_value: withdrawal_date.to_datetime)
  end

  def save_edited_contention_text!(new_description)
    update!(edited_description: new_description, contention_updated_at: nil)
  end

  def remove!
    close!(status: :removed) do
      legacy_issue_optin&.flag_for_rollback!

      # If the decision issue is not associated with any other request issue, also delete
      decision_issues.each(&:soft_delete_on_removed_request_issue)
      # Removing a request issue also deletes the associated request_decision_issue
      request_decision_issues.update_all(deleted_at: Time.zone.now)
      canceled! if submitted_not_processed?
    end
  end

  def move_stream!(new_appeal_stream:, closed_status:)
    return unless decision_review.is_a?(Appeal)

    transaction do
      new_issue_attributes = attributes.reject { |attr| %w[id created_at updated_at].include?(attr) }
      new_issue_attributes["decision_review_id"] = new_appeal_stream.id
      self.class.create!(new_issue_attributes)
      close!(status: closed_status)
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

  def create_vacated_decision_issue!
    decision_issues.find_or_create_by!(
      decision_review: decision_review,
      decision_review_type: decision_review_type,
      disposition: "vacated",
      description: "The decision: #{description} has been vacated.",
      caseflow_decision_date: Time.zone.today,
      benefit_type: benefit_type,
      participant_id: decision_review.veteran.participant_id
    )
  end

  def requires_record_request_task?
    eligible? && !is_unidentified && !benefit_type_requires_payee_code?
  end

  def decision_or_promulgation_date
    return contested_rating_issue&.promulgation_date if associated_rating_issue?

    return contested_rating_decision&.decision_date&.to_date if associated_rating_decision?

    decision_date
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

  def contention_disposition
    @contention_disposition ||= end_product_establishment.fetch_dispositions_from_vbms.find do |disposition|
      disposition.contention_id.to_i == contention_reference_id
    end
  end

  def contention_missing?
    return false unless contention_reference_id

    !contention
  end

  def contention
    end_product_establishment.contention_for_object(self)
  end

  def bgs_contention
    end_product_establishment&.bgs_contention_for_object(self)
  end

  def exam_requested?
    bgs_contention&.exam_requested?
  end

  def editable?
    !contention_connected_to_rating?
  end

  def remanded?
    # if this request issue is a correction for a decision issue from a remand supplemental claim,
    # consider it a remanded request issue regardless of the decision issue disposition
    return contested_decision_issue&.decision_review.try(:decision_review_remanded?) if decision_correction?

    contested_decision_issue&.remanded?
  end

  def remand_type
    return unless remanded?

    # if this request issue is a correction for a decision issue, use the original issue's remand type
    # instead of the contested decision issue's disposition
    return previous_request_issue&.remand_type if decision_correction?

    if contested_decision_issue.disposition == DecisionIssue::DIFFERENCE_OF_OPINION
      "difference_of_opinion"
    else
      "duty_to_assist"
    end
  end

  def title_of_active_review
    duplicate_of_issue_in_active_review? ? ineligible_due_to.review_title : nil
  end

  def handle_legacy_issues!
    create_legacy_issue!
    create_legacy_issue_optin!
  end

  def timely_issue?(receipt_date)
    return true unless receipt_date && decision_date
    return false if receipt_date < decision_date
    return true if untimely_exemption

    decision_date >= (receipt_date - Rating::ONE_YEAR_PLUS_DAYS)
  end

  private

  def create_legacy_issue!
    return unless vacols_id && vacols_sequence_id

    legacy_issues.create!(
      vacols_id: vacols_id,
      vacols_sequence_id: vacols_sequence_id
    )
  end

  def create_legacy_issue_optin!
    return unless legacy_issue_opted_in?

    LegacyIssueOptin.create!(
      request_issue: self,
      original_disposition_code: vacols_issue.disposition_id,
      original_disposition_date: vacols_issue.disposition_date,
      legacy_issue: legacy_issues.first,
      original_legacy_appeal_decision_date: vacols_issue&.legacy_appeal&.decision_date,
      original_legacy_appeal_disposition_code: vacols_issue&.legacy_appeal&.case_record&.bfdc,
      folder_decision_date: vacols_issue&.legacy_appeal&.case_record&.folder&.tidcls
    )
  end

  # When a request issue contention is connected to a new rating issue, it can no longer be removed in VBMS.
  def contention_connected_to_rating?
    if contention_reference_id && end_product_establishment&.associated_rating
      return matching_rating_issues.any?
    end

    false
  rescue Rating::NilRatingProfileListError
    false
  end

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

  def duplicate_of_issue_in_active_review?
    duplicate_of_rating_issue_in_active_review? || duplicate_of_nonrating_issue_in_active_review?
  end

  def create_decision_issues
    if rating?
      fail NoAssociatedRating, id unless end_product_establishment.associated_rating

      create_decision_issues_from_rating
    end

    # We expect all rating request issues on an EP to get an associated rating created when they're decided
    # Only non-rating issues should have decision issues created from dispositions
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
        rating_profile_date: end_product_establishment_associated_rating_profile_date,
        rating_promulgation_date: end_product_establishment_associated_rating_promulgation_date,
        decision_review: decision_review,
        benefit_type: benefit_type,
        end_product_last_action_date: end_product_establishment.last_action_date
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
    fail MissingContentionDisposition unless contention_disposition

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
      rating_promulgation_date: rating_issue.promulgation_date,
      decision_text: rating_issue.decision_text,
      rating_profile_date: rating_issue.profile_date,
      decision_review: decision_review,
      benefit_type: rating_issue.benefit_type,
      subject_text: rating_issue.subject_text,
      percent_number: rating_issue.percent_number,
      end_product_last_action_date: end_product_establishment.last_action_date
    )
  end

  # RatingIssue and RatingDecision are not in db so we pull hash from the serialized_ratings.
  # We must unwind the nested hash tree to find the child.
  def fetch_contested_rating_child_ui_hash(haystack:, needle:, needle_value:)
    return unless decision_review&.serialized_ratings

    rating_child = nil

    decision_review.serialized_ratings.each do |rating|
      rating_child = rating[haystack].find { |child| child[needle] == needle_value }
      break if rating_child
    end

    rating_child
  end

  def fetch_contested_rating_issue_ui_hash
    fetch_contested_rating_child_ui_hash(
      haystack: :issues,
      needle: :reference_id,
      needle_value: contested_rating_issue_reference_id
    )
  end

  def fetch_contested_rating_decision_ui_hash
    fetch_contested_rating_child_ui_hash(
      haystack: :decisions,
      needle: :disability_id,
      needle_value: contested_rating_decision_reference_id
    )
  end

  # rubocop:disable Metrics/CyclomaticComplexity
  # rubocop:disable Metrics/PerceivedComplexity
  def check_for_eligible_previous_review!
    return unless eligible?
    return unless contested_issue
    return if decision_correction?

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

    if decision_or_promulgation_date && decision_or_promulgation_date < decision_review.ama_activation_date
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

    unless issue_eligible_for_opt_in? && legacy_appeal_eligible_for_opt_in?
      self.ineligible_reason = :legacy_appeal_not_eligible
    end
  end

  def issue_eligible_for_opt_in?
    vacols_issue.eligible_for_opt_in?(covid_flag: covid_timeliness_exempt)
  end

  def legacy_appeal_eligible_for_opt_in?
    vacols_issue.legacy_appeal.eligible_for_opt_in?(
      receipt_date: decision_review.receipt_date, covid_flag: covid_timeliness_exempt
    )
  end

  def check_for_active_request_issue_by_rating!
    return unless associated_rating_issue?

    add_duplicate_issue_error(
      RequestIssue.active.find_by(
        contested_rating_issue_reference_id: contested_rating_issue_reference_id,
        correction_type: correction_type
      )
    )
  end

  # A decision can be corrected via a 930 simultaneously with being contested by a veteran
  def check_for_active_request_issue_by_decision_issue!
    return unless contested_decision_issue_id
    return if decision_correction?

    add_duplicate_issue_error(
      RequestIssue.active.find_by(contested_decision_issue_id: contested_decision_issue_id,
                                  correction_type: correction_type)
    )
  end

  def add_duplicate_issue_error(existing_request_issue)
    if existing_request_issue && existing_request_issue.decision_review != decision_review
      self.ineligible_reason = :duplicate_of_rating_issue_in_active_review
      self.ineligible_due_to = existing_request_issue
    end
  end

  def check_for_active_request_issue!
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
    decision_review.tasks.open.any?
  end
end
# rubocop:enable Metrics/ClassLength
