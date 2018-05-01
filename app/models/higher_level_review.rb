class HigherLevelReview < ApplicationRecord
  include EstablishesEndProduct

  validate :validate_receipt_date

  with_options if: :saving_review do
    validates :receipt_date, presence: { message: "blank" }
    validates :informal_conference, :same_office, inclusion: { in: [true, false], message: "blank" }
  end

  AMA_BEGIN_DATE = Date.new(2018, 4, 17).freeze

  attr_reader :saving_review

  def start_review!
    @saving_review = true
  end

  def create_end_product!
    establish_end_product! && :created
  end

  def end_product_description
    end_product_reference_id && end_product_to_establish.description_with_routing
  end

  def pending_end_product_description
    # This is for EPs not yet created or that failed to create
    end_product_to_establish.modifier
  end

  private

  def veteran
    @veteran ||= Veteran.new(file_number: veteran_file_number)
  end

  # TODO: Update with real code and modifier data
  def end_product_code
    "030HLRAMA"
  end

  def end_product_modifier
    "030"
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
