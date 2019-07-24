# frozen_string_literal: true

# :nocov:
module BgsService
  extend ActiveSupport::Concern

  private

  # both class and instance method
  class_methods do
    def bgs
      BGSService.new
    end
  end

  def bgs
    BGSService.new
  end
end
# :nocov:
