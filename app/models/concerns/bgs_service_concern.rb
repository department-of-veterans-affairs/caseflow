# frozen_string_literal: true

module BGSServiceConcern
  extend ActiveSupport::Concern

  private

  # both class and instance method
  class_methods do
    # :nocov:
    def bgs
      BGSService.new
    end
    # :nocov:
  end

  # :nocov:
  def bgs
    BGSService.new
  end
  # :nocov:
end
