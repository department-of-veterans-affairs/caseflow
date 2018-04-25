class RampReview < ApplicationRecord
  include EstablishesEndProduct

  belongs_to :user

  RAMP_BEGIN_DATE = Date.new(2017, 11, 1).freeze

  self.abstract_class = true

  attr_reader :saving_review

  enum option_selected: {
    supplemental_claim: "supplemental_claim",
    higher_level_review: "higher_level_review",
    higher_level_review_with_hearing: "higher_level_review_with_hearing",
    appeal: "appeal"
  }

  has_many :issues, as: :review, class_name: "RampIssue"

  HIGHER_LEVEL_REVIEW_OPTIONS = %w[higher_level_review higher_level_review_with_hearing].freeze

  END_PRODUCT_DATA_BY_OPTION = {
    "supplemental_claim" => { code: "683SCRRRAMP", modifier: "683" },
    "higher_level_review" => { code: "682HLRRRAMP", modifier: "682" },
    "higher_level_review_with_hearing" => { code: "682HLRRRAMP", modifier: "682" }
  }.freeze

  validates :receipt_date, :option_selected, presence: { message: "blank" }, if: :saving_review

  # TODO move to EstablishesEndProduct
  def self.established
    where.not(established_at: nil)
  end

  # Allows us to enable certain validations only when saving the review
  def start_review!
    @saving_review = true
  end

  def higher_level_review?
    HIGHER_LEVEL_REVIEW_OPTIONS.include?(option_selected)
  end

  # If an EP with the exact same traits has already been created. Use that instead
  # of creating a new EP. This prevents duplicate EP errors and allows this method
  # to be idempotent
  #
  # Returns a symbol designating whether the end product was created or connected
  def create_or_connect_end_product!
    return connect_end_product! if matching_end_product

    create_end_product! && :created
  end

  def end_product_description
    end_product_reference_id && end_product.description_with_routing
  end

  def pending_end_product_description
    # This is for EPs not yet created or that failed to create
    end_product.modifier
  end

  private

  def veteran
    @veteran ||= Veteran.new(file_number: veteran_file_number)
  end

  # Find an end product that has the traits of the end product that should be created.
  def matching_end_product
    @matching_end_product ||= veteran.end_products.find { |ep| end_product.matches?(ep) }
  end

  def connect_end_product!
    update!(
      end_product_reference_id: matching_end_product.claim_id,
      established_at: Time.zone.now
    ) && :connected
  end

  def end_product_code
    (END_PRODUCT_DATA_BY_OPTION[option_selected] || {})[:code]
  end

  def end_product_modifier
    (END_PRODUCT_DATA_BY_OPTION[option_selected] || {})[:modifier]
  end

  def end_product_station
    "397" # AMC
  end

  def validate_receipt_date_not_before_ramp
    errors.add(:receipt_date, "before_ramp") if receipt_date < RAMP_BEGIN_DATE
  end

  def validate_receipt_date_not_in_future
    errors.add(:receipt_date, "in_future") if Time.zone.today < receipt_date
  end
end
