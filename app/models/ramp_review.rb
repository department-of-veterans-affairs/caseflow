class RampReview < ApplicationRecord
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

  def established?
    !!established_at
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
    return connect_end_product! if end_product_establishment.preexisting_end_product

    establish_end_product! && :created
  end

  def end_product_description
    end_product_establishment.description
  end

  def end_product_base_modifier
    end_product_modifier
  end

  def end_product_active?
    sync_ep_status! && cached_status_active?
  end

  def end_product_canceled?
    sync_ep_status! && end_product_establishment.status_canceled?
  end

  def sync_ep_status!
    # There is no need to sync end_product_status if the status
    # is already inactive since an EP can never leave that state
    return true unless cached_status_active?

    ## TODO: Remove this once all the data is backfilled
    if (saved_end_product_establishment = EndProductEstablishment.find_by(source: self))
      saved_end_product_establishment.sync!
      if FeatureToggle.enabled?(:automatic_ramp_rollback) && saved_end_product_establishment.status_canceled?
        rollback_ramp_review
      end
      true
    end
  end

  def establish_end_product!
    end_product_establishment.perform!
    update! established_at: Time.zone.now
  end

  class << self
    def established
      where.not(established_at: nil)
    end

    def active
      # We only know the set of inactive EP statuses
      # We also only know the EP status after fetching it from BGS
      # Therefore, our definition of active is when the EP is either
      #   not known or not known to be inactive
      established.where("end_product_status NOT IN (?) OR end_product_status IS NULL", EndProduct::INACTIVE_STATUSES)
    end
  end

  private

  def find_end_product_establishment
    @preexisting_end_product_establishment ||= EndProductEstablishment.find_by(source: self)
  end

  def new_end_product_establishment
    @new_end_product_establishment ||= EndProductEstablishment.new(
      veteran_file_number: veteran_file_number,
      reference_id: end_product_reference_id,
      claim_date: receipt_date,
      code: end_product_code,
      valid_modifiers: [end_product_modifier],
      source: self,
      station: "397" # AMC
    )
  end

  def end_product_establishment
    find_end_product_establishment || new_end_product_establishment
  end

  def rollback_ramp_review
    RampElectionRollback.create!(
      ramp_election: self,
      user: User.system_user,
      reason: "Automatic roll back due to EP #{end_product_establishment.modifier} cancelation"
    )
  end

  def veteran
    @veteran ||= Veteran.find_or_create_by_file_number(veteran_file_number)
  end

  def connect_end_product!
    update!(
      end_product_reference_id: end_product_establishment.preexisting_end_product.claim_id,
      established_at: Time.zone.now
    ) && :connected
  end

  def cached_status_active?
    !EndProduct::INACTIVE_STATUSES.include?(end_product_establishment.synced_status)
  end

  def end_product_code
    (END_PRODUCT_DATA_BY_OPTION[option_selected] || {})[:code]
  end

  def end_product_modifier
    (END_PRODUCT_DATA_BY_OPTION[option_selected] || {})[:modifier]
  end

  def validate_receipt_date_not_before_ramp
    errors.add(:receipt_date, "before_ramp") if receipt_date < RAMP_BEGIN_DATE
  end

  def validate_receipt_date_not_in_future
    errors.add(:receipt_date, "in_future") if Time.zone.today < receipt_date
  end
end
