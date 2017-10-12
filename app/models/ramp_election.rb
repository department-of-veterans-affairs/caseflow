class RampElection < ActiveRecord::Base
  OPTIONS = %w(
    supplemental_claim
    higher_level_review
    higher_level_review_with_hearing
    withdraw
  ).freeze

  validates :option_selected, inclusion: { in: OPTIONS, message: "invalid" }, allow_nil: true
  validates :receipt_date, :option_selected, presence: { message: "blank" }, if: :saving_receipt?
  validate :validate_receipt_date_after_notice_date

  def start_saving_receipt
    @saving_receipt = true
  end

  def saving_receipt?
    @saving_receipt
  end

  private

  def validate_receipt_date_after_notice_date
    return unless notice_date && receipt_date

    if notice_date > receipt_date
      errors.add(:receipt_date, "before_notice_date")
    end
  end
end
