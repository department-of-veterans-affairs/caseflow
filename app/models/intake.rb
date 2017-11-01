class Intake < ActiveRecord::Base
  belongs_to :user
  belongs_to :detail, polymorphic: true

  enum completion_status: {
    success: "success",
    canceled: "canceled",
    error: "error"
  }

  ERROR_CODES = {
    invalid_file_number: "invalid_file_number",
    veteran_not_found: "veteran_not_found",
    veteran_not_accessible: "veteran_not_accessible"
  }.freeze

  attr_reader :error_data

  def self.in_progress
    where(completed_at: nil).where.not(started_at: nil)
  end

  def start!
    if validate_start
      update_attributes(
        started_at: Time.zone.now,
        detail: find_or_create_initial_detail
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

    else
      validate_detail_on_start

    end

    !error_code
  end

  def veteran
    @veteran ||= Veteran.new(file_number: veteran_file_number).load_bgs_record!
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

  def find_or_create_initial_detail
    fail Caseflow::Error::MustImplementInSubclass
  end
end
