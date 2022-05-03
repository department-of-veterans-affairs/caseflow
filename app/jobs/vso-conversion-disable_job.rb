# frozen_string_literal: true

# VSO users should not be able to convert a hearing to virtual within 11 days of the hearing.
class VSOConversionDisable < CaseflowJob
  def perform
    # HOW DO I GET THE HEARING DOCKET?????????????
    appeal_list = find_affected_hearings(hearing_docket)
    disable_conversion_task(appeal_list)
  end

  def find_affected_hearings
    # CAN'T GET THE APPEAL ID FROM THE HEARING_DAYS MODEL???
    # HOW ARE THE DOCKETS AND THE HEARINGS AND THE HEARING_DAYS CONNECTED?????
    current_time = Time.zone.now
    deadline_time = current_time + 11
    appeal_list = []
    hearing_day_list = HearingDay.find_by(scheduled_for: deadline_time)
    hearing_day_list.each | hearing_day |
      if (current_time.day - hearing_day.scheduled_for).to_i <= 11
        hearing = Hearing.find_by(hearing_day_id: hearing_day.id)
        appeal = Appeal.find_by(hearing_id: hearing.id)
        appeal_list.push(appeal)
      end
    # OR find hearing day that is 11 days after current time
    # get all of the hearings on that specific day (how to do that???)
    # are there currently hearings that have less than 11 days before scheduled time?
  end

	def disable_conversion_task(hearing_list)
		
	end
end
