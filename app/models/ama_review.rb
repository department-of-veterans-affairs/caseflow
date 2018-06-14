class AmaReview < ApplicationRecord
  include EstablishesEndProduct

  AMA_BEGIN_DATE = Date.new(2018, 4, 17).freeze

  self.abstract_class = true

  attr_reader :saving_review

  has_many :request_issues, as: :review_request
  has_many :claimants, as: :review_request

  validate :validate_receipt_date
  validates :receipt_date, presence: { message: "blank" }, if: :saving_review

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

  private

  def validate_receipt_date
    return unless receipt_date
    validate_receipt_date_not_before_ama
    validate_receipt_date_not_in_future
  end

  def validate_receipt_date_not_before_ama
    errors.add(:receipt_date, "before_ama") if receipt_date < HigherLevelReview::AMA_BEGIN_DATE
  end

  def validate_receipt_date_not_in_future
    errors.add(:receipt_date, "in_future") if Time.zone.today < receipt_date
  end
end
