# frozen_string_literal: true

# ************************
# Remediates AssignHearingDispositionTasks that are stuck in the
# 'assigned' status due to a VACOLS record not existing for the
# associated LegacyHearing. This job will create a VACOLS record for the
# associated LegacyHearing, cancel the task, then destroy the VACOLS record.
# The VACOLS record is deleted because the exact time of the hearing cannot be
# recorded accurately and we do not want any false data to exist.
# ************************
class MissingVacolsHearingJobFix
  def initialize
    @stuck_job_report_service = StuckJobReportService.new
    @start_time = nil
    @end_time = nil
    @tasks_missing_hearings = []
  end

  def perform
    start_time
    RequestStore[:current_user] = User.system_user
    return "There are no stuck AssignHearingDisposition tasks." if questionable_tasks.blank?

    process_missing_vacols_records

    unless @tasks_missing_hearings.blank?
      Rails.logger.error("ALERT------- Task Id's: #{@tasks_missing_hearings.to_sentence} are missing" \
      " associated hearings. This requires manual remediation------- ALERT")
    end
    end_time
    log_processing_time
  end

  def process_missing_vacols_records
    questionable_tasks
    # These tasks are stuck because they have a LegacyHearing associated with them that do not exist in VACOLS

    stuck_tasks(questionable_tasks).each do |task|
      task = Task.find(task.id)
      appeal = task.appeal
      hearing = task.hearing

      attributes = get_attributes(appeal, hearing)
      process_vacols_record(attributes, task)
    end
  rescue StandardError => error
    Rails.logger.error("Something went wrong. Requires manual remediation. Error: #{error} Aborting...")

    raise error
  end

  def questionable_tasks
    Task.where(
      type: "AssignHearingDispositionTask",
      status: "assigned",
      appeal_type: "LegacyAppeal",
      assigned_at: 7.years.ago..6.months.ago
    )
  end

  # :reek:FeatureEnvy
  def stuck_tasks(questionable_tasks)
    tasks_with_hearing_missing_vacols_records = []
    questionable_tasks.each do |task|
      if task.hearing.nil?
        @tasks_missing_hearings.push(task.id)
        next
      end

      if VACOLS::CaseHearing.find_by(hearing_pkseq: task.hearing.vacols_id).nil?
        # adds the stuck task associated with the missing VACOLS hearing
        tasks_with_hearing_missing_vacols_records.push(task)
      end
    end

    tasks_with_hearing_missing_vacols_records
  end

  def process_vacols_record(attrs, task)
    vacols_record = create_hearing_in_vacols(attrs)
    if vacols_record
      task.hearing.update(vacols_id: vacols_record[:hearing_pkseq])
      task.cancelled!
      vacols_record.destroy!
    end
  rescue StandardError => error
    Rails.logger.error("Something went wrong. Requires manual remediation. Error: #{error} Aborting...")
    raise Interrupt
  end

  def create_hearing_in_vacols(attrs)
    vacols_record = VACOLS::CaseHearing.create_hearing!(
      folder_nr: attrs[:appeal].vacols_id,
      hearing_pkseq: attrs[:vacols_id],
      hearing_date: VacolsHelper.format_datetime_with_utc_timezone(attrs[:scheduled_for]),
      vdkey: attrs[:hearing_day].id,
      hearing_type: attrs[:hearing_day].request_type,
      room: attrs[:hearing_day].room,
      board_member: attrs[:hearing_day].judge ? attrs[:hearing_day].judge.vacols_attorney_id : nil,
      vdbvapoc: attrs[:hearing_day].bva_poc,
      notes1: attrs[:notes]
    )

    vacols_record
  end

  def get_attributes(appeal, hearing)
    scheduled_for = HearingDatetimeService.prepare_datetime_for_storage(
      date: hearing.hearing_day.scheduled_for,
      time_string: "1:00 PM Central Time (US & Canada)"
    )

    attrs = {
      hearing_day: hearing.hearing_day,
      appeal: appeal,
      scheduled_for: scheduled_for,
      notes: ""
    }
    attrs
  end

  def log_processing_time
    (@end_time && @start_time) ? @end_time - @start_time : 0
  end

  def start_time
    @start_time ||= Time.zone.now
  end

  def end_time
    @end_time ||= Time.zone.now
  end
end
