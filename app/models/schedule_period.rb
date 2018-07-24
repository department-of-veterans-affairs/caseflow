class SchedulePeriod < ApplicationRecord
  include CachedAttributes

  belongs_to :user
  has_many :allocations
  has_many :non_availabilities

  cache_attribute :ro_hearing_day_allocations, expires_in: 4.days do
    genenerate_ro_hearing_schedule
  end

  delegate :full_name, to: :user, prefix: true

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

  def format_ro_data(ro_allocations)
    ro_allocations.reduce([]) do |acc, (ro_key, ro_info)|
      ro_info[:allocated_dates].each_value do |dates|
        dates.each do |date, rooms|
          rooms.each do |room|
            acc << HearingDayMapper.hearing_day_field_validations(
              hearing_type: :video,
              hearing_date: date,
              room_info: room[:room_num],
              regional_office: ro_key
            )
          end
        end
      end
      acc
    end
  end

  def genenerate_ro_hearing_schedule
    generate_hearings_days = HearingSchedule::GenerateHearingDaysSchedule.new(self)
    format_ro_data(generate_hearings_days.allocate_hearing_days_to_ros)
  end

  def schedule_confirmed(*)
    update(finalized: true)
  end
end
