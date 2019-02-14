class RoSchedulePeriod < SchedulePeriod
  validate :validate_spreadsheet, on: :create
  after_create :import_spreadsheet

  cache_attribute :algorithm_assignments, expires_in: 4.days do
    generate_ro_hearing_schedule
  end

  def validate_spreadsheet
    validate_spreadsheet = HearingSchedule::ValidateRoSpreadsheet.new(spreadsheet, start_date, end_date)
    errors[:base] << validate_spreadsheet.validate
  end

  def import_spreadsheet
    RoNonAvailability.import_ro_non_availability(self)
    CoNonAvailability.import_co_non_availability(self)
    Allocation.import_allocation(self)
  end

  def schedule_confirmed(hearing_schedule)
    RoSchedulePeriod.transaction do
      start_confirming_schedule
      begin
        transaction do
          HearingDay.create_schedule(hearing_schedule)
        end
        super
      rescue StandardError
        end_confirming_schedule
        raise ActiveRecord::Rollback
      end
      end_confirming_schedule
    end
  end

  private

  # Video hearings master records reflect 8:30 am start time.
  def format_ro_data(ro_allocations)
    ro_allocations.reduce([]) do |acc, (ro_key, ro_info)|
      ro_info[:allocated_dates].each_value do |dates|
        dates.each do |date, rooms|
          rooms.each do |room|
            acc << HearingDayMapper.hearing_day_field_validations(
              request_type: :video,
              scheduled_for: Date.new(date.year, date.month, date.day),
              room: room[:room_num],
              regional_office: ro_key
            )
          end
        end
      end
      acc
    end
  end

  def generate_ro_hearing_schedule
    generate_hearings_days = HearingSchedule::GenerateHearingDaysSchedule.new(self)
    video_hearing_days = format_ro_data(generate_hearings_days.allocate_hearing_days_to_ros)
    co_hearing_days = generate_hearings_days.generate_co_hearing_days_schedule
    hearing_days = video_hearing_days + co_hearing_days
    hearing_days.sort_by { |day| day[:scheduled_for] }
  end
end
