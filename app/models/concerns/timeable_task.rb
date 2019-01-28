module TimeableTask
  extend ActiveSupport::Concern

  module ClassMethods
    def create!(args)
      fail Caseflow::Error::MissingTimerMethod unless method_defined?(:when_timer_ends)
      fail Caseflow::Error::MissingTimerMethod unless respond_to?(:timer_delay)

      super(args).tap do |task|
        TaskTimer.create!(task: task, last_submitted_at: Time.zone.now + timer_delay)
      end
    end
  end
end
