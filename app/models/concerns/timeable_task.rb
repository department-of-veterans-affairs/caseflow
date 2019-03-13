# frozen_string_literal: true

module TimeableTask
  extend ActiveSupport::Concern

  module ClassMethods
    def create!(args)
      fail Caseflow::Error::MissingTimerMethod unless method_defined?(:when_timer_ends)
      fail Caseflow::Error::MissingTimerMethod unless method_defined?(:timer_ends_at)

      super(args).tap do |task|
        TaskTimer.create!(task: task, last_submitted_at: task.timer_ends_at)
      end
    end
  end
end
