# frozen_string_literal: true

# VSO users should not be able to convert a hearing to virtual within 11 days of the hearing.
class VSOConversionDisable < CaseflowJob
  def perform
    find_affected_appeals
  end

  def find_affected_appeals
    current_time = Time.zone.now

  end

	def disable_conversion_task
		
	end
end
