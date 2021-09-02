# frozen_string_literal: true

##
# See https://github.com/department-of-veterans-affairs/caseflow/wiki/Timed-Tasks#timeabletask

module TimeableTask
  extend ActiveSupport::Concern

  module ClassMethods
    def create!(args)
      fail Caseflow::Error::MissingTimerMethod unless method_defined?(:when_timer_ends)
      fail Caseflow::Error::MissingTimerMethod unless method_defined?(:timer_ends_at)

      super(args).tap do |task|
        create_timer task
      end
    end

    def create_timer(task)
      timer = TaskTimer.new(task: task)
      timer.submit_for_processing!(delay: task.timer_ends_at)
      # if timer_ends_at is in the past, we automatically trigger processing now.
      timer.restart! if timer.expired_without_processing?
    end
  end
end
