# frozen_string_literal: true

# Purpose: Active Job that handles polling VACOLS for legacy appeals that have been recently docketed

class PollDocketedLegacyAppealsJob < CaseflowJob
  queue_as :low_priority
  application_attr :hearing_schedule

  def perform(vacols_id)
    
  end
end
