class Fakes::QueueRepository
  class << self
    attr_accessor :task_records
  end

  def self.tasks_for_user(_css_id)
    task_records || Fakes::Data::AppealData.default_records.map do |record|
      # This is a bit awkward. For now, we're using the default appeal records, which
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
    appeals = appeal_records || Fakes::Data::AppealData.default_records
    appeal = appeals.first
    # Create fake hearings for the first appeal if one doesn't already exist
    2.times { Generators::Hearing.create(appeal: appeal) } if Hearing.where(appeal: appeal).empty?
    appeals
  end
end
