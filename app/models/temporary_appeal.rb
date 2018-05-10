class TemporaryAppeal
  validates :receipt_date, :docket_type, presence: { message: "blank" }, on: :intake_review
  validate :validate_receipt_date_within_range

  has_many :request_issues, as: :review_request

  def veteran
    @veteran ||= Veteran.find_or_create_by_file_number(veteran_file_number)
  end

  private

  def validate_receipt_date_within_range
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