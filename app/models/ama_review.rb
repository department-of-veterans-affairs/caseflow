class AmaReview < ApplicationRecord
  include CachedAttributes

  validate :validate_receipt_date

  AMA_BEGIN_DATE = Date.new(2018, 4, 1).freeze

  self.abstract_class = true

  attr_reader :saving_review

  has_many :request_issues, as: :review_request
  has_many :claimants, as: :review_request

  cache_attribute :cached_serialized_timely_ratings, cache_key: :timely_ratings_cache_key, expires_in: 1.day do
    receipt_date && veteran.timely_ratings(from_date: receipt_date).map(&:ui_hash)
  end

  def start_review!
    @saving_review = true
  end

  def create_claimants!(participant_id:, payee_code:)
    claimants.destroy_all unless claimants.empty?
    claimants.create_from_intake_data!(participant_id: participant_id, payee_code: payee_code)
  end

  def remove_claimants!
    claimants.destroy_all
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

  def create_issues!(request_issues_data:)
    request_issues.destroy_all unless request_issues.empty?

    request_issues_data.map { |data| request_issues.create_from_intake_data!(data) }
  end

  def create_end_products_and_contentions!
    rating_establishment = create_end_product_and_contentions!(rated: true)
    invalid_modifiers = rating_establishment ? [rating_establishment.modifier] : []
    nonrating_establishment = create_end_product_and_contentions!(rated: false, invalid_modifiers: invalid_modifiers)

    if rating_establishment || nonrating_establishment
      update! established_at: Time.zone.now
    end
  end

  def create_end_product_and_contentions!(rated: true, invalid_modifiers: [])
    return nil if issue_descriptions_to_create(rated: rated).empty?

    end_product_establishment(rated: rated, invalid_modifiers: invalid_modifiers).tap do |establishment|
      establishment.perform!
      create_contentions_on_new_end_product!(rated: rated)
      create_associated_rated_issues_in_vbms! if rated
    end
  end

  def veteran
    @veteran ||= Veteran.find_or_create_by_file_number(veteran_file_number)
  end

  private

  def end_product_establishment
    fail Caseflow::Error::MustImplementInSubclass
  end

  def timely_ratings_cache_key
    "#{veteran_file_number}-#{formatted_receipt_date}"
  end

  def formatted_receipt_date
    receipt_date ? receipt_date.to_formatted_s(:short_date) : ""
  end

  def rated_issues_to_create
    @rated_issues_to_create ||= request_issues.rated.where(contention_reference_id: nil)
  end

  def nonrated_issues_to_create
    @nonrated_issues_to_create ||= request_issues.nonrated.where(contention_reference_id: nil)
  end

  def issue_descriptions_to_create(rated: true)
    (rated ? rated_issues_to_create : nonrated_issues_to_create).pluck(:description)
  end

  def create_rated_issue_contention_map
    issue_contention_map = {}
    request_issues.where.not(rating_issue_reference_id: nil).find_each do |contention|
      issue_contention_map[contention.rating_issue_reference_id] = contention.contention_reference_id
    end
    issue_contention_map
  end

  def rated_issue_contention_map
    @rated_issue_contention_map ||= create_rated_issue_contention_map
  end

  def create_contentions_on_new_end_product!(rated: true)
    issues_to_create = (rated ? rated_issues_to_create : nonrated_issues_to_create).all

    end_product_establishment(rated: rated).create_contentions!(issues_to_create)
  end

  def create_associated_rated_issues_in_vbms!
    return if rated_issue_contention_map.blank?
    VBMSService.associate_rated_issues!(
      claim_id: end_product_establishment(rated: true).reference_id,
      rated_issue_contention_map: rated_issue_contention_map
    )
  end

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
