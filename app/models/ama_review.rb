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

  def create_claimants!(claimant_data:)
    claimants.destroy_all unless claimants.empty?
    claimants.create_from_intake_data!(claimant_data)
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

  def create_issues!(request_issues_data:)
    request_issues.destroy_all unless request_issues.empty?

    request_issues_data.map { |data| request_issues.create_from_intake_data!(data) }
  end

  def create_end_product_and_contentions!
    return nil if contention_descriptions_to_create.empty?
    end_product_establishment.perform!
    create_contentions_on_new_end_product!
    create_associated_rated_issues_in_vbms!
    update! established_at: Time.zone.now
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

  def contention_descriptions_to_create
    @contention_descriptions_to_create ||=
      request_issues.where(contention_reference_id: nil).pluck(:description)
  end

  def rated_contentions
    request_issues.where.not(contention_reference_id: nil, rating_issue_profile_date: nil)
  end

  def create_rated_issue_contention_map
    issue_contention_map = {}
    rated_contentions.each do |contention|
      issue_contention_map[contention.rating_issue_reference_id] = contention.contention_reference_id
    end
    issue_contention_map
  end

  def rated_issue_contention_map
    @rated_issue_contention_map ||= create_rated_issue_contention_map
  end

  # VBMS will return ALL contentions on a end product when you create contentions,
  # not just the ones that were just created. This method assumes there are no
  # pre-existing contentions on the end product. Since it was also just created.
  def create_contentions_on_new_end_product!
    # Load all the issues so we can match them in memory
    request_issues.all.tap do |issues|
      # Currently not making any assumptions about the order in which VBMS returns
      # the created contentions. Instead find the issue by matching text.
      create_contentions_in_vbms.each do |contention|
        matching_issue = issues.find { |issue| issue.description == contention.text }
        matching_issue && matching_issue.update!(contention_reference_id: contention.id)
      end

      fail ContentionCreationFailed if issues.any? { |issue| !issue.contention_reference_id }
    end
  end

  def create_contentions_in_vbms
    VBMSService.create_contentions!(
      veteran_file_number: veteran_file_number,
      claim_id: end_product_establishment.reference_id,
      contention_descriptions: contention_descriptions_to_create
    )
  end

  def create_associated_rated_issues_in_vbms!
    return if rated_issue_contention_map.blank?
    VBMSService.associate_rated_issues!(
      claim_id: end_product_establishment.reference_id,
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
