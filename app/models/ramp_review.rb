# frozen_string_literal: true

class RampReview < ApplicationRecord
  belongs_to :user
  has_one :intake, as: :detail

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

  before_destroy :remove_issues!

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

  def on_decision_issues_sync_processed(end_product_establishment)
    # no-op, can be overwritten
  end

  # If an EP with the exact same traits has already been created and is still active. Use that instead
  # of creating a new EP. This prevents duplicate EP errors and allows this method
  # to be idempotent
  #
  # Returns a symbol designating whether the end product was created or connected
  def create_or_connect_end_product!
    return connect_existing_establishment! if preexisting_end_product_establishment
    return connect_end_product! if matching_end_product&.active?

    establish_end_product!(commit: true) && :created
  end

  def end_product_description
    end_product_establishment.description
  end

  def end_product_base_modifier
    end_product_modifier
  end

  def end_product_active?
    end_product_establishment.status_active?(sync: true)
  end

  def establish_end_product!(commit:)
    new_end_product_establishment.perform!(commit: commit)
    update! established_at: Time.zone.now
  end

  def end_product_establishment
    return nil unless established_at

    preexisting_end_product_establishment || connected_end_product_establishment
  end

  def valid_modifiers
    [end_product_modifier]
  end

  def remove_issues!
    issues.destroy_all unless issues.empty?
  end

  private

  def connect_existing_establishment!
    update!(
      established_at: Time.zone.now
    ) && :connected
  end

  def intake_processed_by
    intake ? intake.user : nil
  end

  def preexisting_end_product_establishment
    @preexisting_end_product_establishment ||= EndProductEstablishment.find_by(source: self)
  end

  def matching_end_product_establishments
    @matching_end_product_establishments ||= EndProductEstablishment.where(
      veteran_file_number: veteran_file_number,
      source_type: "RampElection",
      claim_date: receipt_date,
      code: end_product_code,
      payee_code: payee_code,
      claimant_participant_id: claimant_participant_id,
      modifier: end_product_modifier,
      station: "397",
      benefit_type_code: veteran.benefit_type_code
    )
  end

  def connected_end_product_establishment
    @connected_end_product_establishment ||=
      matching_end_product_establishments.detect do |epe|
        epe.result&.last_action_date&.nil? || epe.result.last_action_date > established_at
      end
  end

  def matching_active_end_product
    new_end_product_establishment.preexisting_end_products.detect(&:active?)
  end

  def new_end_product_establishment
    @new_end_product_establishment ||= EndProductEstablishment.new(
      veteran_file_number: veteran_file_number,
      claim_date: receipt_date,
      code: end_product_code,
      payee_code: payee_code,
      claimant_participant_id: claimant_participant_id,
      valid_modifiers: valid_modifiers,
      source: self,
      station: "397", # AMC
      benefit_type_code: veteran.benefit_type_code,
      user: intake_processed_by
    )
  end

  def veteran
    @veteran ||= Veteran.find_or_create_by_file_number(veteran_file_number)
  end

  def connect_end_product!
    save_end_product_establishment_if_missing

    update!(
      established_at: Time.zone.now
    ) && :connected
  end

  def save_end_product_establishment_if_missing
    return if connected_end_product_establishment

    new_end_product_establishment.update!(reference_id: matching_active_end_product.claim_id)
  end

  def end_product_code
    (END_PRODUCT_DATA_BY_OPTION[option_selected] || {})[:code]
  end

  def end_product_modifier
    (END_PRODUCT_DATA_BY_OPTION[option_selected] || {})[:modifier]
  end

  def payee_code
    "00" # payee is Veteran for RAMP intakes
  end

  def claimant_participant_id
    veteran.participant_id
  end

  def validate_receipt_date_not_before_ramp
    errors.add(:receipt_date, "before_ramp") if receipt_date < RAMP_BEGIN_DATE
  end

  def validate_receipt_date_not_in_future
    errors.add(:receipt_date, "in_future") if Time.zone.today < receipt_date
  end
end
