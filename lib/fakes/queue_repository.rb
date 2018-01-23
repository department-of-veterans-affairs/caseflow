class Fakes::QueueRepository
  class << self
    attr_accessor :appeal_records
    attr_accessor :task_records
  end

  def self.tasks_for_user(_css_id)
    appeal_records || Fakes::Data::AppealData.default_queue_records.map do |record|
      # For now, we're using the default appeal records, which
      # also contain all the task information we need. We'll then choose only the relevant
      # task attributes and create a new Appeal model with only those attributes, so our fake
      # tasks don't contain appeals data.
      task_attrs = {
        vacols_id: record.vacols_id,
        vbms_id: record.vbms_id,
        docket_date: record.docket_date,
        date_assigned: record.date_assigned,
        date_received: record.date_received,
        date_due: record.date_due,
        docket_number: record.docket_number
      }
      Appeal.new(task_attrs)
    end
  end

  def self.appeals_from_tasks(_tasks)
    appeals = appeal_records || Fakes::Data::AppealData.default_queue_records
    appeal = appeals.first

    # Create fake hearings for the first appeal if one doesn't already exist
    2.times { |i| Fakes::HearingRepository.create_hearing_for_appeal(i, appeal) } if appeal.hearings.empty?


        user = User.find_by_css_id("Hearing Prep")
    Generators::Hearing.create(random_attrs(i).merge(user: user, appeal: appeal))

    {
      vacols_record: OpenStruct.new(vacols_id: 950_330_575 + (i * 1465)),
      type: VACOLS::CaseHearing::HEARING_TYPES.values[i % 3],
      date: Time.zone.now - (i % 9).days - rand(3).days - rand(2).hours + rand(60).minutes,
      vacols_id: 950_330_575 + (i * 1465),
      disposition: nil,
      aod: nil,
      hold_open: nil,
      add_on: false,
      notes: Prime.prime?(i) ? "The Veteran had active service from November 1989 to November 1990" : nil,
      transcript_requested: false
    }

    if appeals[1]
      Fakes::HearingRepository.create_hearing_for_appeal(2, appeals[1])
    end

    appeals
  end
end
