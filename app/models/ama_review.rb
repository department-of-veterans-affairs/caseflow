class AmaReview < ApplicationRecord
  include CachedAttributes

  validate :validate_receipt_date

  AMA_BEGIN_DATE = Date.new(2017, 11, 1).freeze

  self.abstract_class = true

  attr_reader :saving_review

  has_many :request_issues, as: :review_request
  has_many :claimants, as: :review_request

  before_destroy :remove_issues!

  # cache_attribute :cached_serialized_timely_ratings, cache_key: :timely_ratings_cache_key, expires_in: 1.day do
  #   receipt_date && timely_ratings_with_issues.map(&:ui_hash)
  # end

  cache_attribute :cached_serialized_ratings, cache_key: :ratings_cache_key, expires_in: 1.day do
    ratings_with_issues.map(&:ui_hash)
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

  private

  def ratings_with_issues
    veteran.ratings.reject { |rating| rating.issues.empty? }
  end

  # disabled for simplecov sake
  # def timely_ratings_with_issues
  #  return unless receipt_date
  #
  #  veteran.timely_ratings(from_date: receipt_date).reject { |rating| rating.issues.empty? }
  # end

  def ratings_cache_key
    "#{veteran_file_number}-ratings"
  end

  # def timely_ratings_cache_key
  #  "#{veteran_file_number}-#{formatted_receipt_date}"
  # end

  # def formatted_receipt_date
  #  receipt_date ? receipt_date.to_formatted_s(:short_date) : ""
  # end

  def end_product_station
    "397" # TODO: Change to 499 National Work Queue
  end

  def validate_receipt_date_not_before_ama
    errors.add(:receipt_date, "before_ama") if receipt_date < AMA_BEGIN_DATE
  end

  def validate_receipt_date_not_in_future
    errors.add(:receipt_date, "in_future") if Time.zone.today < receipt_date
  end

  def validate_receipt_date
    return unless receipt_date
    validate_receipt_date_not_before_ama
    validate_receipt_date_not_in_future
  end
end
