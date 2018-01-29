class Fakes::QueueRepository
  class << self
    attr_accessor :appeal_records
    attr_accessor :task_records
  end

  def self.tasks_for_user(_css_id)
    appeal_records || Fakes::Data::AppealData.default_queue_records.map do |record|
      # For now, we're using appeal records, which
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
    2.times { |i| Fakes::HearingRepository.create_already_held_hearing_for_appeal(i, appeal) } if appeal.hearings.empty?

    Fakes::HearingRepository.create_hearing_for_appeal(2, appeals[1]) if appeal.hearings.empty?

    # The fake appeal repository returns `true` by default for aod, so let's make
    # only the first appeal AOD.
    appeals[1..-1].each do |a|
      a.aod = false
    end

    appeals
  end
end
