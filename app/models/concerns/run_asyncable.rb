# frozen_string_literal: true

module RunAsyncable
  extend ActiveSupport::Concern

  class_methods do
    def run_async?
      !Rails.env.development? && !Rails.env.test?
    end
  end

  private

  def perform_async_or_inline(job_class, *args, **kwargs)
    if run_async?
      job_class.perform_later(*args, **kwargs)
    else
      job_class.perform_now(*args, **kwargs)
    end
  end

  def run_async?
    self.class.run_async?
  end
end
