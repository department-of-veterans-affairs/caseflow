# frozen_string_literal: true

class HigherLevelReviewRequest::Veteran
  attr_reader :file_number

  def initialize(options)
    @file_number = options[:file_number]
    unless /^\d{8,9}$/.match?(file_number)
      fail ArgumentError, "file_number must be a string of 8 or 9 digits"
    end
  end
end
