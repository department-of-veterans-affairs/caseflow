class DecisionReview < ApplicationRecord
  include CachedAttributes

  validate :validate_receipt_date

  self.abstract_class = true

  attr_reader :saving_review

  has_many :request_issues, as: :review_request
  has_many :claimants, as: :review_request

  before_destroy :remove_issues!

  cache_attribute :cached_serialized_ratings, cache_key: :ratings_cache_key, expires_in: 1.day do
    ratings_with_issues.map(&:serialize)
  end

  def self.ama_activation_date
    if FeatureToggle.enabled?(:use_ama_activation_date)
      Constants::DATES["AMA_ACTIVATION"].to_date
    else
      Constants::DATES["AMA_ACTIVATION_TEST"].to_date
    end
  end

  def self.review_title
    to_s.underscore.titleize
  end

  def serialized_ratings
    return unless receipt_date

    cached_serialized_ratings.each do |rating|
      rating[:issues].each do |rating_issue_hash|
        rating_issue_hash[:timely] = timely_issue?(Date.parse(rating_issue_hash[:promulgation_date].to_s))
        # always re-compute flags that depend on data in our db
        rating_issue_hash.merge!(RatingIssue.deserialize(rating_issue_hash).serialize)
      end
    end
  end

  def ui_hash
    {
      veteran: {
        name: veteran && veteran.name.formatted(:readable_short),
        fileNumber: veteran_file_number,
        formName: veteran && veteran.name.formatted(:form)
      },
      relationships: veteran && veteran.relationships,
      claimant: claimant_participant_id,
      veteranIsNotClaimant: veteran_is_not_claimant,
      receiptDate: receipt_date.to_formatted_s(:json_date),
      legacyOptInApproved: legacy_opt_in_approved,
      legacyAppeals: serialized_legacy_appeals,
      ratings: serialized_ratings,
      requestIssues: request_issues.map(&:ui_hash)
    }
  end

  def timely_issue?(decision_date)
    return true unless receipt_date && decision_date
    decision_date >= (receipt_date - Rating::ONE_YEAR_PLUS_DAYS)
  end

  def start_review!
    @saving_review = true
  end

  def create_claimants!(participant_id:, payee_code:)
    remove_claimants!
    claimants.create_from_intake_data!(participant_id: participant_id, payee_code: payee_code)
  end

  def remove_claimants!
    claimants.destroy_all unless claimants.empty?
  end

  def claimant_participant_id
    return nil if claimants.empty?
    claimants.first.participant_id
  end

  def claimant_not_veteran
    # This is being replaced by veteran_is_not_claimant, but keeping it temporarily
    # until data is backfilled
    claimant_participant_id && claimant_participant_id != veteran.participant_id
  end

  def payee_code
    return nil if claimants.empty?
    claimants.first.payee_code
  end

  def veteran
    @veteran ||= Veteran.find_or_create_by_file_number(veteran_file_number)
  end

  def remove_issues!
    request_issues.destroy_all unless request_issues.empty?
  end

  def mark_rating_request_issues_to_reassociate!
    request_issues.select(&:rating?).each { |ri| ri.update!(rating_issue_associated_at: nil) }
  end

  def serialized_legacy_appeals
    return [] unless FeatureToggle.enabled?(:intake_legacy_opt_in, user: RequestStore.store[:current_user])
    return [] unless available_legacy_appeals

    available_legacy_appeals.map do |legacy_appeal|
      {
        date: legacy_appeal.nod_date,
        eligible_for_soc_opt_in: legacy_appeal.eligible_for_soc_opt_in?,
        issues: legacy_appeal.issues.map(&:intake_attributes)
      }
    end
  end

  private

  def available_legacy_appeals
    # If a Veteran does not opt-in to withdraw legacy appeals, do not show inactive appeals
    legacy_opt_in_approved ? matchable_legacy_appeals : active_legacy_appeals
  end

  def matchable_legacy_appeals
    @matchable_legacy_appeals ||= LegacyAppeal
      .fetch_appeals_by_file_number(veteran_file_number)
      .select(&:matchable_to_request_issue?)
  end

  def active_legacy_appeals
    @active_matchable_legacy_appeals ||= matchable_legacy_appeals.select(&:active?)
  end

  def ratings_with_issues
    veteran.ratings.reject { |rating| rating.issues.empty? }
  end

  def ratings_cache_key
    "#{veteran_file_number}-ratings"
  end

  def formatted_receipt_date
    receipt_date ? receipt_date.to_formatted_s(:short_date) : ""
  end

  def end_product_station
    "499" # National Work Queue
  end

  def validate_receipt_date_not_before_ama
    errors.add(:receipt_date, "before_ama") if receipt_date < self.class.ama_activation_date
  end

  def validate_receipt_date_not_in_future
    errors.add(:receipt_date, "in_future") if Time.zone.today < receipt_date
  end

  def validate_receipt_date
    return unless receipt_date
    validate_receipt_date_not_before_ama
    validate_receipt_date_not_in_future
  end

  def legacy_opt_in_enabled?
    FeatureToggle.enabled?(:intake_legacy_opt_in)
  end
end
