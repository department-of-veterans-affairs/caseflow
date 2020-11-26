# frozen_string_literal: true

##
# SchedulePeriod represents data related to a schedule period for bulk assigning hearing days or assigning judges to
# those hearing day. The record stores the start and end date, filename and whether or not it was
# finalized by the user. SchedulePeriod can be a type of `RoSchedulePeriod` or `JudgeSchedulePeriod`.
# A User cannot upload a spreadsheet for a date period if they've already uploaded and confirmed the schedule. If
# not confirmed, they can re-upload a spreadsheet.
##
class SchedulePeriod < CaseflowRecord
  validate :validate_schedule_period, on: :create

  class OverlappingSchedulePeriods < StandardError; end

  include CachedAttributes

  belongs_to :user
  has_many :allocations
  has_many :non_availabilities

  delegate :full_name, to: :user, prefix: true
  attr_accessor :confirming_to_vacols

  # NOTE: The schedule is NOT actually uploaded to VACOLS; confirming_to_vacols is just a boolean we set
  cache_attribute :submitting_to_vacols, expires_in: 1.day do
    confirming_to_vacols
  end

  def clear_submitted_to_vacols
    clear_cached_attr!(:submitting_to_vacols)
  end

  def start_confirming_schedule
    clear_submitted_to_vacols
    @confirming_to_vacols = true
    submitting_to_vacols
  end

  def end_confirming_schedule
    clear_submitted_to_vacols
    @confirming_to_vacols = false
    submitting_to_vacols
  end

  S3_SUB_BUCKET = "hearing_schedule"

  def validate_schedule_period
    if dates_finalized_or_being_finalized?
      errors[:base] << OverlappingSchedulePeriods.new("You have already uploaded a file for these dates.")
    end
  end

  def spreadsheet_location
    File.join(Rails.root, "tmp", "hearing_schedule", "spreadsheets", file_name)
  end

  def s3_file_location
    S3_SUB_BUCKET + "/" + file_name
  end

  def spreadsheet
    S3Service.fetch_file(s3_file_location, spreadsheet_location)
    Roo::Spreadsheet.open(spreadsheet_location, extension: :xlsx)
  end

  def to_hash
    serializable_hash(
      methods: [:user_full_name, :type]
    )
  end

  def schedule_confirmed(*)
    update(finalized: true)
  end

  def dates_finalized_or_being_finalized?
    SchedulePeriod.where(type: type).any? do |schedule_period|
      (schedule_period.start_date <= start_date && start_date <= schedule_period.end_date) &&
        (schedule_period.submitting_to_vacols || schedule_period.finalized)
    end
  end

  def can_be_finalized?
    nbr_of_days = updated_at.beginning_of_day - Time.zone.today.beginning_of_day
    ((nbr_of_days < 5) && !dates_finalized_or_being_finalized?) && !finalized
  end
end
