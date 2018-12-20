module TimeableTask
  extend ActiveSupport::Concern

  module ClassMethods

    def create(args)
      fail "Must provide method to call when timer ends" unless method_defined?(:when_timer_ends)
      fail "Must provide timer interval" unless method_defined?(:timer_delay)
      task = super(args)
      TaskTimer.create!(task: task, submitted_at: Time.zone.now + task.timer_delay)
    end

    def create!(args)
      fail "Must provide method to call when timer ends" unless method_defined?(:when_timer_ends)
      fail "Must provide timer interval" unless method_defined?(:timer_delay)
      task = super(args)
      TaskTimer.create!(task: task, submitted_at: Time.zone.now + task.timer_delay)
    end
  end
end
