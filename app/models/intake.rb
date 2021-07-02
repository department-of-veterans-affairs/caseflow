# frozen_string_literal: true

class Intake < CaseflowRecord
  class FormTypeNotSupported < StandardError; end

  belongs_to :user
  belongs_to :detail, polymorphic: true

  COMPLETION_TIMEOUT = 5.minutes
  IN_PROGRESS_EXPIRES_AFTER = 1.day

  enum completion_status: {
    success: "success",
    canceled: "canceled",
    error: "error",
    expired: "expired"
  }

  ERROR_CODES = {
    invalid_file_number: "invalid_file_number",
    veteran_not_found: "veteran_not_found",
    veteran_has_multiple_phone_numbers: "veteran_has_multiple_phone_numbers",
    veteran_has_duplicate_records_in_corpdb: "veteran_has_duplicate_records_in_corpdb",
    veteran_not_accessible: "veteran_not_accessible",
    veteran_not_modifiable: "veteran_not_modifiable",
    veteran_not_valid: "veteran_not_valid",
    duplicate_intake_in_progress: "duplicate_intake_in_progress",
    reserved_veteran_file_number: "reserved_veteran_file_number",
    incident_flash: "incident_flash"
  }.freeze

  FORM_TYPES = {
    ramp_election: "RampElectionIntake",
    ramp_refiling: "RampRefilingIntake",
    supplemental_claim: "SupplementalClaimIntake",
    higher_level_review: "HigherLevelReviewIntake",
    appeal: "AppealIntake"
  }.freeze

  attr_reader :error_data

  after_initialize :strip_file_number

  scope :updated_since_for_appeals, lambda { |since|
    select(:detail_id)
      .where("#{table_name}.updated_at >= ?", since)
      .where("detail_type='Appeal'")
  }

  def strip_file_number
    return if veteran_file_number.nil?

    veteran_file_number.strip!
  end

  def store_error_data(error_data)
    @error_data = error_data
  end

  class << self
    def in_progress
      where(completed_at: nil).where(started_at: IN_PROGRESS_EXPIRES_AFTER.ago..Time.zone.now)
    end

    def expired
      where(completed_at: nil).where(started_at: Time.zone.at(0)...IN_PROGRESS_EXPIRES_AFTER.ago)
    end

    def build(form_type:, veteran_file_number:, user:)
      intake_classname = FORM_TYPES[form_type.to_sym]

      fail FormTypeNotSupported unless intake_classname

      intake_classname.constantize.new(
        veteran_file_number: veteran_file_number.strip,
        user: user
      )
    end

    def close_expired_intakes!
      Intake.expired.each do |intake|
        intake.complete_with_status!(:expired)
        intake.cancel_detail!
      end
    end

    def flagged_for_manager_review
      IntakesFlaggedForManagerReviewQuery.call
    end

    def user_stats(user, n_days = 60)
      IntakeUserStats.new(user: user, n_days: n_days).call
    end
  end

  def pending?
    !!completion_started_at && completion_started_at > COMPLETION_TIMEOUT.ago
  end

  def complete?
    !!completed_at
  end

  def start!
    preload_intake_data!

    if validate_start
      self.class.close_expired_intakes!

      after_validated_pre_start!

      update!(
        started_at: Time.zone.now,
        detail: find_or_build_initial_detail
      )
    else
      update!(
        started_at: Time.zone.now,
        completed_at: Time.zone.now,
        completion_status: :error
      )
      false
    end
  end

  def review_errors
    fail Caseflow::Error::MustImplementInSubclass
  end

  def review!(_review_params, _current_user)
    fail Caseflow::Error::MustImplementInSubclass
  end

  def cancel!(reason:, other: nil)
    return if complete? || pending?

    transaction do
      cancel_detail!
      update!(
        cancel_reason: reason,
        cancel_other: other
      )
      complete_with_status!(:canceled)
    end
  end

  def cancel_detail!
    detail&.destroy!
  end

  def save_error!(*)
    fail Caseflow::Error::MustImplementInSubclass
  end

  # :nocov:
  def complete!(_request_params)
    fail NotImplementedError
  end
  # :nocov:

  # Optional step to load data into the Caseflow DB that will be used for the intake
  def preload_intake_data!
    nil
  end

  def start_completion!
    update!(completion_started_at: Time.zone.now)
  end

  def abort_completion!
    update!(completion_started_at: nil)
  end

  def complete_with_status!(status)
    update!(
      completed_at: Time.zone.now,
      completion_status: status
    )
  end

  def validate_start
    validator = IntakeStartValidator.new(intake: self)

    return false unless validator.validate

    validate_detail_on_start

    !error_code
  end

  def veteran
    @veteran ||= Veteran.find_or_create_by_file_number(veteran_file_number)
  end

  def ui_hash
    Intake::IntakeSerializer.new(self).serializable_hash[:data][:attributes]
  end

  def form_type
    FORM_TYPES.key(self.class.name)
  end

  def create_end_product_and_contentions
    detail.create_end_products_and_contentions!
  rescue StandardError => error
    abort_completion!
    raise error
  end

  # rubocop:disable Metrics/MethodLength
  # rubocop:disable Metrics/AbcSize
  def veteran_invalid_fields
    missing_fields = veteran.errors.details
      .select { |_, errors| errors.any? { |e| e[:error] == :blank } }
      .keys

    address_too_long = veteran.errors.details.any? do |field_name, errors|
      [:address_line1, :address_line2, :address_line3].include?(field_name) &&
        errors.any? { |e| e[:error] == :too_long }
    end

    address_invalid_characters = veteran.errors.details.any? do |field_name, errors|
      [:address_line1, :address_line2, :address_line3].include?(field_name) &&
        errors.any? { |e| e[:error] == "invalid_characters" }
    end

    city_invalid_characters = veteran.errors.details[:city]&.any? { |e| e[:error] == "invalid_characters" }

    city_too_long = veteran.errors.details[:city]&.any? { |e| e[:error] == "too_long" }

    date_of_birth = veteran.errors.details[:date_of_birth]&.any? { |e| e[:error] == "invalid_date_of_birth" }

    name_suffix_invalid = veteran.errors.details[:name_suffix]&.any? { |e| e[:error] == "invalid_character" }

    zip_code_invalid = veteran.errors.details[:zip_code]&.any? { |e| e[:error] == "invalid_zip_code" }

    pay_grade_invalid = veteran.errors.details[:pay_grades]&.any? { |e| e[:error] == "invalid_pay_grade" }

    {
      veteran_missing_fields: missing_fields,
      veteran_address_too_long: address_too_long,
      veteran_address_invalid_fields: address_invalid_characters,
      veteran_city_invalid_fields: city_invalid_characters,
      veteran_city_too_long: city_too_long,
      veteran_date_of_birth_invalid: date_of_birth,
      veteran_name_suffix_invalid: name_suffix_invalid,
      veteran_zip_code_invalid: zip_code_invalid,
      veteran_pay_grade_invalid: pay_grade_invalid
    }
  end
  # rubocop:enable Metrics/AbcSize
  # rubocop:enable Metrics/MethodLength

  # Optionally implement this methods in subclass
  def validate_detail_on_start
    true
  end

  private

  # Optional step called after the intake is validated and not-yet-marked as started
  def after_validated_pre_start!
    nil
  end

  def update_person!
    # Update the person when a claimant is created
    Person.find_or_create_by(participant_id: detail.claimant_participant_id).tap(&:update_cached_attributes!)
  end

  def find_or_build_initial_detail
    fail Caseflow::Error::MustImplementInSubclass
  end
end
