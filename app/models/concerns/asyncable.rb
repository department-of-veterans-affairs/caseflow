module Asyncable
  extend ActiveSupport::Concern

  private

  def run_async?
    !Rails.env.development? && !Rails.env.test?
  end
end
