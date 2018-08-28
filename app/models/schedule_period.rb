class SchedulePeriod < ApplicationRecord
  validate :validate_schedule_period, on: :create

  class OverlappingSchedulePeriods < StandardError; end

  include CachedAttributes

  belongs_to :user
  has_many :allocations
  has_many :non_availabilities

  delegate :full_name, to: :user, prefix: true

  def validate_schedule_period
    SchedulePeriod.where(type: type, finalized: true).find_each do |sp|
      if sp.start_date <= start_date && start_date <= sp.end_date
        errors[:base] << OverlappingSchedulePeriods
      end
    end
  end

  def spreadsheet_location
    File.join(Rails.root, "tmp", "hearing_schedule", "spreadsheets", file_name)
  end

  def spreadsheet
    S3Service.fetch_file(file_name, spreadsheet_location)
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

  def have_dates_already_been_finalized
    sps = SchedulePeriod.all.select(&:finalized)
    sps.any? do |schedule_period|
      schedule_period.start_date <= start_date && start_date <= schedule_period.end_date
    end
  end

  def can_be_finalized?
    nbr_of_days = updated_at.beginning_of_day - Time.zone.today.beginning_of_day
    ((nbr_of_days < 5) && !have_dates_already_been_finalized) && !finalized
  end
end
