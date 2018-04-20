class Fakes::QueueRepository
  class << self
    attr_accessor :appeal_records
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
        assigned_to_attorney_date: record.assigned_to_attorney_date,
        reassigned_to_judge_date: record.reassigned_to_judge_date,
        assigned_to_location_date: record.assigned_to_location_date,
        created_at: record.created_at,
        date_due: record.date_due,
        docket_number: record.docket_number,
        added_by_first_name: record.added_by_first_name,
        added_by_middle_name: record.added_by_middle_name,
        added_by_last_name: record.added_by_last_name,
        added_by_css_id: record.added_by_css_id,
        document_id: "173341517.524"
      }
      Appeal.new(task_attrs)
    end
  end

  def self.appeals_from_tasks(_tasks)
    appeals = appeal_records || Fakes::Data::AppealData.default_queue_records
    appeal = appeals.first

    # Create fake hearings for the first appeal if one doesn't already exist
    2.times { |i| Fakes::HearingRepository.create_already_held_hearing_for_appeal(i, appeal) } if appeal.hearings.empty?

    Fakes::HearingRepository.create_hearing_for_appeal(rand(4), appeals[1]) if appeal.hearings.empty?

    # The fake appeal repository returns `true` by default for aod, so let's make
    # only the first appeal AOD.
    appeals[1..-1].each do |a|
      a.aod = false
    end

    appeals
  end

  def self.reassign_case_to_judge!(_decass_hash)
    true
  end

  def self.assign_case_to_attorney!(_args)
    true
  end
end
