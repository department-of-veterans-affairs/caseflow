module TimeableTask
  extend ActiveSupport::Concern

  module ClassMethods
    def create(args)
      fail Caseflow::Error::MissingTimerInfo unless method_defined?(:when_timer_ends)
      fail Caseflow::Error::MissingTimerInfo unless respond_to?(:timer_delay)

      task = super(args)
      TaskTimer.create!(task: task, submitted_at: Time.zone.now + timer_delay)
    end

    def create!(args)
      fail Caseflow::Error::MissingTimerInfo unless method_defined?(:when_timer_ends)
      fail Caseflow::Error::MissingTimerInfo unless respond_to?(:timer_delay)

      task = super(args)
      TaskTimer.create!(task: task, submitted_at: Time.zone.now + timer_delay)
    end
  end
end
