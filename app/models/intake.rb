class Intake < ApplicationRecord
  class FormTypeNotSupported < StandardError; end

  belongs_to :user
  belongs_to :detail, polymorphic: true

  enum completion_status: {
    pending: "pending",
    success: "success",
    canceled: "canceled",
    error: "error"
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
    higher_level_review: "HigherLevelReviewIntake"
  }.freeze

  attr_reader :error_data

  def self.in_progress
    where(completed_at: nil).where.not(started_at: nil)
  end

  def self.build(form_type:, veteran_file_number:, user:)
    intake_classname = FORM_TYPES[form_type.to_sym]

    fail FormTypeNotSupported unless intake_classname

    intake_classname.constantize.new(veteran_file_number: veteran_file_number, user: user)
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

  def complete?
    !!completed_at
  end

  def start!
    preload_intake_data!

    if validate_start
      update_attributes(
        started_at: Time.zone.now,
        detail: find_or_build_initial_detail
      )
    else
      update_attributes(
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
      update_attributes!(
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

  def start_complete!
    update_attributes!(
      completion_status: "pending"
    )
  end

  def complete_with_status!(status)
    update_attributes!(
      completed_at: Time.zone.now,
      completion_status: status
    )
  end

  def validate_start
    if !file_number_valid?
      self.error_code = :invalid_file_number

    elsif !veteran.found?
      self.error_code = :veteran_not_found

    elsif !veteran.accessible?
      self.error_code = :veteran_not_accessible

    elsif !veteran.valid?(:bgs)
      self.error_code = :veteran_not_valid
      errors = veteran.errors.messages.map { |(key, _value)| key }
      @error_data = { veteran_missing_fields: errors }

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

  def ui_hash
    {
      id: id,
      form_type: form_type,
      veteran_file_number: veteran_file_number,
      veteran_name: veteran.name.formatted(:readable_short),
      veteran_form_name: veteran.name.formatted(:form),
      completed_at: completed_at
    }
  end

  def form_type
    FORM_TYPES.key(self.class.name)
  end

  private

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
end
