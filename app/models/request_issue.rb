class RequestIssue < ApplicationRecord
  belongs_to :review_request, polymorphic: true
  belongs_to :end_product_establishment
  has_many :decision_issues, foreign_key: "source_request_issue_id"
  has_many :remand_reasons
  has_many :duplicate_but_ineligible, class_name: "RequestIssue", foreign_key: "ineligible_due_to_id"
  belongs_to :ineligible_due_to, class_name: "RequestIssue", foreign_key: "ineligible_due_to_id"

  # enum is symbol, but validates requires a string
  validates :ineligible_reason, exclusion: { in: ["untimely"] }, if: proc { |reqi| reqi.untimely_exemption }

  enum ineligible_reason: {
    duplicate_of_issue_in_active_review: "duplicate_of_issue_in_active_review",
    untimely: "untimely",
    previous_higher_level_review: "previous_higher_level_review",
    before_ama: "before_ama"
  }

  UNIDENTIFIED_ISSUE_MSG = "UNIDENTIFIED ISSUE - Please click \"Edit in Caseflow\" button to fix".freeze

  class << self
    def rating
      where.not(rating_issue_reference_id: nil, rating_issue_profile_date: nil)
        .or(where(is_unidentified: true))
    end

    def nonrating
      where(rating_issue_reference_id: nil, rating_issue_profile_date: nil, is_unidentified: [nil, false])
        .where.not(issue_category: nil)
    end

    def unidentified
      where(rating_issue_reference_id: nil, rating_issue_profile_date: nil, is_unidentified: true)
    end

    def no_follow_up_issues
      where.not(id: select(:parent_request_issue_id).uniq)
    end

    # ramp_claim_id is set to the claim id of the RAMP EP when the contested rating issue is part of a ramp decision
    def from_intake_data(data)
      new(
        rating_issue_reference_id: data[:reference_id],
        rating_issue_profile_date: data[:profile_date],
        description: data[:decision_text],
        decision_date: data[:decision_date],
        issue_category: data[:issue_category],
        notes: data[:notes],
        is_unidentified: data[:is_unidentified],
        untimely_exemption: data[:untimely_exemption],
        untimely_exemption_notes: data[:untimely_exemption_notes],
        ramp_claim_id: data[:ramp_claim_id]
      ).validate_eligibility!
    end

    def find_active_by_reference_id(reference_id)
      request_issue = unscoped.find_by(rating_issue_reference_id: reference_id, removed_at: nil, ineligible_reason: nil)
      return unless request_issue && request_issue.status_active?
      request_issue
    end
  end

  def status_active?
    return appeal_active? if review_request.is_a?(Appeal)
    return false unless end_product_establishment
    end_product_establishment.status_active?
  end

  def rating?
    rating_issue_reference_id && rating_issue_profile_date
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

  def ui_hash
    {
      reference_id: rating_issue_reference_id,
      profile_date: rating_issue_profile_date,
      description: description,
      contention_text: contention_text,
      decision_date: decision_date,
      category: issue_category,
      notes: notes,
      is_unidentified: is_unidentified,
      ramp_claim_id: ramp_claim_id,
      ineligible_reason: ineligible_reason,
      title_of_active_review: duplicate_of_issue_in_active_review? ? ineligible_due_to.review_title : nil
    }
  end

  def validate_eligibility!
    check_for_active_request_issue!
    check_for_untimely!
    check_for_previous_higher_level_review!
    check_for_before_ama!
    self
  end

  def contested_rating_issue
    return unless review_request
    @contested_rating_issue ||= begin
      ui_hash = fetch_contested_rating_issue_ui_hash
      ui_hash ? RatingIssue.from_ui_hash(ui_hash) : nil
    end
  end

  def previous_request_issue
    return unless contested_rating_issue
    review_request.veteran.decision_issues.find_by(
      rating_issue_reference_id: contested_rating_issue.reference_id
    ).try(:source_request_issue)
  end

  private

  # RatingIssue is not in db so we pull hash from the serialized_ratings.
  def fetch_contested_rating_issue_ui_hash
    rating_with_issue = review_request.serialized_ratings.find do |rating|
      rating[:issues].find { |issue| issue[:reference_id] == rating_issue_reference_id }
    end || { issues: [] }

    rating_with_issue[:issues].find { |issue| issue[:reference_id] == rating_issue_reference_id }
  end

  def check_for_previous_higher_level_review!
    return unless rating?
    return unless eligible?
    check_for_previous_review!(:source_higher_level_review)
  end

  def check_for_previous_review!(review_type)
    reason = rating_issue_rationale_to_request_issue_reason(review_type)
    contested_rating_issue_ui_hash = fetch_contested_rating_issue_ui_hash

    if contested_rating_issue_ui_hash && contested_rating_issue_ui_hash[review_type].present?
      self.ineligible_reason = reason
      self.ineligible_due_to_id = contested_rating_issue_ui_hash[review_type]
    end
  end

  def decision_or_promulgation_date
    return decision_date if nonrating?
    return contested_rating_issue.try(:promulgation_date) if rating?
  end

  def check_for_before_ama!
    return unless eligible?
    return if is_unidentified
    return if ramp_claim_id

    if decision_or_promulgation_date && decision_or_promulgation_date < DecisionReview.ama_activation_date
      self.ineligible_reason = :before_ama
    end
  end

  def rating_issue_rationale_to_request_issue_reason(rationale)
    rationale.to_s.sub(/^source_/, "previous_").to_sym
  end

  def check_for_active_request_issue!
    return unless rating?
    return unless eligible?
    existing_request_issue = self.class.find_active_by_reference_id(rating_issue_reference_id)
    if existing_request_issue
      self.ineligible_reason = :duplicate_of_issue_in_active_review
      self.ineligible_due_to = existing_request_issue
    end
  end

  def check_for_untimely!
    return unless eligible?
    return if untimely_exemption
    return if review_request && review_request.is_a?(SupplementalClaim)

    if !review_request.timely_issue?(decision_or_promulgation_date)
      self.ineligible_reason = :untimely
    end
  end

  def appeal_active?
    review_request.tasks.where.not(status: Constants.TASK_STATUSES.completed).count > 0
  end
end
