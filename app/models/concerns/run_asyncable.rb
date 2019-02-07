module RunAsyncable
  extend ActiveSupport::Concern

  class_methods do
    def run_async?
      !Rails.env.development? && !Rails.env.test?
    end
  end

  private

  def run_async?
    self.class.run_async?
  end
end
