class Intake < ApplicationRecord
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
    veteran_not_accessible: "veteran_not_accessible",
    veteran_not_valid: "veteran_not_valid",
    duplicate_intake_in_progress: "duplicate_intake_in_progress"
  }.freeze

  FORM_TYPES = {
    ramp_election: "RampElectionIntake",
    ramp_refiling: "RampRefilingIntake",
    supplemental_claim: "SupplementalClaimIntake",
    higher_level_review: "HigherLevelReviewIntake",
    appeal: "AppealIntake"
  }.freeze

  attr_reader :error_data

  def self.in_progress
    where(completed_at: nil).where(started_at: IN_PROGRESS_EXPIRES_AFTER.ago..Time.zone.now)
  end

  def self.expired
    where(completed_at: nil).where(started_at: Time.zone.at(0)...IN_PROGRESS_EXPIRES_AFTER.ago)
  end

  def self.build(form_type:, veteran_file_number:, user:)
    intake_classname = FORM_TYPES[form_type.to_sym]

    fail FormTypeNotSupported unless intake_classname

    intake_classname.constantize.new(
      veteran_file_number: veteran_file_number,
      user: user
    )
  end

  def self.close_expired_intakes!
    Intake.expired.each do |intake|
      intake.complete_with_status!(:expired)
      intake.cancel_detail!
    end
  end

  def self.flagged_for_manager_review
    Intake.select("intakes.*, intakes.type as form_type, users.full_name")
      .joins(:user,
             # Exclude an intake from results if an intake with the same veteran_file_number
             # and intake type has succeeded since the completed_at time (indicating the issue has been resolved)
             "LEFT JOIN
               (SELECT veteran_file_number,
                 type,
                 MAX(completed_at) as succeeded_at
               FROM intakes
               WHERE completion_status = 'success'
               GROUP BY veteran_file_number, type) latest_success
               ON intakes.veteran_file_number = latest_success.veteran_file_number
               AND intakes.type = latest_success.type",
             # To exclude ramp elections that were established outside of Caseflow
             "LEFT JOIN ramp_elections ON intakes.veteran_file_number = ramp_elections.veteran_file_number")
      .where.not(completion_status: "success")
      .where(error_code: [nil, "veteran_not_accessible", "veteran_not_valid"])
      .where(
        "(intakes.completed_at > latest_success.succeeded_at OR latest_success.succeeded_at IS NULL)
        AND NOT (intakes.type = 'RampElectionIntake' AND ramp_elections.established_at IS NOT NULL)"
      )
  end

  def self.user_stats(user, n_days = 60)
    stats = {}
    Intake.select("intakes.*, date(completed_at) as day_completed")
      .where(user: user)
      .where("completed_at > ?", Time.zone.now.end_of_day - n_days.days)
      .where(completion_status: "success")
      .order("day_completed").each do |intake|
      completed = intake[:day_completed].iso8601
      type = intake.detail_type.underscore.to_sym
      stats[completed] ||= { type => 0, date: completed }
      stats[completed][type] ||= 0
      stats[completed][type] += 1
    end
    stats.sort.map { |entry| entry[1] }.reverse
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

      update(
        started_at: Time.zone.now,
        detail: find_or_build_initial_detail
      )
    else
      update(
        started_at: Time.zone.now,
        completed_at: Time.zone.now,
        completion_status: :error
      )
      return false
    end
  end

  def review_errors
    fail Caseflow::Error::MustImplementInSubclass
  end

  def review!(_review_params)
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
    detail.destroy!
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
    if !file_number_valid?
      self.error_code = :invalid_file_number

    elsif !veteran
      self.error_code = :veteran_not_found

    elsif !veteran.accessible?
      self.error_code = :veteran_not_accessible

    elsif !veteran.valid?(:bgs)
      self.error_code = :veteran_not_valid
      @error_data = veteran_invalid_fields

    elsif duplicate_intake_in_progress
      self.error_code = :duplicate_intake_in_progress
      @error_data = { processed_by: duplicate_intake_in_progress.user.full_name }

    else
      validate_detail_on_start

    end

    !error_code
  end

  def duplicate_intake_in_progress
    @duplicate_intake_in_progress ||=
      Intake.in_progress.find_by(type: type, veteran_file_number: veteran_file_number)
  end

  def veteran
    @veteran ||= Veteran.find_or_create_by_file_number(veteran_file_number)
  end

  def ui_hash(ama_enabled)
    {
      id: id,
      form_type: form_type,
      veteran_file_number: veteran_file_number,
      veteran_name: veteran&.name&.formatted(:readable_short),
      veteran_form_name: veteran&.name&.formatted(:form),
      veteran_is_deceased: veteran&.deceased?,
      completed_at: completed_at,
      relationships: ama_enabled && veteran&.relationships&.map(&:ui_hash)
    }
  end

  def form_type
    FORM_TYPES.key(self.class.name)
  end

  def create_end_product_and_contentions
    detail.create_end_products_and_contentions!
  rescue StandardError => e
    abort_completion!
    raise e
  end

  private

  def update_person!
    # Update the person when a claimant is created
    Person.find_or_create_by(participant_id: detail.claimant_participant_id).tap do |person|
      person.update!(date_of_birth: BGSService.new.fetch_person_info(detail.claimant_participant_id)[:birth_date])
    end
  end

  def file_number_valid?
    return false unless veteran_file_number

    self.veteran_file_number = veteran_file_number.strip
    veteran_file_number =~ /^[0-9]{8,9}$/
  end

  # Optionally implement this methods in subclass
  def validate_detail_on_start
    true
  end

  def find_or_build_initial_detail
    fail Caseflow::Error::MustImplementInSubclass
  end

  def veteran_invalid_fields
    missing_fields = veteran.errors.details
      .select { |_, errors| errors.any? { |e| e[:error] == :blank } }
      .keys

    address_too_long = veteran.errors.details.any? do |field_name, errors|
      [:address_line1, :address_line2, :address_line3].include?(field_name) &&
        errors.any? { |e| e[:error] == :too_long }
    end

    {
      veteran_missing_fields: missing_fields,
      veteran_address_too_long: address_too_long
    }
  end
end
