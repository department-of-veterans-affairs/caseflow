# frozen_string_literal: true

# VSO users should not be able to convert a hearing to virtual within 11 days of the hearing.
class VSOConversionDisable < CaseflowJob
  def perform
    # HOW DO I GET THE HEARING DOCKET?????????????
    hearing_list = find_affected_hearings(hearing_docket)
    disable_conversion_task(hearing_list)
  end

  def find_affected_hearings(hearing_docket)
    current_time = Time.zone.now
    hearing_list = []
    hearing_docket.each | hearing |
      if (current_time.day - hearing.scheduled_time.day).to_i <= 11
        hearing_list.push(hearing)
      end
  end

	def disable_conversion_task(hearing_list)
		
	end
end
