class HigherLevelReview < ApplicationRecord
  include EstablishesEndProduct

  validate :validate_receipt_date

  has_many :request_issues, as: :review_request

  with_options if: :saving_review do
    validates :receipt_date, presence: { message: "blank" }
    validates :informal_conference, :same_office, inclusion: { in: [true, false], message: "blank" }
  end

  AMA_BEGIN_DATE = Date.new(2018, 4, 17).freeze

  attr_reader :saving_review

  def start_review!
    @saving_review = true
  end

  def create_end_product_and_contentions!
    return nil if contention_descriptions_to_create.empty?
    establish_end_product!
    create_contentions_on_new_end_product!
  end

  def create_issues!(request_issues_data:)
    request_issues.destroy_all unless request_issues.empty?

    request_issues_data.map { |data| request_issues.create_from_intake_data!(data) }
  end

  def end_product_description
    end_product_reference_id && end_product_to_establish.description_with_routing
  end

  def pending_end_product_description
    # This is for EPs not yet created or that failed to create
    end_product_to_establish.modifier
  end

  private

  def contention_descriptions_to_create
    @contention_descriptions_to_create ||=
      request_issues.where(contention_reference_id: nil).pluck(:description)
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
      claim_id: end_product_reference_id,
      contention_descriptions: contention_descriptions_to_create
    )
  end

  def veteran
    @veteran ||= Veteran.new(file_number: veteran_file_number)
  end

  # TODO: Update with real code and modifier data
  def end_product_code
    "030HLRR"
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
