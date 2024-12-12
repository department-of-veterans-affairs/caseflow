# frozen_string_literal: true

require_relative "./helpers/seed_helpers"

module Seeds
  class CavcAmaAppeals < Base
    include SeedHelpers

    def initialize
      initial_id_values
      @ama_appeals = []
    end

    def seed!
      create_cavc_ama_appeals
      create_cavc_appeals_at_response_window
      create_cavc_appeals_at_response_window_complete
    end

    private

    def initial_id_values
      @file_number ||= 400_000_000
      @participant_id ||= 800_000_000
      while Veteran.find_by(file_number: format("%<n>09d", n: @file_number + 1)) ||
            VACOLS::Correspondent.find_by(ssn: format("%<n>09d", n: @file_number + 1))
        @file_number += 2000
        @participant_id += 2000
      end
    end

    def create_cavc_ama_appeals
      create_cavc_appeals_at_send_letter
    end

    def create_cavc_appeals_at_send_letter
      10.times do
        create(:appeal, :type_cavc_remand, veteran: create_veteran)
      end
    end

    def create_cavc_appeals_at_response_window
      10.times do
        create(:appeal, :cavc_response_window_open, veteran: create_veteran)
      end
    end

    def create_cavc_appeals_at_response_window_complete
      10.times do
        Timecop.travel(91.days.ago)
        appeal = create(:appeal, :cavc_response_window_open, veteran: create_veteran)
        timed_hold_task = appeal.reload.tasks.find { |task| task.is_a?(TimedHoldTask) }
        Timecop.return
        TaskTimerJob.new.send(:process, timed_hold_task.task_timers.first)
      end
    end
  end
end
