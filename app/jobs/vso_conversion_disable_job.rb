# frozen_string_literal: true

# VSO users should not be able to convert a hearing to virtual within 11 days of the hearing.
class VSOConversionDisableJob < CaseflowJob
  def perform
    appeal_list = find_affected_hearings
    if !appeal_list.nil?
      disable_conversion_task(appeal_list)
    end
  end

  def find_affected_hearings
    current_time = Time.zone.today
    deadline_time = current_time.next_day(11)
    appeal_list = []
    hearing_day = HearingDay.find_by(scheduled_for: deadline_time)
    byebug
    if hearing_day.nil?
      return
    end

    # iterate through hearings on the hearing day to find appeal
    Hearing.where(hearing_day_id: hearing_day.id).to_a.each do |hearing|
      # appeal = Appeal.find_by(hearing_id: hearing.id)
      appeal_list.push(hearing.appeal_id)
    end
  end

	def disable_conversion_task(appeal_list)
		
	end
end
