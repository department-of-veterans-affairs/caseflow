# frozen_string_literal: true

module BgsService
  extend ActiveSupport::Concern

  # both class and instance method
  class_methods do
    private

    def bgs
      BGSService.new
    end
  end

  private

  def bgs
    BGSService.new
  end
end
