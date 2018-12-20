module TimeableTask
  extend ActiveSupport::Concern

  module ClassMethods
    def timer_delay
      # TODO: add option to have tasks always expire at the midnight following their creation?
      TIMER_DELAY
    end

    def create
      fail "Must provide method to call when timer ends" unless method_defined?(:when_timer_ends)
      fail "Must provide timer interval" if TIMER_DELAY.blank?
      task = super
      TaskTimer.create!(task: task, submitted_at: Time.zone.now + timer_delay)
    end

    def create!
      fail "Must provide method to call when timer ends" unless method_defined?(:when_timer_ends)
      fail "Must provide timer interval" if TIMER_DELAY.blank?
      task = super
      TaskTimer.create(task: task, submitted_at: Time.zone.now + timer_delay)
    end
   end
end
