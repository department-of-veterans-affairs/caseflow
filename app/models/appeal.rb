class Appeal < ApplicationRecord
  validates :receipt_date, :docket_type, presence: { message: "blank" }, on: :intake_review
  validate :validate_receipt_date_within_range

  has_many :request_issues, as: :review_request
  has_many :claimants, as: :review_claimant

  UUID_REGEX = /^\h{8}-\h{4}-\h{4}-\h{4}-\h{12}$/

  def document_fetcher
    @document_fetcher ||= DocumentFetcher.new(
      appeal: self, use_efolder: true
    )
  end

  delegate :documents, :number_of_documents, :manifest_vbms_fetched_at, :manifest_vva_fetched_at, to: :document_fetcher

  def self.find_appeal_by_id_or_find_or_create_legacy_appeal_by_vacols_id(id)
    if UUID_REGEX.match(id)
      find_by_uuid!(id)
    else
      LegacyAppeal.find_or_create_by_vacols_id(id)
    end
  end

  def veteran
    @veteran ||= Veteran.find_or_create_by_file_number(veteran_file_number)
  end

  def create_claimants!(claimant_data:)
    claimants.create_from_intake_data!(claimant_data)
  end

  def remove_claimants!
    claimants.destroy_all
  end

  def create_issues!(request_issues_data:)
    request_issues.destroy_all unless request_issues.empty?

    request_issues_data.map { |data| request_issues.create_from_intake_data!(data) }
  end

  def serializer
    ::WorkQueue::AppealSerializer
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
