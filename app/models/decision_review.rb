class DecisionReview < ApplicationRecord
  include CachedAttributes

  validate :validate_receipt_date

  self.abstract_class = true

  attr_reader :saving_review

  has_many :request_issues, as: :review_request
  has_many :claimants, as: :review_request

  before_destroy :remove_issues!

  cache_attribute :cached_serialized_ratings, cache_key: :ratings_cache_key, expires_in: 1.day do
    ratings_with_issues.map(&:ui_hash)
  end

  AMA_ACTIVATION_DATE =
    if use_ama_activation_date?
      Constants::DATES["AMA_ACTIVATION"].to_date
    else
      Constants::DATES["AMA_ACTIVATION_TEST"].to_date
    end

  def self.review_title
    to_s.underscore.titleize
  end

  def serialized_ratings
    return unless receipt_date

    cached_serialized_ratings.each do |rating|
      rating[:issues].each do |rating_issue_hash|
        rating_issue_hash[:timely] = timely_rating?(Date.parse(rating_issue_hash[:promulgation_date].to_s))
        # always re-compute flags that depend on data in our db
        rating_issue_hash.merge!(RatingIssue.from_ui_hash(rating_issue_hash).ui_hash)
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
      claimantNotVeteran: claimant_not_veteran,
      receiptDate: receipt_date.to_formatted_s(:json_date),
      legacyOptInApproved: legacy_opt_in_approved,
      ratings: serialized_ratings,
      requestIssues: request_issues.map(&:ui_hash)
    }
  end

  def timely_rating?(promulgation_date)
    return true unless receipt_date
    promulgation_date >= (receipt_date - Rating::ONE_YEAR_PLUS_DAYS)
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

  private

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
    errors.add(:receipt_date, "before_ama") if receipt_date < AMA_ACTIVATION_DATE
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

  def use_ama_activation_date?
    FeatureToggle.enabled?(:use_ama_activation_date)
  end
end
