# frozen_string_literal: true

module Seeds
  class CavcAmaAppeals < Base
    def initialize
      @ama_appeals = []
    end

    def seed!
      create_cavc_ama_appeals
      create_cavc_appeals_at_response_window
      create_cavc_appeals_at_response_window_complete
    end

    private

    def create_cavc_ama_appeals
      create_cavc_appeals_at_send_letter
    end

    def create_cavc_appeals_at_send_letter
      10.times do
        create(:appeal, :type_cavc_remand)
      end
    end

    def create_cavc_appeals_at_response_window
      10.times do
        create(:appeal, :cavc_response_window_open)
      end
    end

    def create_cavc_appeals_at_response_window_complete
      now = Time.zone.now
      10.times do
        Timecop.travel(now - 91.days)
        appeal = create(:appeal, :cavc_response_window_open)
        timed_hold_task = appeal.reload.tasks.find { |task| task.is_a?(TimedHoldTask) }
        Timecop.travel(now)
        TaskTimerJob.new.send(:process, timed_hold_task.task_timers.first)
      end
    end
  end
end
