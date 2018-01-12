class Fakes::QueueRepository
  class << self
    attr_accessor :task_records
  end

  def self.tasks_for_user(css_id)
    tasks = task_records || Fakes::Data::AppealData.default_records.map do |record|
      task_attrs = record.pluck(
        :vacols_id,
        :vbms_id,
        :docket_date,
        :date_assigned,
        :date_received,
        :date_due,
        :docket_number
      )
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
